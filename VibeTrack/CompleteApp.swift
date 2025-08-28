//
//  CompleteApp.swift
//  VibeTrack
//
//  Created by Kurt Lang on 9/7/25.
//

// VibeTrack iOS App - Complete Implementation

import SwiftUI
import Speech
import AVFoundation
import Charts
import Foundation

// MARK: - Main App
@main
struct VibeTrackApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var speechManager = SpeechManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(speechManager)
        }
    }
}

// MARK: - Models
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
}

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

// MARK: - Core Data
import CoreData

class PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init() {
        container = NSPersistentContainer(name: "VibeTrack")
        
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data failed to load: \(error)")
            }
        }
    }
    
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Failed to save context: \(error)")
            }
        }
    }
}

// MARK: - Speech Manager
class SpeechManager: NSObject, ObservableObject, SFSpeechRecognizerDelegate {
    @Published var isRecording = false
    @Published var transcribedText = ""
    @Published var errorMessage: String?
    
    private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    override init() {
        super.init()
        speechRecognizer?.delegate = self
        requestAuthorization()
    }
    
    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    print("Speech recognition authorized")
                case .denied, .restricted, .notDetermined:
                    self.errorMessage = "Speech recognition not available"
                @unknown default:
                    self.errorMessage = "Unknown authorization status"
                }
            }
        }
    }
    
    func startRecording() {
        if audioEngine.isRunning {
            stopRecording()
            return
        }
        
        do {
            try startRecordingSession()
        } catch {
            errorMessage = "Recording failed: \(error.localizedDescription)"
        }
    }
    
    private func startRecordingSession() throws {
        recognitionTask?.cancel()
        recognitionTask = nil
        
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode
        guard let recognitionRequest = recognitionRequest else {
            throw NSError(domain: "SpeechManager", code: 1, userInfo: nil)
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                self.transcribedText = result.bestTranscription.formattedString
            }
            
            if error != nil || result?.isFinal == true {
                self.stopRecording()
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        isRecording = true
        transcribedText = "Listening..."
    }
    
    func stopRecording() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        audioEngine.inputNode.removeTap(onBus: 0)
        
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false
    }
}

// MARK: - API Service
class NutritionAPIService {
    static let shared = NutritionAPIService()
    
    func parseFood(from text: String, retryCount: Int = 0) async throws -> LLMResponse {
        // Using Claude API - replace with your preferred LLM endpoint
        let url = URL(string: "https://api.anthropic.com/v1/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("API-KEY-HERE", forHTTPHeaderField: "x-api-key") // Replace with actual API key
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
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        // Parse the Claude response
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let content = (json["content"] as? [[String: Any]])?.first,
           let responseText = content["text"] as? String,
           let responseData = responseText.data(using: .utf8) {
            
            let llmResponse = try JSONDecoder().decode(LLMResponse.self, from: responseData)
            return llmResponse
        }
        
        // Fallback mock response for testing without API
        return mockParseFoodResponse(text: text)
    }
    
    private func mockParseFoodResponse(text: String) -> LLMResponse {
        // Mock response for testing without API
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
        
        return LLMResponse(
            foods: foods,
            confidence: 0.8,
            notes: "Parsed \(foods.count) food item(s)"
        )
    }
}

// MARK: - Data Store
class FoodDataStore: ObservableObject {
    @Published var entries: [FoodEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastLLMResponse: LLMResponse?
    @Published var retryCount = 0
    
    private let userDefaults = UserDefaults.standard
    private let entriesKey = "vibetrack_entries"
    
    init() {
        loadEntries()
    }
    
    func processVoiceInput(_ text: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let response = try await NutritionAPIService.shared.parseFood(from: text, retryCount: retryCount)
            
            await MainActor.run {
                self.lastLLMResponse = response
                
                if response.confidence < 0.5 && retryCount < 2 {
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
                    }
                    
                    self.saveEntries()
                    self.retryCount = 0
                    
                    let totalCalories = response.foods.reduce(0) { $0 + $1.calories }
                    let totalProtein = response.foods.reduce(0.0) { $0 + $1.protein }
                    self.errorMessage = "Got it! Logged \(totalCalories) calories, \(Int(totalProtein))g protein. Tap to edit if needed."
                }
                
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Hmm, I didn't catch that. Mind trying again?"
                self.isLoading = false
            }
        }
    }
    
    func updateEntry(_ entry: FoodEntry) {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[index] = entry
            saveEntries()
        }
    }
    
    func deleteEntry(_ entry: FoodEntry) {
        entries.removeAll { $0.id == entry.id }
        saveEntries()
    }
    
    private func saveEntries() {
        if let encoded = try? JSONEncoder().encode(entries) {
            userDefaults.set(encoded, forKey: entriesKey)
        }
    }
    
    private func loadEntries() {
        if let data = userDefaults.data(forKey: entriesKey),
           let decoded = try? JSONDecoder().decode([FoodEntry].self, from: data) {
            entries = decoded
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

// MARK: - Views
struct ContentView: View {
    @StateObject private var dataStore = FoodDataStore()
    @EnvironmentObject var speechManager: SpeechManager
    @State private var selectedTab = 0
    @State private var showingManualEntry = false
    @State private var manualInput = ""
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Main Recording View
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("What did you eat?")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    let totals = dataStore.todaysTotals()
                    Text("\(totals.calories) calories today")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Voice Input Section
                VStack(spacing: 20) {
                    // Microphone Button
                    Button(action: {
                        if speechManager.isRecording {
                            speechManager.stopRecording()
                            Task {
                                await dataStore.processVoiceInput(speechManager.transcribedText)
                            }
                        } else {
                            speechManager.startRecording()
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(speechManager.isRecording ? Color.red : Color.blue)
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: speechManager.isRecording ? "stop.fill" : "mic.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                        }
                    }
                    .scaleEffect(speechManager.isRecording ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: speechManager.isRecording)
                    
                    // Transcribed Text
                    if !speechManager.transcribedText.isEmpty && speechManager.transcribedText != "Listening..." {
                        Text(speechManager.transcribedText)
                            .font(.body)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }
                    
                    // Status Messages
                    if dataStore.isLoading {
                        ProgressView()
                            .padding()
                    }
                    
                    if let error = dataStore.errorMessage {
                        VStack(spacing: 12) {
                            Text(error)
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .foregroundColor(error.contains("Got it!") ? .green : .orange)
                            
                            if dataStore.retryCount > 0 && dataStore.retryCount < 2 {
                                Button("Try explaining again") {
                                    speechManager.startRecording()
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Manual Entry Option
                    Button(action: { showingManualEntry = true }) {
                        Text("Or tap to type...")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
                
                // Recent Entries Preview
                if !dataStore.entries.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recent entries")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(dataStore.entries.prefix(5)) { entry in
                                    VStack(alignment: .leading) {
                                        Text(entry.name)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                        Text("\(entry.calories) cal")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(8)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom)
                }
            }
            .tabItem {
                Label("Track", systemImage: "mic.fill")
            }
            .tag(0)
            
            // Entries List View
            EntriesListView(dataStore: dataStore)
                .tabItem {
                    Label("Entries", systemImage: "list.bullet")
                }
                .tag(1)
            
            // Charts View
            ChartsView(dataStore: dataStore)
                .tabItem {
                    Label("Trends", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(2)
        }
        .sheet(isPresented: $showingManualEntry) {
            ManualEntryView(dataStore: dataStore, isPresented: $showingManualEntry)
        }
    }
}

struct EntriesListView: View {
    @ObservedObject var dataStore: FoodDataStore
    @State private var editingEntry: FoodEntry?
    
    var groupedEntries: [(String, [FoodEntry])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: dataStore.entries.sorted { $0.timestamp > $1.timestamp }) { entry in
            calendar.startOfDay(for: entry.timestamp)
        }
        
        return grouped.sorted { $0.key > $1.key }.map { date, entries in
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.doesRelativeDateFormatting = true
            return (formatter.string(from: date), entries)
        }
    }
    
    var body: some View {
        NavigationView {
            if dataStore.entries.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "fork.knife.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("No meals logged today")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Tap the mic and tell me what you've eaten!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            } else {
                List {
                    ForEach(groupedEntries, id: \.0) { date, entries in
                        Section(header: Text(date)) {
                            ForEach(entries) { entry in
                                EntryRowView(entry: entry)
                                    .onTapGesture {
                                        editingEntry = entry
                                    }
                            }
                            .onDelete { indexSet in
                                for index in indexSet {
                                    dataStore.deleteEntry(entries[index])
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Food Log")
                .sheet(item: $editingEntry) { entry in
                    EditEntryView(entry: entry, dataStore: dataStore)
                }
            }
        }
    }
}

struct EntryRowView: View {
    let entry: FoodEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(entry.name)
                    .font(.headline)
                Spacer()
                Text("\(entry.calories) cal")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            
            HStack(spacing: 12) {
                Label("\(Int(entry.protein))g", systemImage: "p.square.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
                
                Label("\(Int(entry.carbs))g", systemImage: "c.square.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Label("\(Int(entry.fat))g", systemImage: "f.square.fill")
                    .font(.caption)
                    .foregroundColor(.purple)
                
                Spacer()
                
                Text(entry.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let assumptions = entry.llmAssumptions {
                Text(assumptions)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding(.vertical, 4)
    }
}

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
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        dataStore.updateEntry(entry)
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ManualEntryView: View {
    let dataStore: FoodDataStore
    @Binding var isPresented: Bool
    @State private var textInput = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Type what you ate")
                    .font(.headline)
                    .padding(.top)
                
                TextEditor(text: $textInput)
                    .padding(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .padding()
                
                if textInput.isEmpty {
                    Text("Example: \"Had eggs for breakfast, salad for lunch\"")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    Task {
                        await dataStore.processVoiceInput(textInput)
                        isPresented = false
                    }
                }) {
                    Text("Log Food")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding()
                .disabled(textInput.isEmpty)
            }
            .navigationTitle("Manual Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { isPresented = false }
                }
            }
        }
    }
}

struct ChartsView: View {
    @ObservedObject var dataStore: FoodDataStore
    @State private var selectedTimeRange = 0
    
    var timeRanges = ["Week", "Month", "3 Months"]
    
    var daysToShow: Int {
        switch selectedTimeRange {
        case 0: return 7
        case 1: return 30
        case 2: return 90
        default: return 7
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Time Range Picker
                    Picker("Time Range", selection: $selectedTimeRange) {
                        ForEach(0..<timeRanges.count, id: \.self) { index in
                            Text(timeRanges[index]).tag(index)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    
                    // Today's Summary
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Today's Summary")
                            .font(.headline)
                        
                        let totals = dataStore.todaysTotals()
                        
                        HStack(spacing: 20) {
                            VStack {
                                Text("\(totals.calories)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("Calories")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack {
                                Text("\(Int(totals.protein))g")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.orange)
                                Text("Protein")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack {
                                Text("\(Int(totals.carbs))g")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                                Text("Carbs")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack {
                                Text("\(Int(totals.fat))g")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.purple)
                                Text("Fat")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // Calories Chart
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Daily Calories")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        Chart(dataStore.dailyCalories(for: daysToShow), id: \.date) { item in
                            BarMark(
                                x: .value("Date", item.date, unit: .day),
                                y: .value("Calories", item.calories)
                            )
                            .foregroundStyle(Color.blue)
                        }
                        .frame(height: 200)
                        .padding(.horizontal)
                    }
                    
                    // Macro Distribution Chart
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Macro Distribution (Last 7 Days)")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        let last7Days = dataStore.entries.filter {
                            $0.timestamp > Calendar.current.date(byAdding: .day, value: -7, to: Date())!
                        }
                        
                        let totalProtein = last7Days.reduce(0.0) { $0 + $1.protein }
                        let totalCarbs = last7Days.reduce(0.0) { $0 + $1.carbs }
                        let totalFat = last7Days.reduce(0.0) { $0 + $1.fat }
                        
                        let macroData = [
                            ("Protein", totalProtein, Color.orange),
                            ("Carbs", totalCarbs, Color.blue),
                            ("Fat", totalFat, Color.purple)
                        ]
                        
                        Chart(macroData, id: \.0) { item in
                            SectorMark(
                                angle: .value("Value", item.1),
                                innerRadius: .ratio(0.5)
                            )
                            .foregroundStyle(item.2)
                        }
                        .frame(height: 200)
                        .padding()
                        
                        HStack(spacing: 20) {
                            ForEach(macroData, id: \.0) { item in
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(item.2)
                                        .frame(width: 12, height: 12)
                                    Text("\(item.0): \(Int(item.1))g")
                                        .font(.caption)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 50)
                }
            }
            .navigationTitle("Trends")
        }
    }
}

// MARK: - Core Data Model
// Create a new Core Data model file in Xcode:
// 1. File > New > File > Core Data > Data Model
// 2. Name it "VibeTrack"
// 3. Add Entity: "FoodEntryEntity" with attributes:
//    - id: UUID
//    - name: String
//    - calories: Integer 32
//    - protein: Double
//    - carbs: Double
//    - fat: Double
//    - timestamp: Date
//    - notes: String (Optional)
//    - llmAssumptions: String (Optional)
