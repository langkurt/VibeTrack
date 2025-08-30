import SwiftUI

struct EditEntryView: View {
    @State var entry: FoodEntry
    let dataStore: FoodDataStore
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Food Details") {
                    TextField("Name", text: $entry.name)
                    
                    HStack {
                        Text("Calories")
                        Spacer()
                        TextField("0", value: $entry.calories, format: .number)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numberPad)
                    }
                }
                
                Section("Macros (grams)") {
                    HStack {
                        Text("Protein")
                        Spacer()
                        TextField("0", value: $entry.protein, format: .number)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                    }
                    
                    HStack {
                        Text("Carbs")
                        Spacer()
                        TextField("0", value: $entry.carbs, format: .number)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                    }
                    
                    HStack {
                        Text("Fat")
                        Spacer()
                        TextField("0", value: $entry.fat, format: .number)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                    }
                }
                
                Section("Time") {
                    DatePicker("When", selection: $entry.timestamp)
                }
                
                if let assumptions = entry.llmAssumptions {
                    Section("AI Assumptions") {
                        Text(assumptions)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        LogManager.shared.log("Edit cancelled for: \(entry.name)", category: .ui)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        LogManager.shared.log("Saving edits for: \(entry.name)", category: .ui)
                        dataStore.updateEntry(entry)
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            LogManager.shared.log("EditEntryView opened for: \(entry.name)", category: .ui)
        }
    }
}

