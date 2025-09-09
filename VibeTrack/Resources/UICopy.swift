import Foundation

// MARK: - UI Copy with ✨ vibes ✨
// Tone: Tech bro meets Gen Z - confident, casual, fun
struct UICopy {
    
    // MARK: - Main Recording View
    struct Recording {
        static let mainPrompt = "what's on the menu?"
        static let todaysSummary = "%d cals crushed today"
        static let micPromptListening = "i'm all ears..."
        static let micPromptReady = "tap to spill the tea"
        static let manualEntryHint = "or just type it out"
        static let recentEntriesHeader = "recent fuel ⚡"
        
        // Processing states
        static let processing = "crunching the numbers..."
        static let errorGeneric = "didn't catch that, wanna run it back?"
        static let errorRetry = "one more time for the people in the back?"
        static let successLogged = "logged it! %d cals, %dg protein locked in 💪"
        
        // Voice states
        static let listeningActive = "listening..."
        static let transcribing = "got it, processing..."
    }
    
    // MARK: - Manual Entry
    struct ManualEntry {
        static let title = "type it out"
        static let placeholder = "had a burger and fries..."
        static let hint = "try: \"2 eggs and toast\" or \"iced latte with oat milk\""
        static let submitButton = "log this meal"
        static let submitButtonProcessing = "working on it..."
        static let cancelButton = "nevermind"
        static let doneButton = "done"
    }
    
    // MARK: - Entries List
    struct EntriesList {
        static let title = "food log"
        static let emptyStateTitle = "no meals tracked yet"
        static let emptyStateMessage = "hit the mic and tell me what you're eating!"
        static let deleteConfirmation = "remove this?"
        static let todayHeader = "today"
        static let yesterdayHeader = "yesterday"
        
        // Entry details
        static let caloriesFormat = "%d cal"
        static let proteinLabel = "%dg"
        static let carbsLabel = "%dg"
        static let fatLabel = "%dg"
        static let assumptionsPrefix = "ai notes: "
    }
    
    // MARK: - Edit Entry
    struct EditEntry {
        static let title = "tweak the deets"
        static let sectionFood = "the basics"
        static let sectionMacros = "macro breakdown"
        static let sectionTime = "when tho"
        static let sectionAssumptions = "ai's best guess"
        
        static let saveButton = "update"
        static let cancelButton = "nah"
        
        // Field labels
        static let nameField = "what'd you eat"
        static let caloriesField = "calories"
        static let proteinField = "protein"
        static let carbsField = "carbs"
        static let fatField = "fat"
        static let timestampField = "logged at"
    }
    
    // MARK: - Charts View
    struct Charts {
        static let title = "the stats 📊"
        static let timeRangeWeek = "week"
        static let timeRangeMonth = "month"
        static let timeRangeQuarter = "3 months"
        
        static let todaysSummaryHeader = "today's damage"
        static let dailyCaloriesHeader = "daily intake"
        static let macroDistributionHeader = "macro split (last 7 days)"
        
        static let caloriesLabel = "calories"
        static let proteinLabel = "protein"
        static let carbsLabel = "carbs"
        static let fatLabel = "fat"
        
        static let noDataMessage = "no data for this period"
        static let macroFormat = "%@: %dg"
    }
    
    // MARK: - Tab Bar
    struct TabBar {
        static let trackTab = "track"
        static let entriesTab = "history"
        static let trendsTab = "trends"
    }
    
    // MARK: - Debug View
    struct Debug {
        static let title = "debug mode"
        static let aiInteractionsTab = "ai convos"
        static let systemLogsTab = "system logs"
        
        static let exportButton = "export logs"
        static let clearButton = "clear all"
        
        static let noInteractionsTitle = "no ai interactions yet"
        static let noInteractionsMessage = "start tracking to see the magic"
        
        static let noLogsTitle = "no logs yet"
        static let searchPlaceholder = "search logs..."
        
        static let inputLabel = "you said:"
        static let outputLabel = "ai replied:"
    }
    
    // MARK: - Errors & Warnings
    struct Errors {
        static let noAPIKey = "missing api key - check your config!"
        static let networkError = "connection issues, try again?"
        static let parsingError = "couldn't understand that format"
        static let speechPermissionDenied = "need mic access to work the magic"
        static let lowConfidence = "not super confident about that one..."
    }
    
    // MARK: - Onboarding (if needed)
    struct Onboarding {
        static let welcome = "welcome to vibetrack"
        static let tagline = "the chillest way to track your food"
        static let micPermissionTitle = "we need your mic"
        static let micPermissionMessage = "so you can just tell us what you ate"
        static let getStartedButton = "let's go 🚀"
    }
    
    // MARK: - Motivational
    struct Motivation {
        static let streakMessage = "%d day streak! keep crushing it"
        static let goalReached = "daily goal hit! 🎯"
        static let almostThere = "almost at your goal!"
        static let greatChoice = "solid choice!"
        static let balancedMeal = "perfectly balanced, as all things should be"
    }
    
    // MARK: - AI Assumptions Templates
    struct AIAssumptions {
        static let standardPortion = "assuming standard portion size"
        static let restaurantEstimate = "estimated based on typical restaurant serving"
        static let homemadeGuess = "assuming homemade preparation"
        static let brandEstimate = "estimated based on %@ nutrition info"
        static let genericEstimate = "using generic nutrition values"
    }
}
