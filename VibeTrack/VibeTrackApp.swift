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
