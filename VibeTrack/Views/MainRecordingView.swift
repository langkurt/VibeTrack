import SwiftUI

struct MainRecordingView: View {
    @ObservedObject var dataStore: FoodDataStore
    @EnvironmentObject var speechManager: SpeechManager
    @State private var showingManualEntry = false
    
    var body: some View {
        ZStack {
            // Gradient Background
            AdaptiveGradientBackground(intensity: .full)
            
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("What did you eat?")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    let totals = dataStore.todaysTotals()
                    Text("\(totals.calories) calories today")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Voice Input Section
                VStack(spacing: 20) {
                    // Microphone Button
                    Button(action: {
                        if speechManager.isRecording {
                            speechManager.stopRecording()
                            Task {
                                await dataStore.processVoiceInput(speechManager.transcribedText)
                            }
                        } else {
                            speechManager.startRecording()
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(speechManager.isRecording ? Color.red : Color.white.opacity(0.2))
                                .frame(width: 120, height: 120)
                            
                            Circle()
                                .stroke(Color.white.opacity(0.4), lineWidth: 2)
                                .frame(width: 120, height: 120)
                                .scaleEffect(speechManager.isRecording ? 1.15 : 1.0)
                                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: speechManager.isRecording)
                            
                            Image(systemName: speechManager.isRecording ? "stop.fill" : "mic.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                        }
                    }
                    
                    // Transcribed Text
                    if !speechManager.transcribedText.isEmpty && speechManager.transcribedText != "Listening..." {
                        Text(speechManager.transcribedText)
                            .font(.body)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }
                    
                    // Status Messages
                    if dataStore.isLoading {
                        ProgressView()
                            .tint(.white)
                            .padding()
                    }
                    
                    if let error = dataStore.errorMessage {
                        VStack(spacing: 12) {
                            Text(error)
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white)
                            
                            if dataStore.retryCount > 0 && dataStore.retryCount < 2 {
                                Button("Try explaining again") {
                                    speechManager.startRecording()
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.white)
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Manual Entry Option
                    Button(action: { showingManualEntry = true }) {
                        Text("Or tap to type...")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                Spacer()
                
                // Recent Entries Preview
                if !dataStore.entries.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recent entries")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(dataStore.entries.prefix(5)) { entry in
                                    VStack(alignment: .leading) {
                                        Text(entry.name)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                        Text("\(entry.calories) cal")
                                            .font(.caption2)
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    .padding(8)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom)
                }
            }
        }
        .sheet(isPresented: $showingManualEntry) {
            ManualEntryView(dataStore: dataStore, isPresented: $showingManualEntry)
        }
    }
}
