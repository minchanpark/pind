import test from 'node:test';
import assert from 'node:assert/strict';
import {RequestCache} from './request-cache.ts';
test('concurrent duplicate provider calls share a request, TTL expires, failures retry',async()=>{
  let now=0,calls=0;let resolve!:(value:number)=>void;
  const cache=new RequestCache<number>(100,2,()=>now);
  const load=()=>{calls++;return new Promise<number>(r=>resolve=r);};
  const a=cache.get('a',load),b=cache.get('a',load);assert.equal(calls,1);resolve(4);
  assert.deepEqual(await Promise.all([a,b]),[4,4]);
  assert.equal(await cache.get('a',async()=>9),4);now=101;
  assert.equal(await cache.get('a',async()=>9),9);
  await assert.rejects(()=>cache.get('fail',async()=>{throw Error('offline');}));
  assert.equal(await cache.get('fail',async()=>7),7);
});
test('LRU cache is bounded and separate keys never share answers',async()=>{
  const c=new RequestCache<number>(10000,2);let calls=0;
  const get=(k:string)=>c.get(k,async()=>++calls);
  await get('a');await get('b');await get('a');await get('c');
  assert.equal(await get('a'),1);assert.equal(await get('b'),4);
});
