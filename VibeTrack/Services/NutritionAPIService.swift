import Foundation

class NutritionAPIService {
    static let shared = NutritionAPIService()
    
    func parseFood(from text: String, retryCount: Int = 0) async throws -> LLMResponse {
        LogManager.shared.log("Parsing food from text: '\(text)' (retry: \(retryCount))", category: .api)
        
        // Store the input for logging
        LogManager.shared.logAIInteraction(input: text, output: nil, type: .request)
        
        // Check for API key
        guard ConfigManager.shared.hasValidAPIKey else {
            LogManager.shared.log("No valid API key, using mock response", category: .api)
            return mockParseFoodResponse(text: text)
        }
        
        let url = URL(string: "https://api.anthropic.com/v1/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(ConfigManager.shared.apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        let systemPrompt = """
        You are a nutrition parser. Extract food items from natural speech and return ONLY valid JSON.
        
        Rules:
        1. Search for accurate nutrition data for specific foods/brands mentioned
        2. Use standard serving sizes if not specified
        3. Parse relative times (yesterday, this morning, etc) into timestamps
        4. Handle multiple meals in one input
        5. Make reasonable assumptions but note them
        
        Output format:
        {
          "foods": [
            {
              "name": "Food name",
              "calories": number,
              "protein": number (grams),
              "carbs": number (grams),
              "fat": number (grams),
              "timestamp": "ISO 8601 date",
              "assumptions": "Any assumptions made"
            }
          ],
          "confidence": 0.0-1.0,
          "notes": "Overall notes if any"
        }
        
        Current time: \(ISO8601DateFormatter().string(from: Date()))
        """
        
        let retryNote = retryCount > 0 ? " (User clarifying - attempt \(retryCount + 1)/3)" : ""
        
        let body: [String: Any] = [
            "model": "claude-3-5-sonnet-20241022",
            "max_tokens": 1000,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": text + retryNote]
            ]
        ]
        
        LogManager.shared.log("Sending API request", category: .api)
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            LogManager.shared.log("API Response status: \(httpResponse.statusCode)", category: .api)
        }
        
        // Parse the Claude response
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
            LogManager.shared.log("API Response received", category: .api)
            
            if let content = (json["content"] as? [[String: Any]])?.first,
               let responseText = content["text"] as? String {
                LogManager.shared.log("Extracted response text: \(responseText)", category: .api)
                
                // Log the AI response
                LogManager.shared.logAIInteraction(input: text, output: responseText, type: .response)
                
                if let responseData = responseText.data(using: .utf8) {
                    let llmResponse = try JSONDecoder().decode(LLMResponse.self, from: responseData)
                    LogManager.shared.log("Successfully parsed \(llmResponse.foods.count) food items", category: .api)
                    return llmResponse
                }
            }
        }
        
        LogManager.shared.log("Failed to parse API response, using mock", category: .api)
        return mockParseFoodResponse(text: text)
    }
    
    private func mockParseFoodResponse(text: String) -> LLMResponse {
        LogManager.shared.log("Generating mock response for: \(text)", category: .api)
        
        let now = Date()
        var foods: [LLMResponse.ParsedFood] = []
        
        // Simple keyword matching for demo
        let lowercased = text.lowercased()
        
        if lowercased.contains("big mac") {
            foods.append(.init(
                name: "Big Mac",
                calories: 563,
                protein: 26,
                carbs: 45,
                fat: 33,
                timestamp: now,
                assumptions: "Standard McDonald's Big Mac"
            ))
        }
        
        if lowercased.contains("fries") || lowercased.contains("french fries") {
            let size = lowercased.contains("large") ? "Large" : "Medium"
            foods.append(.init(
                name: "\(size) Fries",
                calories: size == "Large" ? 444 : 333,
                protein: size == "Large" ? 5 : 4,
                carbs: size == "Large" ? 57 : 43,
                fat: size == "Large" ? 22 : 16,
                timestamp: now,
                assumptions: "McDonald's \(size) fries"
            ))
        }
        
        if lowercased.contains("diet coke") || lowercased.contains("diet cola") {
            foods.append(.init(
                name: "Diet Coke",
                calories: 0,
                protein: 0,
                carbs: 0,
                fat: 0,
                timestamp: now,
                assumptions: "Standard diet cola"
            ))
        }
        
        if lowercased.contains("egg") {
            foods.append(.init(
                name: "Egg Sandwich",
                calories: 320,
                protein: 18,
                carbs: 28,
                fat: 14,
                timestamp: lowercased.contains("breakfast") ? Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: now)! : now,
                assumptions: "Standard egg sandwich with bread"
            ))
        }
        
        if lowercased.contains("bagel") {
            foods.append(.init(
                name: "Bagel with Cream Cheese",
                calories: 380,
                protein: 13,
                carbs: 56,
                fat: 11,
                timestamp: lowercased.contains("yesterday") ? Calendar.current.date(byAdding: .day, value: -1, to: now)! : now,
                assumptions: "Plain bagel with 2 tbsp cream cheese"
            ))
        }
        
        if foods.isEmpty {
            foods.append(.init(
                name: "Unrecognized food",
                calories: 200,
                protein: 10,
                carbs: 20,
                fat: 8,
                timestamp: now,
                assumptions: "Could not parse specific food, using generic estimate"
            ))
        }
        
        let mockResponse = LLMResponse(
            foods: foods,
            confidence: 0.8,
            notes: "These are estimates based on typical values"
        )
        
        // Log mock interaction
        LogManager.shared.logAIInteraction(
            input: text,
            output: "Mock response: \(foods.count) items",
            type: .response
        )
        
        LogManager.shared.log("Mock response generated with \(foods.count) items", category: .api)
        
        return mockResponse
    }
}
