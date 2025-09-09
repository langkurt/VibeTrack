import SwiftUI

// MARK: - Enhanced Logging Manager
class LogManager: ObservableObject {
    static let shared = LogManager()
    
    @Published var logs: [LogEntry] = []
    @Published var aiInteractions: [AIInteraction] = []
    
    private let maxLogs = 500
    private let maxInteractions = 100
    private let userDefaults = UserDefaults.standard
    private let logsKey = "vibetrack_logs"
    private let aiInteractionsKey = "vibetrack_ai_interactions"
    
    enum LogCategory: String, CaseIterable {
        case app = "📱 APP"
        case api = "🌐 API"
        case speech = "🎤 SPEECH"
        case data = "💾 DATA"
        case ui = "🎨 UI"
        case error = "❌ ERROR"
        
        var color: Color {
            switch self {
            case .app: return .blue
            case .api: return .green
            case .speech: return .orange
            case .data: return .purple
            case .ui: return .pink
            case .error: return .red
            }
        }
    }
    
    struct LogEntry: Identifiable, Codable {
        let id = UUID()
        let timestamp: Date
        let category: String
        let message: String
        let file: String
        let function: String
        let line: Int
        
        var formattedTime: String {
            let formatter = DateFormatter()
            formatter.timeStyle = .medium
            return formatter.string(from: timestamp)
        }
    }
    
    struct AIInteraction: Identifiable, Codable {
        let id = UUID()
        let timestamp: Date
        let input: String
        let output: String?
        let type: InteractionType
        
        enum InteractionType: String, Codable {
            case request = "Request"
            case response = "Response"
            case error = "Error"
        }
    }
    
    init() {
        loadLogs()
        loadAIInteractions()
    }
    
    func log(_ message: String, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
        let filename = URL(fileURLWithPath: file).lastPathComponent
        let entry = LogEntry(
            timestamp: Date(),
            category: category.rawValue,
            message: message,
            file: filename,
            function: function,
            line: line
        )
        
        DispatchQueue.main.async {
            self.logs.insert(entry, at: 0)
            if self.logs.count > self.maxLogs {
                self.logs = Array(self.logs.prefix(self.maxLogs))
            }
            self.saveLogs()
        }
        
        // Also print to console
        print("[\(category.rawValue)] \(filename):\(line) - \(function) - \(message)")
    }
    
    func logError(_ error: Error, category: LogCategory = .error, file: String = #file, function: String = #function, line: Int = #line) {
        log("ERROR: \(error.localizedDescription)", category: category, file: file, function: function, line: line)
    }
    
    func logAIInteraction(input: String, output: String?, type: AIInteraction.InteractionType) {
        let interaction = AIInteraction(
            timestamp: Date(),
            input: input,
            output: output,
            type: type
        )
        
        DispatchQueue.main.async {
            self.aiInteractions.insert(interaction, at: 0)
            if self.aiInteractions.count > self.maxInteractions {
                self.aiInteractions = Array(self.aiInteractions.prefix(self.maxInteractions))
            }
            self.saveAIInteractions()
        }
    }
    
    func clearLogs() {
        logs.removeAll()
        saveLogs()
    }
    
    func clearAIInteractions() {
        aiInteractions.removeAll()
        saveAIInteractions()
    }
    
    func exportLogs() -> String {
        var export = "VibeTrack Debug Logs\n"
        export += "Generated: \(Date())\n\n"
        
        export += "=== AI Interactions ===\n"
        for interaction in aiInteractions {
            export += "\n[\(interaction.timestamp)] \(interaction.type.rawValue)\n"
            export += "Input: \(interaction.input)\n"
            if let output = interaction.output {
                export += "Output: \(output)\n"
            }
        }
        
        export += "\n\n=== System Logs ===\n"
        for log in logs {
            export += "\n[\(log.formattedTime)] \(log.category)\n"
            export += "\(log.file):\(log.line) - \(log.message)\n"
        }
        
        return export
    }
    
    private func saveLogs() {
        if let encoded = try? JSONEncoder().encode(logs) {
            userDefaults.set(encoded, forKey: logsKey)
        }
    }
    
    private func loadLogs() {
        if let data = userDefaults.data(forKey: logsKey),
           let decoded = try? JSONDecoder().decode([LogEntry].self, from: data) {
            logs = decoded
        }
    }
    
    private func saveAIInteractions() {
        if let encoded = try? JSONEncoder().encode(aiInteractions) {
            userDefaults.set(encoded, forKey: aiInteractionsKey)
        }
    }
    
    private func loadAIInteractions() {
        if let data = userDefaults.data(forKey: aiInteractionsKey),
           let decoded = try? JSONDecoder().decode([AIInteraction].self, from: data) {
            aiInteractions = decoded
        }
    }
}
