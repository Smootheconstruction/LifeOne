# LifeOne NOVA 2.1 — Gemini-connected edition

This updates the existing NOVA 2.0 without changing its CSS or layout. The previous scripted NOVA chat has been replaced by a real Gemini request routed through a Node server. Tasks, visual world, and other demo functions remain unchanged.

## Setup (Windows / macOS)

1. Install Node.js 20+ (Node 22 LTS recommended).
2. Open https://aistudio.google.com/app/apikey and create a Gemini API key. **Never put the API key inside `index.html`, GitHub, or ChatGPT.**
3. Extract this ZIP and open a terminal in the `LifeOne_NOVA_Gemini` folder.
4. Run `npm install`.
5. Copy `.env.example` to `.env` and replace `replace_with_your_private_api_key` with your Gemini API key.
6. Run `npm start`.
7. Open **http://localhost:3000** — NOT the `index.html` file directly.
8. Open **NOVA AI**, type `Hello NOVA, what can you help me with?`, and hit Send.

### Quick check

Go to `http://localhost:3000/api/health`. It should say `{"ok":true,"aiConfigured":true}` after you configure `.env`. This only checks that the key is present; it doesn't guarantee Google will accept it. Real chat is the integration test.

### What is now live, what isn't

- Gemini conversational replies and short multi-turn context: **wired to Gemini; works after valid key + server + network**.
- Microphone input: **not implemented**; existing spoken greeting remains browser text-to-speech demo.
- Document Lens: **file selection only**, not AI document analysis.
- Scam Checker: **keyword-only demo**, not Gemini.
- Social users/messages: **not connected**.
- Private accounts: **not connected**. Missions are saved only on the current browser.

### Security / launch limitations

- The Gemini API key stays server-side. The browser calls `/api/chat` on the same origin.
- Request size, message lengths, timeouts, and basic per-IP limits are enabled.
- This is a **private development/test starter**, NOT a production-ready public AI service. For public use add authenticated accounts, per-user quotas, abuse monitoring, moderation, persistent rate limiting, logging policy, privacy disclosures, robust CSP, and deployment secrets. Do not upload real sensitive documents to the free-tier model without reviewing Google's data-use policies.
- Vercel's ordinary static file upload cannot run this Express process. Deploy to an appropriate Node host, or adapt the endpoint to your hosting platform's serverless functions.
