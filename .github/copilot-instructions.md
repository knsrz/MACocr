# macOS Screenshot OCR Tool - Project Instructions

## Project Overview
This is a macOS screenshot OCR application built with Swift and SwiftUI. The app captures screenshots and uses third-party LLM APIs for text recognition.

## Project Status
- [x] Create copilot-instructions.md file
- [x] Get project setup information
- [x] Scaffold the project structure
- [x] Implement screenshot capture module
- [x] Implement configuration management module
- [x] Implement API calling module
- [x] Implement result processing module
- [x] Create main UI
- [x] Complete documentation

## Technical Stack
- Language: Swift
- Framework: SwiftUI
- Platform: macOS 13.0+
- Architecture: MVVM pattern

## Key Features
1. System-level screenshot with global hotkeys
2. Configurable LLM API integration (OpenAI, Anthropic, DeepSeek, Baidu)
3. Base64 image encoding and HTTP API requests
4. Result preview and clipboard integration
5. Persistent configuration storage

## Development Guidelines
- Use SwiftUI for all UI components
- Follow Apple Human Interface Guidelines
- Implement proper error handling and retry mechanisms
- Use UserDefaults for configuration persistence
- Support dark mode
