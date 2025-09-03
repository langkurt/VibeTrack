import Foundation

struct LLMResponse: Codable {
    struct ParsedFood: Codable {
        let name: String
        let calories: Int
        let protein: Double
        let carbs: Double
        let fat: Double
        let timestamp: Date
        let assumptions: String?
        
        // Custom coding keys and date handling
        private enum CodingKeys: String, CodingKey {
            case name, calories, protein, carbs, fat, timestamp, assumptions
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            name = try container.decode(String.self, forKey: .name)
            calories = try container.decode(Int.self, forKey: .calories)
            protein = try container.decode(Double.self, forKey: .protein)
            carbs = try container.decode(Double.self, forKey: .carbs)
            fat = try container.decode(Double.self, forKey: .fat)
            assumptions = try container.decodeIfPresent(String.self, forKey: .assumptions)
            
            // Handle timestamp conversion from string to Date
            let timestampString = try container.decode(String.self, forKey: .timestamp)
            let formatter = ISO8601DateFormatter()
            
            if let date = formatter.date(from: timestampString) {
                timestamp = date
            } else {
                // Fallback to current date if parsing fails
                timestamp = Date()
                LogManager.shared.log("Failed to parse timestamp: \(timestampString), using current date", category: .api)
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            try container.encode(name, forKey: .name)
            try container.encode(calories, forKey: .calories)
            try container.encode(protein, forKey: .protein)
            try container.encode(carbs, forKey: .carbs)
            try container.encode(fat, forKey: .fat)
            try container.encodeIfPresent(assumptions, forKey: .assumptions)
            
            // Convert Date back to ISO8601 string
            let formatter = ISO8601DateFormatter()
            try container.encode(formatter.string(from: timestamp), forKey: .timestamp)
        }
        
        // Convenience initializer for manual creation
        init(name: String, calories: Int, protein: Double, carbs: Double, fat: Double, timestamp: Date, assumptions: String? = nil) {
            self.name = name
            self.calories = calories
            self.protein = protein
            self.carbs = carbs
            self.fat = fat
            self.timestamp = timestamp
            self.assumptions = assumptions
        }
    }
    
    let foods: [ParsedFood]
    let confidence: Double
    let notes: String?
}
