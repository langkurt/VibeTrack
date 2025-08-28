import Foundation

struct FoodEntry: Identifiable, Codable {
    let id = UUID()
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
}
