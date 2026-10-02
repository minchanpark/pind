// Groq (OpenAI-compatible) for the JSON the agent and insights ask for:
// faster than Gemini and in a separate quota. Strict json_schema output
// needs every property required and no extra ones, as our schemas are.
import { withFallback } from './insights.ts';

/// Bigger first; the smaller one has its own rate limits.
export const GROQ_MODELS = ['openai/gpt-oss-120b', 'openai/gpt-oss-20b'];

/// The model's JSON text for [user] under [system], shaped by [schema].
/// Throws with `.status` so [withFallback] can move on after a 429/503.
export async function groqJson(
  key: string,
  system: string,
  user: string,
  schema: object,
  fetcher: typeof fetch = fetch,
  delayMs = 500,
): Promise<string> {
  return await withFallback(GROQ_MODELS, async model => {
    const response = await fetcher('https://api.groq.com/openai/v1/chat/completions', {
      method: 'POST',
      headers: {Authorization: `Bearer ${key}`, 'Content-Type': 'application/json'},
      body: JSON.stringify({
        model,
        // Short structured answers: a little reasoning, none of it returned.
        reasoning_effort: 'low',
        include_reasoning: false,
        messages: [{role: 'system', content: system}, {role: 'user', content: user}],
        response_format: {type: 'json_schema', json_schema: {name: 'answer', strict: true, schema}},
      }),
    });
    const data = await response.json().catch(() => null);
    if (!response.ok) {
      throw Object.assign(new Error(`Groq ${response.status}: ${data?.error?.message ?? ''}`.slice(0, 300)),
        {status: response.status});
    }
    const choice = data?.choices?.[0];
    if (choice?.finish_reason !== 'stop' || typeof choice.message?.content !== 'string') {
      throw new Error(`Groq stopped: ${choice?.finish_reason}`);
    }
    return choice.message.content;
  }, delayMs);
}
