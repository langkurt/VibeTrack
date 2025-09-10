import SwiftUI

class FoodDataStore: ObservableObject {
    @Published var entries: [FoodEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastLLMResponse: LLMResponse?
    @Published var retryCount = 0
    @Published var lastEditSuccess: String?
    
    private let userDefaults = UserDefaults.standard
    private let entriesKey = "vibetrack_entries"
    
    init() {
        loadEntries()
        LogManager.shared.log("FoodDataStore initialized with \(entries.count) entries", category: .data)
    }
    
    func processVoiceInput(_ text: String) async {
        LogManager.shared.log("Processing voice input: \(text)", category: .data)
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let response = try await NutritionAPIService.shared.parseFood(from: text, retryCount: retryCount)
            
            await MainActor.run {
                self.lastLLMResponse = response
                
                if response.confidence < 0.5 && retryCount < 2 {
                    LogManager.shared.log("Low confidence (\(response.confidence)), requesting retry", category: .data)
                    self.errorMessage = "I'm not quite sure I understood. Could you clarify? \(response.notes ?? "")"
                    self.retryCount += 1
                } else {
                    // Auto-log entries
                    for food in response.foods {
                        let entry = FoodEntry(
                            name: food.name,
                            calories: food.calories,
                            protein: food.protein,
                            carbs: food.carbs,
                            fat: food.fat,
                            timestamp: food.timestamp,
                            notes: food.assumptions,
                            llmAssumptions: food.assumptions
                        )
                        self.entries.append(entry)
                        LogManager.shared.log("Added entry: \(entry.name)", category: .data)
                    }
                    
                    self.saveEntries()
                    self.retryCount = 0
                    
                    let totalCalories = response.foods.reduce(0) { $0 + $1.calories }
                    let totalProtein = response.foods.reduce(0.0) { $0 + $1.protein }
                    self.errorMessage = "Got it! Logged \(totalCalories) calories, \(Int(totalProtein))g protein. Tap to edit if needed."
                    LogManager.shared.log("Successfully logged \(response.foods.count) items", category: .data)
                }
                
                self.isLoading = false
            }
        } catch {
            LogManager.shared.logError(error, category: .data)
            await MainActor.run {
                self.errorMessage = "Hmm, I didn't catch that. Mind trying again?"
                self.isLoading = false
            }
        }
    }
    
    func processVoiceEdit(for entry: FoodEntry, editText: String) async {
        LogManager.shared.log("Processing voice edit for \(entry.name): \(editText)", category: .data)
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let editedEntry = try await NutritionAPIService.shared.parseEdit(
                originalEntry: entry,
                editInstruction: editText
            )
            
            await MainActor.run {
                // Update the entry in the list
                if let index = self.entries.firstIndex(where: { $0.id == entry.id }) {
                    self.entries[index] = editedEntry
                    self.saveEntries()
                    
                    // Create success message
                    let message = self.createEditSuccessMessage(
                        original: entry,
                        edited: editedEntry,
                        instruction: editText
                    )
                    self.lastEditSuccess = message
                    
                    LogManager.shared.log("Successfully edited entry: \(editedEntry.name)", category: .data)
                }
                
                self.isLoading = false
            }
        } catch {
            LogManager.shared.logError(error, category: .data)
            await MainActor.run {
                self.errorMessage = "couldn't process that edit, try again?"
                self.isLoading = false
                self.lastEditSuccess = "❌ couldn't update, try again"
            }
        }
    }
    
    private func createEditSuccessMessage(original: FoodEntry, edited: FoodEntry, instruction: String) -> String {
        // Detect what changed
        var changes: [String] = []
        
        if original.name != edited.name {
            changes.append("updated to \(edited.name)")
        }
        
        let calDiff = edited.calories - original.calories
        if calDiff != 0 {
            if calDiff > 0 {
                changes.append("+\(calDiff) cal")
            } else {
                changes.append("\(calDiff) cal")
            }
        }
        
        let proteinDiff = Int(edited.protein - original.protein)
        if proteinDiff != 0 {
            if proteinDiff > 0 {
                changes.append("+\(proteinDiff)g protein")
            } else {
                changes.append("\(proteinDiff)g protein")
            }
        }
        
        if changes.isEmpty {
            return "✅ got it! updated \(edited.name)"
        } else {
            return "✅ updated: \(changes.joined(separator: ", "))"
        }
    }
    
    func updateEntry(_ entry: FoodEntry) {
        LogManager.shared.log("Updating entry: \(entry.name)", category: .data)
        
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[index] = entry
            saveEntries()
        }
    }
    
    func deleteEntry(_ entry: FoodEntry) {
        LogManager.shared.log("Deleting entry: \(entry.name)", category: .data)
        entries.removeAll { $0.id == entry.id }
        saveEntries()
    }
    
    func deleteEntries(at offsets: IndexSet, from array: [FoodEntry]) {
        for index in offsets {
            let entry = array[index]
            deleteEntry(entry)
        }
    }
    
    private func saveEntries() {
        if let encoded = try? JSONEncoder().encode(entries) {
            userDefaults.set(encoded, forKey: entriesKey)
            LogManager.shared.log("Saved \(entries.count) entries", category: .data)
        }
    }
    
    private func loadEntries() {
        if let data = userDefaults.data(forKey: entriesKey),
           let decoded = try? JSONDecoder().decode([FoodEntry].self, from: data) {
            entries = decoded
            LogManager.shared.log("Loaded \(entries.count) entries", category: .data)
        }
    }
    
    // Analytics
    func todaysTotals() -> (calories: Int, protein: Double, carbs: Double, fat: Double) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let todaysEntries = entries.filter {
            calendar.isDate($0.timestamp, inSameDayAs: today)
        }
        
        return (
            calories: todaysEntries.reduce(0) { $0 + $1.calories },
            protein: todaysEntries.reduce(0) { $0 + $1.protein },
            carbs: todaysEntries.reduce(0) { $0 + $1.carbs },
            fat: todaysEntries.reduce(0) { $0 + $1.fat }
        )
    }
    
    func dailyCalories(for days: Int = 7) -> [(date: Date, calories: Int)] {
        let calendar = Calendar.current
        var result: [(Date, Int)] = []
        
        for dayOffset in (0..<days).reversed() {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) {
                let startOfDay = calendar.startOfDay(for: date)
                let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
                
                let dayEntries = entries.filter {
                    $0.timestamp >= startOfDay && $0.timestamp < endOfDay
                }
                
                let totalCalories = dayEntries.reduce(0) { $0 + $1.calories }
                result.append((startOfDay, totalCalories))
            }
        }
        
        return result
    }
}
