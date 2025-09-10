import SwiftUI

struct EntriesListView: View {
    @ObservedObject var dataStore: FoodDataStore
    @EnvironmentObject var speechManager: SpeechManager
    @State private var editingEntry: FoodEntry?
    @State private var voiceEditingEntry: FoodEntry?
    @State private var showToast = false
    @State private var toastMessage = ""
    
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
                        Text(UICopy.EntriesList.emptyStateTitle)
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text(UICopy.EntriesList.emptyStateMessage)
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
                                        .listRowBackground(Color.white.opacity(0.7))
                                        .onTapGesture {
                                            LogManager.shared.log("Entry tapped: \(entry.name)", category: .ui)
                                            editingEntry = entry
                                        }
                                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                            Button {
                                                startVoiceEdit(for: entry)
                                            } label: {
                                                Label(UICopy.EntriesList.voiceEditButton, systemImage: "mic.fill")
                                            }
                                            .tint(.orange)
                                        }
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button(role: .destructive) {
                                                LogManager.shared.log("Deleting entry: \(entry.name)", category: .ui)
                                                dataStore.deleteEntry(entry)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                }
                
                // Voice Editing Overlay
                if let entry = voiceEditingEntry {
                    VoiceEditOverlay(
                        entry: entry,
                        isRecording: speechManager.isRecording,
                        transcribedText: speechManager.transcribedText,
                        onStop: {
                            stopVoiceEdit()
                        }
                    )
                }
                
                // Toast Notification
                if showToast {
                    VStack {
                        Spacer()
                        ToastView(message: toastMessage)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    withAnimation {
                                        showToast = false
                                    }
                                }
                            }
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle(UICopy.EntriesList.title)
            .sheet(item: $editingEntry) { entry in
                EditEntryView(entry: entry, dataStore: dataStore)
            }
        }
        .onAppear {
            LogManager.shared.log("EntriesListView appeared with \(dataStore.entries.count) entries", category: .ui)
        }
        .onChange(of: dataStore.lastEditSuccess) { success in
            if let success = success {
                showSuccessToast(success)
                dataStore.lastEditSuccess = nil
            }
        }
    }
    
    private func startVoiceEdit(for entry: FoodEntry) {
        LogManager.shared.log("Starting voice edit for: \(entry.name)", category: .ui)
        voiceEditingEntry = entry
        speechManager.startRecording()
    }
    
    private func stopVoiceEdit() {
        guard let entry = voiceEditingEntry else { return }
        
        speechManager.stopRecording()
        
        if !speechManager.transcribedText.isEmpty &&
           speechManager.transcribedText != UICopy.Recording.listeningActive {
            // Process the edit
            Task {
                await dataStore.processVoiceEdit(
                    for: entry,
                    editText: speechManager.transcribedText
                )
            }
        }
        
        voiceEditingEntry = nil
    }
    
    private func showSuccessToast(_ message: String) {
        toastMessage = message
        withAnimation(.easeInOut(duration: 0.3)) {
            showToast = true
        }
    }
}

// MARK: - Voice Edit Overlay
struct VoiceEditOverlay: View {
    let entry: FoodEntry
    let isRecording: Bool
    let transcribedText: String
    let onStop: () -> Void
    
    var body: some View {
        ZStack {
            // Dim background
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    onStop()
                }
            
            VStack(spacing: 20) {
                // Current entry info
                VStack(spacing: 8) {
                    Text(UICopy.EntriesList.voiceEditingLabel)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    Text(entry.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("\(entry.calories) cal")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                // Recording indicator
                HStack(spacing: 12) {
                    Image(systemName: "mic.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                        .scaleEffect(isRecording ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isRecording)
                    
                    Text(UICopy.EntriesList.voiceEditPrompt)
                        .font(.body)
                        .foregroundColor(.white)
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(20)
                
                // Transcribed text
                if !transcribedText.isEmpty && transcribedText != UICopy.Recording.listeningActive {
                    Text(transcribedText)
                        .font(.body)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                }
                
                // Stop button
                Button(action: onStop) {
                    HStack {
                        Image(systemName: "stop.fill")
                        Text(UICopy.EntriesList.voiceEditDone)
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Color.red)
                    .cornerRadius(25)
                }
                .padding(.top)
            }
            .padding()
        }
    }
}

// MARK: - Toast View
struct ToastView: View {
    let message: String
    
    var body: some View {
        Text(message)
            .font(.subheadline)
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(Color.green)
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
            )
            .padding(.horizontal)
    }
}
