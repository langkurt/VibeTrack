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
        You are a nutrition parser that MUST return structured JSON data. Follow these rules:

        1. Extract food items from natural speech
        2. Use your knowledge of nutrition data for foods/brands
        3. Use standard serving sizes if not specified
        4. Parse relative times (yesterday, this morning, etc) into timestamps
        5. Handle multiple meals in one input
        6. Make reasonable assumptions but note them
        7. ALWAYS return valid JSON in the exact format specified below
        8. DO NOT use any tools or search - use your existing knowledge

        CRITICAL: Your response must be ONLY a valid JSON object. No explanations, no search queries, no other text.

        Required JSON format:
        {
          "foods": [
            {
              "name": "Food name",
              "calories": number,
              "protein": number (grams),
              "carbs": number (grams), 
              "fat": number (grams),
              "timestamp": "ISO 8601 date string",
              "assumptions": "Any assumptions made (optional)"
            }
          ],
          "confidence": 0.0-1.0,
          "notes": "Overall notes if any (optional)"
        }
        
        Current time: \(ISO8601DateFormatter().string(from: Date()))
        
        Remember: ONLY return the JSON object. No other text or actions.
        """
        
        let retryNote = retryCount > 0 ? " (User clarifying - attempt \(retryCount + 1)/3)" : ""
        
        let body: [String: Any] = [
            "model": "claude-3-5-sonnet-20241022",
            "max_tokens": 1000,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": text + retryNote]
            ],
            "tools": [
                [
                    "type": "web_search_20250305",
                    "name": "web_search",
                    "max_uses": 3
                ]
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
    
    func parseEdit(originalEntry: FoodEntry, editInstruction: String) async throws -> FoodEntry {
        LogManager.shared.log("Parsing edit: '\(editInstruction)' for \(originalEntry.name)", category: .api)
        
        // Store the input for logging
        let editContext = "Original: \(originalEntry.name) (\(originalEntry.calories) cal) | Edit: \(editInstruction)"
        LogManager.shared.logAIInteraction(input: editContext, output: nil, type: .request)
        
        // Check for API key
        guard ConfigManager.shared.hasValidAPIKey else {
            LogManager.shared.log("No valid API key, using mock edit response", category: .api)
            return mockEditResponse(original: originalEntry, instruction: editInstruction)
        }
        
        let url = URL(string: "https://api.anthropic.com/v1/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(ConfigManager.shared.apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        let systemPrompt = """
        Apply the user's edit instruction to the existing food entry.
        
        The user will provide:
        1. Original food entry data
        2. An edit instruction in natural language
        
        Keep the original timestamp unless specifically instructed to change it.
        
        You are a nutrition parser that MUST return structured JSON data. Follow these rules:

        1. Extract food items from natural speech
        2. Use your knowledge of nutrition data for foods/brands
        3. Use standard serving sizes if not specified
        4. Parse relative times (yesterday, this morning, etc) into timestamps
        5. Handle multiple meals in one input
        6. Make reasonable assumptions but note them
        7. ALWAYS return valid JSON in the exact format specified below
        8. DO NOT use any tools or search - use your existing knowledge

        CRITICAL: Your response must be ONLY a valid JSON object. No explanations, no search queries, no other text.

        Required JSON format:
        {
          "foods": [
            {
              "name": "Food name",
              "calories": number,
              "protein": number (grams),
              "carbs": number (grams), 
              "fat": number (grams),
              "timestamp": "ISO 8601 date string",
              "assumptions": "Any assumptions made (optional)"
            }
          ],
          "confidence": 0.0-1.0,
          "notes": "Overall notes if any (optional)"
        }
        
        Current time: \(ISO8601DateFormatter().string(from: Date()))
        
        Remember: ONLY return the JSON object. No other text or actions.
        """
        
        let originalData = """
        Original Entry:
        - Name: \(originalEntry.name)
        - Calories: \(originalEntry.calories)
        - Protein: \(originalEntry.protein)g
        - Carbs: \(originalEntry.carbs)g
        - Fat: \(originalEntry.fat)g
        - Timestamp: \(ISO8601DateFormatter().string(from: originalEntry.timestamp))
        
        Edit Instruction: "\(editInstruction)"
        """
        
        let body: [String: Any] = [
            "model": "claude-3-5-sonnet-20241022",
            "max_tokens": 2500,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": originalData]
            ],
            "tools": [
                [
                    "type": "web_search_20250305",
                    "name": "web_search",
                    "max_uses": 2
                ]
            ]
        ]
        
        LogManager.shared.log("Sending edit API request", category: .api)
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            LogManager.shared.log("Edit API Response status: \(httpResponse.statusCode)", category: .api)
        }
        
        // Parse the Claude response
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
            LogManager.shared.log("Edit API Response received", category: .api)
            
            if let content = (json["content"] as? [[String: Any]])?.first,
               let responseText = content["text"] as? String {
                LogManager.shared.log("Extracted edit response text", category: .api)
                
                // Log the AI response
                LogManager.shared.logAIInteraction(input: editContext, output: responseText, type: .response)
                
                if let responseData = responseText.data(using: .utf8) {
                    // Parse as LLMResponse first, then extract the food item
                    let llmResponse = try JSONDecoder().decode(LLMResponse.self, from: responseData)
                    
                    guard let editedFood = llmResponse.foods.first else {
                        throw NSError(domain: "NutritionAPIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No food items in edit response"])
                    }
                    
                    // Create updated entry preserving the original ID
                    var updatedEntry = FoodEntry(
                        name: editedFood.name,
                        calories: editedFood.calories,
                        protein: editedFood.protein,
                        carbs: editedFood.carbs,
                        fat: editedFood.fat,
                        timestamp: editedFood.timestamp,
                        notes: originalEntry.notes,
                        llmAssumptions: editedFood.assumptions
                    )
                    
                    // Copy the original ID
                    updatedEntry.id = originalEntry.id
                    
                    LogManager.shared.log("Successfully parsed edited entry", category: .api)
                    return updatedEntry
                }
            }
        }
        
        LogManager.shared.log("Failed to parse edit API response, using mock", category: .api)
        return mockEditResponse(original: originalEntry, instruction: editInstruction)
    }
    
    private func mockEditResponse(original: FoodEntry, instruction: String) -> FoodEntry {
        LogManager.shared.log("Generating mock edit for: \(instruction)", category: .api)
        
        var edited = original
        let lowercased = instruction.lowercased()
        
        // Handle portion size changes
        if lowercased.contains("large") {
            edited.calories = Int(Double(original.calories) * 1.5)
            edited.protein = original.protein * 1.5
            edited.carbs = original.carbs * 1.5
            edited.fat = original.fat * 1.5
            if !lowercased.contains("fries") {
                edited.name = "Large \(original.name)"
            } else {
                edited.name = edited.name.replacingOccurrences(of: "Medium", with: "Large")
            }
            edited.llmAssumptions = "Adjusted to large portion size (1.5x)"
        }
        else if lowercased.contains("small") {
            edited.calories = Int(Double(original.calories) * 0.75)
            edited.protein = original.protein * 0.75
            edited.carbs = original.carbs * 0.75
            edited.fat = original.fat * 0.75
            edited.name = "Small \(original.name)"
            edited.llmAssumptions = "Adjusted to small portion size (0.75x)"
        }
        
        // Handle calorie adjustments
        if lowercased.contains("add 100") {
            edited.calories += 100
            edited.llmAssumptions = "Added 100 calories as requested"
        }
        else if lowercased.contains("add 200") {
            edited.calories += 200
            edited.llmAssumptions = "Added 200 calories as requested"
        }
        else if lowercased.contains("remove") || lowercased.contains("subtract") {
            if lowercased.contains("100") {
                edited.calories = max(0, edited.calories - 100)
                edited.llmAssumptions = "Removed 100 calories as requested"
            }
        }
        
        // Handle additions
        if lowercased.contains("with cheese") {
            edited.calories += 100
            edited.protein += 6
            edited.fat += 8
            edited.name = "\(original.name) with cheese"
            edited.llmAssumptions = "Added cheese (+100 cal, +6g protein, +8g fat)"
        }
        else if lowercased.contains("with extra") {
            edited.calories = Int(Double(edited.calories) * 1.2)
            edited.name = "\(original.name) (extra)"
            edited.llmAssumptions = "Added extra portions (+20%)"
        }
        
        // Handle removals
        if lowercased.contains("without") || lowercased.contains("no sauce") || lowercased.contains("no mayo") {
            edited.calories = Int(Double(edited.calories) * 0.9)
            edited.fat = edited.fat * 0.8
            edited.llmAssumptions = "Removed sauce/condiments (-10% calories, -20% fat)"
        }
        
        // Preserve the original ID
        edited.id = original.id
        
        LogManager.shared.log("Mock edit completed: \(original.name) → \(edited.name)", category: .api)
        
        return edited
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
