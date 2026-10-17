# GoGreen-AI Flutter App

A smart plant care and nursery discovery app powered by **Gemini AI**, built with **Flutter** (Material 3).

## Features
| Feature | Description |
|---|---|
| 🌿 Plant Catalogue | Browse all plants from verified nurseries |
| 🏪 Nursery Discovery | Explore nearby verified nurseries |
| 🤖 AI Chat | Ask the Gemini-powered plant assistant |
| 📸 Plant Identifier | Take a photo and identify any plant (Gemini Vision) |
| 🔍 Recommendations | Content-based plant recommendations via backend API |

## Project Structure
```
gogreenai/
├── android/                    # Native Android project (open in Android Studio)
├── lib/
│   ├── main.dart               # App entry point + NavigationBar shell
│   ├── providers/              # State management (ChangeNotifier)
│   ├── core/
│   │   ├── constants/          # Colors, API URLs
│   │   ├── theme/              # Material 3 theme (Botanical Precision)
│   │   ├── network/            # HTTP client for backend
│   │   └── services/           # GeminiService (chat, vision, care advice)
│   └── features/
│       ├── home/               # Home screen
│       ├── plants/             # Plant catalogue + PlantCard widget
│       ├── nurseries/          # Nursery list
│       └── ai/                 # AI Assistant screen (chat + identifier)
└── pubspec.yaml
```

## Getting Started

### Prerequisites
- Flutter SDK >= 3.16 (install at https://docs.flutter.dev/get-started/install)
- Android Studio (with Flutter & Dart plugins)
- Android SDK 34
- A Gemini API Key from https://aistudio.google.com/

### 1. Install dependencies
```bash
cd gogreenai
flutter pub get
```

### 2. Run with Gemini API Key
```bash
flutter run --dart-define=GEMINI_API_KEY=YOUR_KEY_HERE
```

### 3. Build an APK
```bash
flutter build apk --release --dart-define=GEMINI_API_KEY=YOUR_KEY_HERE
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### 4. Open in Android Studio
Open the `gogreenai/` folder directly in Android Studio.
Android Studio will detect the Flutter project and offer to install Flutter plugin if needed.

## Backend Connection
The app connects to the GoGreen-AI Express backend at:
- **Android Emulator:** `http://10.0.2.2:5000/api`
- **Web/Local:** `http://localhost:5000/api`

Make sure `npm run dev` is running in the `backend/` folder.
