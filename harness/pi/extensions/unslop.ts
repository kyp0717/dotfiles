import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const UNSLOP =
  "\n\nUNSLOP — enforced on every reply:\n" +
  "- No em dashes, no mid-sentence colons, no puffery, no chatbot phrases. Plain words, active voice.\n" +
  "- Be concise. Bullet points under short headers, not long paragraphs.\n" +
  "- Each bullet is one line, 80 characters or fewer.\n" +
  "- Lead with the answer or the action taken, then the detail.\n" +
  "- One header per topic. No preamble, no closing summary.";

export default function (pi: ExtensionAPI) {
  // Fires on every prompt; the appended text is constant, so the system
  // prompt stays byte-identical across turns and prompt caching holds.
  pi.on("before_agent_start", async (event, _ctx) => {
    if (event.systemPrompt.includes("UNSLOP")) return {};
    return { systemPrompt: event.systemPrompt + UNSLOP };
  });
}
