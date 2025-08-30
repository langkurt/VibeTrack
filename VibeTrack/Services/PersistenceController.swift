import CoreData

class PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init() {
        container = NSPersistentContainer(name: "VibeTrack")
        
        container.loadPersistentStores { _, error in
            if let error = error {
                LogManager.shared.logError(error, category: .data)
                fatalError("Core Data failed to load: \(error)")
            } else {
                LogManager.shared.log("Core Data loaded successfully", category: .data)
            }
        }
    }
    
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
                LogManager.shared.log("Core Data context saved", category: .data)
            } catch {
                LogManager.shared.logError(error, category: .data)
            }
        }
    }
}
