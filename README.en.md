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
- **Multi-bubble replies**: one turn is split into up to 4 short messages that appear one after another, so it reads like a real person typing; if the model still writes one big block, the client falls back to splitting it automatically
- **Time awareness**: messages carry time anchors (`today 14:00`, `yesterday 21:35`, `3 days ago 09:12`), so the character won't call yesterday's event "just now"
- **Character grouping**: a horizontal avatar bar atop the chat list filters conversations per character (newest first)
- **WeChat-style timestamps**: a centered time separator appears automatically between messages more than 5 minutes apart
- **Per-chat voice mute**: a toggle in the chat bar silences read-aloud for that conversation only (independent of the global switch)
- **Per-chat background**: set a wallpaper for each conversation (pick → crop → fills the screen), stays put when the keyboard appears, and can be reset anytime
- Character-bound sessions assemble prompts in a fixed order: persona → scenario → **cross-chat memory** → **what the character knows about you** → tag spec → few-shot examples → sliding window of the last 40 messages

### 👤 Characters
- Create manually, or **import SillyTavern V2 character cards** (PNG tEXt / JSON)
- Description, personality, scenario, first message and example dialogues are fully mapped
- Character artwork displayed locally, with a 1:1 visual crop when uploading
- **Cross-chat memory**: the same character remembers across separate conversations — recent excerpts are injected into the prompt, and older history is condensed by an LLM into a first-person memory summary; globally toggleable in Settings
- **Memory documents + "You in their eyes"**: memories are organised into a sectioned document, plus a portrait of you written from the character's point of view. Open it by tapping the avatar in chat or from the character editor, and export as PNG / Word
- **Sticker library**: upload stickers for 14 moods (happy / angry / sad / amused / confused / shy / …), multiple per mood. When a reply carries an emotion, a matching sticker is sent automatically; near-miss moods borrow a close one (e.g. "crying" falls back to "sad")

### 🐾 Desktop Pet (Live2D)
- **Haru built in**: works out of the box — imported automatically on first launch and bound to new conversations; swap in your own model anytime
- Import `.moc3` model packs (zip), rendered offline via WebView + pixi-live2d-display
- `<emotion:happy>` / `<action:wave>` tags in replies drive expressions and motions in real time
- Keyword-based emotion fallback (e.g. "angry" in text still triggers the expression)
- Sentence-level lip sync (envelope animation during playback)

### 🎙 Voice (two-way)

| Direction | Engine |
|---|---|
| TTS (read-aloud) | **MiMo Cloud** (`mimo-v2.5-tts`, default) → Edge (free) → OpenAI-compatible → system engine, auto-fallback on failure |
| ASR (push-to-talk) | **MiMo Cloud** (`mimo-v2.5-asr`, default) → custom endpoint → on-device recognition, auto-fallback |

- Hold to talk; release to recognize and send directly; tap the mic during playback to interrupt
- **Voice Workshop**: design a custom voice from a one-line description (e.g. "a sweet, gentle young female voice") via MiMo `voicedesign` — preview, store multiple voices, and pick them alongside the built-in ones
- **Per-engine API config**: the OpenAI TTS option and the ASR "custom endpoint" option each have their own base URL / key / model fields (blank falls back to the chat API profile); MiMo always reuses the chat config
- TTS input automatically strips `<tags>` — markup is never spoken
- Pipelined synthesis queue (sentence N+1 is synthesized while sentence N plays) for near-seamless continuity
- 9 MiMo voices plus custom workshop voices, speech rate 0.5–2.0×

### ⚙️ Settings
- **API providers**: any OpenAI-compatible endpoint (DeepSeek / Kimi / Qwen / Ollama / proxies / Xiaomi MiMo), with connection test
- **Voice**: TTS/ASR engine, voices, recognition language, optional dedicated cloud API endpoints
- **Cross-chat memory**: global toggle (on by default)
- **Appearance**: five complete themes — Deep Space (violet), Sakura Night, Glacier Blue, Mint, and Daylight (light) — each with a full palette and brightness, shown as preview cards and applied instantly
- **More**: studio website, version info

### 🎨 Interface
- Anime-tech styling with multiple switchable full themes (including one light theme)
- **Liquid glass**: the bottom navigation, chat app bar and input bar use real background blur with translucent gradient borders; chat bubbles use translucent fills (the scrolling list is never blurred per-item, keeping it smooth)
- Splash transition page: icon + tagline + studio credit
- Bottom navigation: Chats / Characters / Pet / Settings

## Recent Updates

- **v1.3 series**: stickers, multi-bubble short replies, liquid-glass UI, memory documents with "You in their eyes" export, per-chat backgrounds and avatar cropping, built-in Haru pet, time awareness
- Fixes: background crop limited to 1:1 / "crop failed", background shrinking with the keyboard, replies still arriving as one big block when the model ignores the format, model-invented tags leaking into bubbles, portrait avatar crop frame landing off-screen

## Tech Stack

Flutter (Android, minSdk 24) · Riverpod 3 · Drift/SQLite · dio (hand-rolled SSE decoding) · just_audio · edge_tts / flutter_tts / speech_to_text / record · flutter_inappwebview + PixiJS + pixi-live2d-display · crop_your_image (cropping) · share_plus (export/share) · image / archive (image and OOXML processing)

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
2. **Voice works out of the box**: TTS/ASR default to MiMo Cloud, reusing the default chat API profile; switch engines and voices in Settings → Voice, or fill in dedicated endpoints for OpenAI TTS / custom ASR
3. MiMo platform notes (verified in practice):
   - Keys only work on `https://token-plan-cn.xiaomimimo.com/v1` (`api.xiaomimimo.com` returns 401)
   - TTS uses `chat/completions` with an `audio` parameter (**not** `/audio/speech`); exactly 9 voices are available
   - Custom voices go through `mimo-v2.5-tts-voicedesign`: the description goes in the user message and the spoken text in the assistant message — no voice ID involved; two syntheses of the same description differ slightly (stochastic output)
   - ASR `content` must **not** contain any text parts — only `input_audio` is accepted
4. Edge free voices may be rejected by Microsoft's endpoint in some regions (403); the app then falls back automatically

## Project Structure

```
lib/
  app/          # MaterialApp, theme, splash, global providers
  core/         # unified exceptions, SSE decoder
    utils/      # time anchors, image compression, Word (.docx) writer, export/share
    widgets/    # liquid-glass widgets
  data/local/   # Drift database and table definitions
  features/
    chat/       # conversations, message list, input bar (push-to-talk), segment splitter, cross-chat memory, stickers, chat background
    characters/ # character cards, SillyTavern import, prompt assembly, emotion tag parsing, memory documents, sticker library, image cropping
    pet/        # Live2D pet, WebView bridge, emotion→expression mapping, bundled Haru
    voice/      # TTS/ASR engine implementations, playback queue, Voice Workshop, voice settings
    settings/   # API providers, general app settings
assets/
  pet/          # pet WebView host, offline vendor libraries, bundled Haru model and its license
  branding/     # app icon and studio logo
```

## Testing

```bash
flutter analyze   # static checks
flutter test      # 304 cases: SSE/tag parsing, splitting and fallback, prompt time anchors, sticker mapping, voice queue, auto-scroll, migrations, memory summarizer, crop geometry, …
```

## Acknowledgments & Copyright

- © Sigborn Studio (sigborn.xyz). The app name "Innermost Words / 心语" and icon assets are property of the studio.
- Pet rendering is based on [pixi-live2d-display](https://github.com/guansss/pixi-live2d-display) (MIT) and Live2D Cubism Core; **Powered by Live2D**. Cubism Core is used under the Live2D license (free for individuals and small revenue; please verify the terms before commercial use).
- The bundled default pet, Haru, is an official Live2D sample model distributed under the Live2D Sample Model License Agreement (see `assets/pet/HARU_LICENSE.txt`; the model is © Live2D).
- Character cards and model assets imported by users are the user's own responsibility; the app renders them locally only.
