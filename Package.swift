// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "Transcribe",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "Transcribe",
            targets: ["Transcribe"]
        )
    ],
    dependencies: [
        // WhisperKit for on-device speech recognition
        .package(url: "https://github.com/argmaxinc/WhisperKit.git", from: "0.5.0"),
        
        // OllamaKit for local LLM integration
        .package(url: "https://github.com/kevinhermawan/OllamaKit.git", from: "5.0.0"),
        
        // OpenAI Swift client
        .package(url: "https://github.com/MacPaw/OpenAI.git", from: "0.4.6"),
        
        // SwiftOpenAI for enhanced OpenAI support
        .package(url: "https://github.com/jamesrochabrun/SwiftOpenAI.git", from: "3.0.0"),
        
        // Sparkle for auto-updates
        .package(url: "https://github.com/sparkle-project/Sparkle.git", from: "2.5.0"),
        
        // KeychainAccess for secure storage
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.0"),
    ],
    targets: [
        .target(
            name: "Transcribe",
            dependencies: [
                "WhisperKit",
                "OllamaKit",
                "OpenAI",
                "SwiftOpenAI",
                "Sparkle",
                "KeychainAccess"
            ],
            path: ".",
            exclude: [
                "ARCHITECTURE.md",
                "TECHNICAL_SPECS.md",
                "FEATURES_REQUIREMENTS.md",
                "API_INTEGRATION_GUIDE.md",
                "README.md"
            ],
            sources: [
                "App",
                "Core",
                "Features",
                "Shared",
                "ContentView.swift"
            ]
        ),
        .testTarget(
            name: "TranscribeTests",
            dependencies: ["Transcribe"]
        )
    ]
)