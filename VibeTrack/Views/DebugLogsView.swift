import SwiftUI

struct DebugLogsView: View {
    @StateObject private var logManager = LogManager.shared
    @State private var selectedTab = 0
    @State private var filterCategory: LogManager.LogCategory?
    @State private var searchText = ""
    @State private var showingShareSheet = false
    @State private var exportText = ""
    
    var filteredLogs: [LogManager.LogEntry] {
        var filtered = logManager.logs
        
        if let category = filterCategory {
            filtered = filtered.filter { $0.category == category.rawValue }
        }
        
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.message.localizedCaseInsensitiveContains(searchText) ||
                $0.file.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Picker
                Picker("View", selection: $selectedTab) {
                    Text("AI Interactions").tag(0)
                    Text("System Logs").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                if selectedTab == 0 {
                    // AI Interactions Tab
                    aiInteractionsView
                } else {
                    // System Logs Tab
                    systemLogsView
                }
            }
            .navigationTitle("Debug Logs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { exportLogs() }) {
                            Label("Export Logs", systemImage: "square.and.arrow.up")
                        }
                        
                        Button(action: { clearLogs() }) {
                            Label("Clear All", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(items: [exportText])
            }
        }
    }
    
    private var aiInteractionsView: some View {
        Group {
            if logManager.aiInteractions.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("No AI interactions yet")
                        .foregroundColor(.secondary)
                    Text("Start using voice input to see interactions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(logManager.aiInteractions) { interaction in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label(interaction.type.rawValue, systemImage: interaction.type == .request ? "arrow.up.circle" : "arrow.down.circle")
                                .font(.caption)
                                .foregroundColor(interaction.type == .request ? .blue : .green)
                            
                            Spacer()
                            
                            Text(interaction.timestamp, style: .time)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Input:")
                                .font(.caption)
                                .fontWeight(.semibold)
                            Text(interaction.input)
                                .font(.caption)
                                .foregroundColor(.primary)
                                .padding(6)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(6)
                            
                            if let output = interaction.output {
                                Text("Output:")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .padding(.top, 4)
                                Text(output)
                                    .font(.caption)
                                    .foregroundColor(.primary)
                                    .padding(6)
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(6)
                                    .lineLimit(10)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
    
    private var systemLogsView: some View {
        VStack(spacing: 0) {
            // Filter and Search Bar
            VStack(spacing: 12) {
                // Category Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(
                            title: "All",
                            isSelected: filterCategory == nil,
                            action: { filterCategory = nil }
                        )
                        
                        ForEach(LogManager.LogCategory.allCases, id: \.self) { category in
                            FilterChip(
                                title: category.rawValue.replacingOccurrences(of: " ", with: ""),
                                isSelected: filterCategory == category,
                                color: category.color,
                                action: { filterCategory = category }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search logs...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
            .background(Color(.systemGroupedBackground))
            
            // Logs List
            if filteredLogs.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text(searchText.isEmpty ? "No logs available" : "No matching logs")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(filteredLogs) { log in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(log.category)
                                .font(.caption)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            Text(log.formattedTime)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Text(log.message)
                            .font(.caption)
                            .foregroundColor(.primary)
                            .lineLimit(3)
                        
                        Text("\(log.file):\(log.line)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }
    
    private func exportLogs() {
        exportText = logManager.exportLogs()
        showingShareSheet = true
    }
    
    private func clearLogs() {
        if selectedTab == 0 {
            logManager.clearAIInteractions()
        } else {
            logManager.clearLogs()
        }
    }
}
