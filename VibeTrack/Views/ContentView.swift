import SwiftUI

struct ContentView: View {
    @StateObject private var dataStore = FoodDataStore()
    @EnvironmentObject var speechManager: SpeechManager
    @State private var selectedTab = 0
    @State private var showingManualEntry = false
    @State private var manualInput = ""
    
    var body: some View {
        TabView(selection: $selectedTab) {
            MainRecordingView(dataStore: dataStore)
                .tabItem {
                    Label("Track", systemImage: "mic.fill")
                }
                .tag(0)
            
            EntriesListView(dataStore: dataStore)
                .tabItem {
                    Label("Entries", systemImage: "list.bullet")
                }
                .tag(1)
            
            ChartsView(dataStore: dataStore)
                .tabItem {
                    Label("Trends", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(2)
        }
        .onAppear {
            LogManager.shared.log("ContentView appeared", category: .ui)
        }
    }
}
