import SwiftUI

@main
struct VibeTrackApp: App {
    @StateObject private var speechManager = SpeechManager()
    
    init() {
        // Enable logging
        LogManager.shared.log("App initialized", category: .app)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(speechManager)
        }
    }
}

// MARK: - Logging Manager
class LogManager {
    static let shared = LogManager()
    
    enum LogCategory: String {
        case app = "📱 APP"
        case api = "🌐 API"
        case speech = "🎤 SPEECH"
        case data = "💾 DATA"
        case ui = "🎨 UI"
        case error = "❌ ERROR"
    }
    
    func log(_ message: String, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
        let filename = URL(fileURLWithPath: file).lastPathComponent
        print("[\(category.rawValue)] \(filename):\(line) - \(function) - \(message)")
    }
    
    func logError(_ error: Error, category: LogCategory = .error, file: String = #file, function: String = #function, line: Int = #line) {
        let filename = URL(fileURLWithPath: file).lastPathComponent
        print("[\(category.rawValue)] \(filename):\(line) - \(function) - ERROR: \(error.localizedDescription)")
    }
}
