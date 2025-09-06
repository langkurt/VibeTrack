import SwiftUI

struct EntriesListView: View {
    @ObservedObject var dataStore: FoodDataStore
    @State private var editingEntry: FoodEntry?
    
    var groupedEntries: [(String, [FoodEntry])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: dataStore.entries.sorted { $0.timestamp > $1.timestamp }) { entry in
            calendar.startOfDay(for: entry.timestamp)
        }
        
        return grouped.sorted { $0.key > $1.key }.map { date, entries in
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.doesRelativeDateFormatting = true
            return (formatter.string(from: date), entries)
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Subtle gradient background
                AdaptiveGradientBackground(intensity: .subtle)
                
                if dataStore.entries.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "fork.knife.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No meals logged")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Tap the mic and tell me what you've eaten!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .onAppear {
                        LogManager.shared.log("EntriesListView: Empty state shown", category: .ui)
                    }
                } else {
                    List {
                        ForEach(groupedEntries, id: \.0) { date, entries in
                            Section(header: Text(date)) {
                                ForEach(entries) { entry in
                                    EntryRowView(entry: entry)
                                        .listRowBackground(Color.white.opacity(0.7)) // Subtle background for list rows
                                        .onTapGesture {
                                            LogManager.shared.log("Entry tapped: \(entry.name)", category: .ui)
                                            editingEntry = entry
                                        }
                                }
                                .onDelete { indexSet in
                                    LogManager.shared.log("Deleting \(indexSet.count) entries", category: .ui)
                                    dataStore.deleteEntries(at: indexSet, from: entries)
                                }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden) // Hide default list background to show gradient
                    .background(Color.clear) // Make list background transparent
                }
            }
            .navigationTitle("Food Log")
            .sheet(item: $editingEntry) { entry in
                EditEntryView(entry: entry, dataStore: dataStore)
            }
        }
        .onAppear {
            LogManager.shared.log("EntriesListView appeared with \(dataStore.entries.count) entries", category: .ui)
        }
    }
}
