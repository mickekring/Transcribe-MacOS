# Transcribe for macOS 🎙️

A privacy-first audio transcription app for macOS with local AI processing and YouTube support. Optimized for Swedish language but supports 100+ languages.

![Swift](https://img.shields.io/badge/Swift-6.1-orange)
![macOS](https://img.shields.io/badge/macOS-15.5+-blue)
![License](https://img.shields.io/badge/License-MIT-green)

## ✨ Features

- **🔒 Privacy First** - All files stored temporarily, auto-deleted on quit
- **🎤 Audio Recording** - Built-in recording with waveform visualization  
- **📹 YouTube Support** - Download and transcribe videos directly
- **🤖 Local AI** - WhisperKit & KB Whisper models run on-device
- **🌍 Multi-language** - 100+ languages with auto-detection
- **🇸🇪 Swedish Optimized** - Special models for Swedish transcription

## 🚀 Quick Start

### Requirements
- macOS 15.5 (Sequoia) or later
- 8GB RAM (16GB recommended)
- M1 +

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/transcribe-macos.git
cd transcribe-macos/Transcribe
```

2. Open in Xcode:
```bash
open Transcribe.xcodeproj
```

3. Build and run (⌘R)

## 🎯 Usage

1. **Record Audio** - Click microphone button to start recording
2. **Import Files** - Drag & drop audio/video files onto the window
3. **YouTube** - Paste YouTube URL and click transcribe
4. **Export** - Save transcription as text file

## 🔐 Security

- No tracking or analytics
- Temporary file storage only (`/var/folders/*/T/`)
- Automatic cleanup on app termination
- Local processing available (no internet required)

## 🛠️ Tech Stack

- **SwiftUI** - Native macOS interface
- **WhisperKit** - Local transcription engine
- **YouTubeKit** - YouTube downloading
- **AVFoundation** - Audio processing

## 📦 Models

### Local Models
- **WhisperKit** - OpenAI Whisper (Tiny to Large)
- **KB Whisper** - Swedish-optimized models

### Cloud (Optional)
- **Berget AI** - GDPR-compliant Swedish service

## 📄 License

MIT License - See [LICENSE](LICENSE) file for details

## 👨‍💻 Author

**Micke Kring**  
[mickekring.se](https://mickekring.se)  

**Claude Code**

---

<sub>Built with ❤️ in Sweden</sub>
