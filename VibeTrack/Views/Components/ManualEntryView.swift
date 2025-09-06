import SwiftUI

struct ManualEntryView: View {
    let dataStore: FoodDataStore
    @Binding var isPresented: Bool
    @State private var textInput = ""
    @State private var isSubmitting = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Type what you ate")
                    .font(.headline)
                    .padding(.top)
                
                // Smaller, more controlled text input
                VStack(alignment: .leading, spacing: 8) {
                    TextField("e.g., \"Had eggs for breakfast, salad for lunch\"", text: $textInput, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                        .focused($isTextFieldFocused)
                        .onSubmit {
                            submitEntry()
                        }
                    
                    if textInput.isEmpty {
                        Text("Try: \"2 eggs and toast\" or \"Large coffee with milk\"")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Submit button
                Button(action: submitEntry) {
                    HStack {
                        if isSubmitting {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        }
                        Text(isSubmitting ? "Processing..." : "Log Food")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(textInput.isEmpty || isSubmitting ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding()
                .disabled(textInput.isEmpty || isSubmitting)
            }
            .navigationTitle("Manual Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        LogManager.shared.log("Manual entry cancelled", category: .ui)
                        dismissView()
                    }
                    .disabled(isSubmitting)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isTextFieldFocused = false
                    }
                }
            }
        }
        .onAppear {
            LogManager.shared.log("ManualEntryView opened", category: .ui)
            // Auto-focus the text field
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
        }
    }
    
    private func submitEntry() {
        guard !textInput.isEmpty && !isSubmitting else { return }
        
        LogManager.shared.log("Manual entry submitted: \(textInput)", category: .ui)
        isSubmitting = true
        isTextFieldFocused = false
        
        Task {
            await dataStore.processVoiceInput(textInput)
            await MainActor.run {
                dismissView()
            }
        }
    }
    
    private func dismissView() {
        isTextFieldFocused = false
        isPresented = false
    }
}
