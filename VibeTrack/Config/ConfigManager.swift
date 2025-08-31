import Foundation

class ConfigManager {
    static let shared = ConfigManager()
    
    private init() {
        LogManager.shared.log("ConfigManager initialized", category: .app)
    }
    
    // Read API key from Info.plist (set via xcconfig)
    var apiKey: String {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "ANTHROPIC_API_KEY") as? String,
              !apiKey.isEmpty,
              apiKey != "$(ANTHROPIC_API_KEY)" else {
            LogManager.shared.log("WARNING: API key not found or not configured", category: .error)
            return ""
        }
        LogManager.shared.log("API key loaded successfully", category: .api)
        return apiKey
    }
    
    var hasValidAPIKey: Bool {
        !apiKey.isEmpty
    }
}
