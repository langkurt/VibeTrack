import Foundation

struct FoodEntry: Identifiable, Codable {
    var id = UUID()  // Changed from let to var to allow ID preservation during edits
    var name: String
    var calories: Int
    var protein: Double
    var carbs: Double
    var fat: Double
    var timestamp: Date
    var notes: String?
    var llmAssumptions: String?
    
    var totalMacros: Double {
        protein + carbs + fat
    }
    
    init(name: String, calories: Int, protein: Double, carbs: Double, fat: Double, timestamp: Date, notes: String? = nil, llmAssumptions: String? = nil) {
        self.name = name
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.timestamp = timestamp
        self.notes = notes
        self.llmAssumptions = llmAssumptions
        
        LogManager.shared.log("Created FoodEntry: \(name) - \(calories) cal", category: .data)
    }
    
    // Helper method to create a copy with a specific ID
    func withID(_ id: UUID) -> FoodEntry {
        var copy = self
        copy.id = id
        return copy
    }
}
