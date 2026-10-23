<p align="center">
  <img src="assets/branding/app_icon.png" width="160" alt="Innermost Words app icon">
</p>

<h1 align="center">Innermost Words（心语）</h1>

<p align="center">Make every conversation a flutter of the heart.</p>

<p align="center">
  An Android AI roleplay chat app: bring your own API, import character cards, interact with a Live2D desktop pet, and talk both ways with voice.<br>
  By Sigborn Studio · <a href="https://www.sigborn.xyz">www.sigborn.xyz</a><br>
  中文文档：<a href="README.md">README.md</a>
</p>

---

## Features

### 💬 Conversations
- Streaming typewriter replies (SSE) with instant stop/interrupt
- Full chat history stored locally in SQLite — nothing lost on restart
- Character-bound sessions assemble prompts in a fixed order: persona → scenario → tag spec → few-shot examples → sliding window of the last 40 messages

### 👤 Characters
- Create manually, or **import SillyTavern V2 character cards** (PNG tEXt / JSON)
- Description, personality, scenario, first message and example dialogues are fully mapped
- Character artwork displayed locally

### 🐾 Desktop Pet (Live2D)
- Import `.moc3` model packs (zip), rendered offline via WebView + pixi-live2d-display
- `<emotion:happy>` / `<action:wave>` tags in replies drive expressions and motions in real time
- Keyword-based emotion fallback (e.g. "angry" in text still triggers the expression)
- Sentence-level lip sync (envelope animation during playback)

### 🎙 Voice (two-way)

| Direction | Engine |
|---|---|
| TTS (read-aloud) | **MiMo Cloud** (`mimo-v2.5-tts`, default) → Edge (free) → OpenAI-compatible → system engine, auto-fallback on failure |
| ASR (push-to-talk) | **MiMo Cloud** (`mimo-v2.5-asr`, default) → on-device recognition, auto-fallback |

- Hold to talk; release to recognize and send directly; tap the mic during playback to interrupt
- TTS input automatically strips `<tags>` — markup is never spoken
- Pipelined synthesis queue (sentence N+1 is synthesized while sentence N plays) for near-seamless continuity
- 9 MiMo voices, speech rate 0.5–2.0×

### ⚙️ Settings
- **API providers**: any OpenAI-compatible endpoint (DeepSeek / Kimi / Qwen / Ollama / proxies / Xiaomi MiMo), with connection test
- **Voice**: TTS/ASR engine, voice, recognition language configured independently
- **Appearance**: four accent themes (violet / cyan / rose / mint), applied instantly
- **More**: studio website, version info

### 🎨 Interface
- Dark "deep-space" anime-tech theme (neon accents on near-black)
- Splash transition page: icon + tagline + studio credit
- Bottom navigation: Chats / Characters / Pet / Settings

## Tech Stack

Flutter (Android, minSdk 24) · Riverpod 3 · Drift/SQLite · dio (hand-rolled SSE decoding) · just_audio · edge_tts / flutter_tts / speech_to_text / record · flutter_inappwebview + PixiJS + pixi-live2d-display

## Getting Started

```bash
# Dependencies
flutter pub get

# Run (with a device/emulator connected)
flutter run

# Build a release APK
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

> If Gradle runs out of memory (daemon OOM), see `android/gradle.properties` — JVM flags are tuned for 16 GB machines (`-Xmx4G`).

## Configuration

1. **Add an API provider**: Settings → API Providers → enter the base URL (e.g. `https://api.xxx.com/v1`, without `/chat/completions`) and key; connection test available
2. **Voice works out of the box**: TTS/ASR default to MiMo Cloud, reusing the default chat API profile; switch engines and voices in Settings → Voice
3. MiMo platform notes (verified in practice):
   - Keys only work on `https://token-plan-cn.xiaomimimo.com/v1` (`api.xiaomimimo.com` returns 401)
   - TTS uses `chat/completions` with an `audio` parameter (**not** `/audio/speech`); exactly 9 voices are available
   - ASR `content` must **not** contain any text parts — only `input_audio` is accepted
4. Edge free voices may be rejected by Microsoft's endpoint in some regions (403); the app then falls back automatically

## Project Structure

```
lib/
  app/          # MaterialApp, theme, splash, global providers
  core/         # unified exceptions, SSE decoder
  data/local/   # Drift database and table definitions
  features/
    chat/       # conversations, message list, input bar (push-to-talk)
    characters/ # character cards, SillyTavern import, prompt assembly, emotion tag parsing
    pet/        # Live2D pet, WebView bridge, emotion→expression mapping
    voice/      # TTS/ASR engine implementations, playback queue, voice settings
    settings/   # API providers, general app settings
assets/
  pet/          # pet WebView host and offline vendor libraries
  branding/     # app icon and studio logo
```

## Testing

```bash
flutter analyze   # static checks
flutter test      # 160+ cases: SSE/tag parsing, prompt assembly, voice queue, auto-scroll, theming, …
```

## Acknowledgments & Copyright

- © Sigborn Studio (sigborn.xyz). The app name "Innermost Words / 心语" and icon assets are property of the studio.
- Pet rendering is based on [pixi-live2d-display](https://github.com/guansss/pixi-live2d-display) (MIT) and Live2D Cubism Core; **Powered by Live2D**. Cubism Core is used under the Live2D license (free for individuals and small revenue; please verify the terms before commercial use).
- Character cards and model assets imported by users are the user's own responsibility; the app renders them locally only.
