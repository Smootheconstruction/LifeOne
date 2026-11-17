export default async function handler(req, res) {
  res.setHeader("Cache-Control", "no-store");

  if (req.method !== "POST") {
    return res.status(405).json({ error: "Use POST to chat with NOVA." });
  }

  const key = process.env.GEMINI_API_KEY;
  if (!key) {
    return res.status(503).json({ error: "Gemini API key is not configured." });
  }

  const body = req.body || {};
  const message = body.message || body.prompt || body.messages?.at(-1)?.content;

  if (typeof message !== "string" || !message.trim()) {
    return res.status(400).json({ error: "Please enter a message." });
  }
  if (message.length > 4000) {
    return res.status(400).json({ error: "Message is too long." });
  }

  // The home-page chat sends prior turns in {role, text} format. Only include
  // bounded plain-text user/model turns; never trust client-supplied system roles.
  const priorTurns = Array.isArray(body.history) ? body.history.slice(-12) : [];
  const contents = priorTurns
    .filter(turn => turn && (turn.role === "user" || turn.role === "model")
      && typeof turn.text === "string" && turn.text.trim())
    .map(turn => ({
      role: turn.role,
      parts: [{ text: turn.text.trim().slice(0, 4000) }]
    }));
  contents.push({ role: "user", parts: [{ text: message.trim() }] });

  try {
    const response = await fetch(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash-lite:generateContent",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-goog-api-key": key
        },
        body: JSON.stringify({
          systemInstruction: {
            parts: [{
              text: "You are NOVA, a friendly and helpful AI companion in the LifeOne app. Give clear, practical answers. Use relevant prior turns to answer follow-up questions naturally."
            }]
          },
          contents
        })
      }
    );

    const data = await response.json();
    if (!response.ok) {
      console.error("Gemini error", response.status);
      return res.status(502).json({
        error: `Gemini error ${response.status}: ${data.error?.status || "UNKNOWN"}`
      });
    }

    const reply = data.candidates?.[0]?.content?.parts
      ?.filter(part => typeof part.text === "string")
      .map(part => part.text)
      .join("\n");

    if (!reply) {
      return res.status(502).json({ error: "Gemini did not return a text answer." });
    }

    return res.status(200).json({ reply, response: reply, text: reply });
  } catch (error) {
    console.error("NOVA connection error", error);
    return res.status(500).json({ error: "NOVA could not complete the request." });
  }
}
