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
                    Label(UICopy.TabBar.trackTab, systemImage: "mic.fill")
                }
                .tag(0)
            
            EntriesListView(dataStore: dataStore)
                .tabItem {
                    Label(UICopy.TabBar.entriesTab, systemImage: "list.bullet")
                }
                .tag(1)
            
            ChartsView(dataStore: dataStore)
                .tabItem {
                    Label(UICopy.TabBar.trendsTab, systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(2)
            
            DebugLogsView()
                .tabItem {
                    Label(UICopy.Debug.title, systemImage: "wrench.and.screwdriver")
                }
                .tag(3)
        }
        .onAppear {
            // Set unselected tab icon color to white
            UITabBar.appearance().unselectedItemTintColor = UIColor.black
            LogManager.shared.log("ContentView appeared", category: .ui)
        }
    }
}
