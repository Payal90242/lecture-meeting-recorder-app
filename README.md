# EchoGemini AI: Voice Note & Lecture Summarizer 🎙️✨

A high-performance Flutter mobile application that transforms 1-tap microphone recordings into verbatim transcriptions and structured, academic-grade bullet-point summaries using the **Google Gemini 1.5 Flash API**. Includes local **SQLite** persistent storage and a **RevenueCat** in-app subscription paywall.

---

## 🌟 Key Architecture & Features

1. **1-Tap Microphone Recording Studio**:
   - Immediate recording on tap using `record`.
   - Real-time decibel amplitude stream normalized for dynamic waveform visualization.
   - Background audio resilience with pause/resume and temporary file cleanup on discard.

2. **Google Gemini Multimodal Audio Intelligence (`gemini-1.5-flash`)**:
   - Streams base64-encoded audio directly to Gemini without requiring external intermediary cloud storage.
   - Structured JSON prompt engineering returning:
     - Clear, contextual lecture/meeting title
     - Verbatim speech-to-text transcript
     - 4–6 high-yield Smart Bullet Points
     - Core Key Takeaways
     - Action Items / homework deadlines checklist

3. **Offline-First SQLite Vault (`sqflite`)**:
   - All voice notes, audio paths, transcripts, summaries, and favorites persist locally on device.
   - Fast full-text search across titles, bullet points, and transcripts.
   - Pre-seeded with a comprehensive ML lecture sample note for immediate testability.

4. **RevenueCat In-App Subscription Paywall (`purchases_flutter`)**:
   - Integrated with RevenueCat SDK for handling Annual ($39.99/yr) and Monthly ($6.99/mo) subscriptions.
   - Free tier quota tracking (3 free AI summaries before paywall trigger).
   - "3-Day Free Trial" offer flow and "Restore Purchases" button complying with App Store & Google Play guidelines.
   - Built-in Developer Sandbox Pro Mode toggle in Settings for testing without physical store sandbox credentials.

5. **Integrated Audio Player (`audioplayers`)**:
   - Play/pause scrubber with precision seeking slider.
   - ±10s fast forward / rewind buttons.
   - Variable playback speed (1.0x, 1.25x, 1.5x, 2.0x).
   - Native system sharing & clipboard export.

---

## 📂 Project Directory Structure

```text
ai_voice_summarizer/
├── pubspec.yaml                        # Flutter dependencies (record, sqflite, purchases_flutter, http, etc.)
├── android/app/src/main/
│   └── AndroidManifest.xml             # Microphone, storage, foreground service & billing permissions
├── ios/Runner/
│   └── Info.plist                      # NSMicrophoneUsageDescription & NSSpeechRecognitionUsageDescription
├── lib/
│   ├── main.dart                       # Entry point, MultiProvider & SQLite/RevenueCat init
│   ├── models/
│   │   └── voice_note.dart             # VoiceNote entity with SQLite JSON serialization
│   ├── services/
│   │   ├── audio_recorder_service.dart # Phone mic capture, amplitude stream, AAC encoding
│   │   ├── audio_player_service.dart   # Audio playback, scrubber & playback rate
│   │   ├── database_service.dart       # SQLite database helper, migrations & CRUD queries
│   │   ├── gemini_service.dart         # Multimodal Gemini API caller & JSON parser
│   │   └── revenuecat_service.dart     # RevenueCat SDK wrapper, offerings & entitlements
│   ├── providers/
│   │   ├── notes_provider.dart         # SQLite state, category filters & search
│   │   ├── recorder_provider.dart      # Recording lifecycle & Gemini transcription pipeline
│   │   └── subscription_provider.dart  # RevenueCat entitlement state & free quota limits
│   ├── theme/
│   │   └── app_theme.dart              # Sleek dark/light theme with AI neon indigo accents
│   ├── widgets/
│   │   ├── waveform_visualizer.dart    # Real-time decibel audio wave painter
│   │   └── note_card.dart              # Note card with category chips, duration, & bullets
│   └── screens/
│       ├── home_screen.dart            # Main dashboard, search bar, filter tabs, 1-tap mic button
│       ├── recording_screen.dart       # Live recording studio with animated waveform & timer
│       ├── note_detail_screen.dart     # Audio scrubber, Smart Summary & Full Transcript tabs
│       ├── paywall_screen.dart         # RevenueCat paywall with trial switcher & restore
│       └── settings_screen.dart        # Gemini API Key configuration & SQLite stats
└── test/
    └── voice_note_test.dart            # Unit test suite for models and serialization
```

---

## 🚀 Getting Started

### 1. Prerequisites
- Flutter SDK (`>= 3.19.0`)
- Android Studio / Xcode
- Google Gemini API Key ([Get one free at Google AI Studio](https://aistudio.google.com/))
- RevenueCat Account ([RevenueCat Dashboard](https://app.revenuecat.com/))

### 2. Installation
Open your terminal in the project directory:

```bash
cd C:\Users\hp\.gemini\antigravity\scratch\ai_voice_summarizer
flutter pub get
```

### 3. Configure Gemini API Key
You can pass your Gemini API key in two convenient ways:

**Option A (App Settings UI)**:
1. Run the app.
2. Tap the **Settings** gear icon in the top right.
3. Paste your Gemini API key under **Google Gemini API Key** and tap **Save Key**.

**Option B (Compile-time environment variable)**:
```bash
flutter run --dart-define=GEMINI_API_KEY=YOUR_GEMINI_API_KEY
```

### 4. Configure RevenueCat
1. In `lib/services/revenuecat_service.dart`, update:
   - `_apiKeyAndroid` with your RevenueCat Google Public API Key (`goog_...`)
   - `_apiKeyApple` with your RevenueCat Apple Public API Key (`appl_...`)
   - Ensure the entitlement ID in RevenueCat matches `'pro_access'`.
2. For testing without an active sandbox merchant account, toggle the **Developer Sandbox Pro Mode** switch directly inside **Settings > Subscription & Billing**.

### 5. Running the App
```bash
# Run on connected Android / iOS device or simulator
flutter run
```
