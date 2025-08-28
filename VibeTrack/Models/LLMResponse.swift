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
    }
    
    let foods: [ParsedFood]
    let confidence: Double
    let notes: String?
}
