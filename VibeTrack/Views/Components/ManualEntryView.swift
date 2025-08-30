import SwiftUI

struct ManualEntryView: View {
    let dataStore: FoodDataStore
    @Binding var isPresented: Bool
    @State private var textInput = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Type what you ate")
                    .font(.headline)
                    .padding(.top)
                
                TextEditor(text: $textInput)
                    .padding(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .padding()
                
                if textInput.isEmpty {
                    Text("Example: \"Had eggs for breakfast, salad for lunch\"")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    LogManager.shared.log("Manual entry submitted: \(textInput)", category: .ui)
                    Task {
                        await dataStore.processVoiceInput(textInput)
                        isPresented = false
                    }
                }) {
                    Text("Log Food")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding()
                .disabled(textInput.isEmpty)
            }
            .navigationTitle("Manual Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        LogManager.shared.log("Manual entry cancelled", category: .ui)
                        isPresented = false
                    }
                }
            }
        }
        .onAppear {
            LogManager.shared.log("ManualEntryView opened", category: .ui)
        }
    }
}

