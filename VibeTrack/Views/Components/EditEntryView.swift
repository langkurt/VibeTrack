import SwiftUI

struct EditEntryView: View {
    @State var entry: FoodEntry
    let dataStore: FoodDataStore
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(UICopy.EditEntry.sectionFood) {
                    TextField(UICopy.EditEntry.nameField, text: $entry.name)
                    
                    HStack {
                        Text(UICopy.EditEntry.caloriesField)
                        Spacer()
                        TextField("0", value: $entry.calories, format: .number)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numberPad)
                    }
                }
                
                Section(UICopy.EditEntry.sectionMacros) {
                    HStack {
                        Text(UICopy.EditEntry.proteinField)
                        Spacer()
                        TextField("0", value: $entry.protein, format: .number)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                    }
                    
                    HStack {
                        Text(UICopy.EditEntry.carbsField)
                        Spacer()
                        TextField("0", value: $entry.carbs, format: .number)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                    }
                    
                    HStack {
                        Text(UICopy.EditEntry.fatField)
                        Spacer()
                        TextField("0", value: $entry.fat, format: .number)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                    }
                }
                
                Section(UICopy.EditEntry.sectionTime) {
                    DatePicker(UICopy.EditEntry.timestampField, selection: $entry.timestamp)
                }
                
                if let assumptions = entry.llmAssumptions {
                    Section(UICopy.EditEntry.sectionAssumptions) {
                        Text(assumptions)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle(UICopy.EditEntry.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(UICopy.EditEntry.cancelButton) {
                        LogManager.shared.log("Edit cancelled for: \(entry.name)", category: .ui)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(UICopy.EditEntry.saveButton) {
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

