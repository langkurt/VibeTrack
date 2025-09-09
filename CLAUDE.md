# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

This is an iOS SwiftUI app using Xcode. Build and run using Xcode IDE:
- Open `VibeTrack.xcodeproj` in Xcode
- Build: Cmd+B
- Run: Cmd+R (requires physical device for voice features)
- Test: Cmd+U (runs unit and UI tests)

No package managers (npm, pod, etc.) - uses Swift Package Manager integrated in Xcode.

## Architecture Overview

VibeTrack is a voice-first nutrition tracking iOS app with SwiftUI and MVVM architecture:

**Core Flow**: Voice input → Speech recognition → Claude API parsing → Local storage → Charts visualization

**Key Components**:
- `SpeechManager`: Handles voice recognition using Speech framework
- `NutritionAPIService`: Manages Claude API calls for food parsing 
- `FoodDataStore`: MVVM store managing food entries with UserDefaults persistence
- `LogManager`: Comprehensive logging system for debugging and AI interaction tracking

**Data Models**:
- `FoodEntry`: Core nutrition data (calories, macros, timestamp, AI assumptions)
- `LLMResponse`: Claude API response structure with parsed food items

**UI Structure**:
- `MainRecordingView`: Primary voice input interface
- `EntriesListView`: Food history with edit capabilities  
- `ChartsView`: Nutrition trends visualization using Swift Charts
- `DebugLogsView`: Development logging interface

## Configuration

**Required Setup**:
1. Add Anthropic API key to `VibeTrack/Config/Config.xcconfig`:
   ```
   ANTHROPIC_API_KEY = your_key_here
   ```
2. Run on physical device (voice features require hardware)

**Important Files**:
- `Config.xcconfig`: API configuration (excluded from git)
- `UICopy.swift`: All user-facing text with "tech bro meets Gen Z" tone
- `todo.txt`: Current development priorities and research tasks

## Code Conventions

**Style**: 
- SwiftUI declarative UI patterns
- MVVM with `@StateObject`/`@ObservableObject` for data flow
- Comprehensive logging via `LogManager.shared.log()` for all operations
- Error handling with user-friendly messages from `UICopy`

**UI Text**: All user-facing copy is centralized in `Resources/UICopy.swift` - never hardcode strings in views.

**API Integration**: Claude API calls include input/output logging for debugging and evaluation. Mock responses available when API key missing.

**Data Persistence**: UserDefaults for simplicity (Core Data deemed overkill for this scope).

## Git Workflow

**Branch Strategy**:
- Always create a new branch when starting a new feature
- Branch from `main`: `git checkout main && git pull && git checkout -b CC/feature-name`
- Branch naming: Use prefix `CC/` followed by descriptive name (e.g., `CC/voice-editing`, `CC/swipe-gestures`)
- Commits are allowed on feature branches
- **NEVER commit directly to `main` branch**

**Development Process**:
1. Create feature branch: `git checkout -b CC/your-feature-name`
2. Make changes and commit regularly to feature branch
3. When feature is complete, create pull request to merge into `main`
4. Feature branches can be deleted after successful merge

**Example Workflow**:
```bash
git checkout main
git pull
git checkout -b CC/semantic-caching
# Make changes...
git add .
git commit -m "Implement semantic caching layer"
# Continue development with regular commits
```