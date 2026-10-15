/// Only provider-independent search plans and area coordinates are cached.
/// User-visible place results always run with the caller's JWT and RLS.
export class RequestCache<T> {
  private values = new Map<string, {at: number; value: T}>();
  private pending = new Map<string, Promise<T>>();
  private generation = 0;
  constructor(private ttlMs: number, private maxEntries = 256,
    private now: () => number = Date.now) {}
  async get(key: string, load: () => Promise<T>): Promise<T> {
    const found = this.values.get(key);
    if (found && this.now() - found.at < this.ttlMs) {
      this.values.delete(key); this.values.set(key, found);
      return found.value;
    }
    this.values.delete(key);
    const pending = this.pending.get(key);
    if (pending) return await pending;
    const generation = this.generation;
    const task = load();
    this.pending.set(key, task);
    try {
      const value = await task;
      if (generation === this.generation) {
        this.values.set(key, {at: this.now(), value});
        while (this.values.size > this.maxEntries) this.values.delete(this.values.keys().next().value!);
      }
      return value;
    } finally { if (this.pending.get(key) === task) this.pending.delete(key); }
  }
  clear() { this.generation++; this.values.clear(); this.pending.clear(); }
}
