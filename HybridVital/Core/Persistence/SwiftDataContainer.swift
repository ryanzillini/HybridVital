import SwiftData
import Foundation

actor SwiftDataContainer {
    static let shared = SwiftDataContainer()
    
    private var container: ModelContainer?
    private let lock = NSLock()
    
    nonisolated private init() {}
    
    func initialize() throws {
        lock.lock()
        defer { lock.unlock() }
        
        guard container == nil else { return }
        
        let schema = Schema([
            UserProfile.self,
            DailyLog.self,
            FoodEntry.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        
        container = try ModelContainer(
            for: schema,
            configurations: [modelConfiguration]
        )
    }
    
    var mainContext: ModelContext {
        guard let container else {
            fatalError("SwiftDataContainer not initialized. Call initialize() first.")
        }
        return ModelContext(container)
    }
    
    func backgroundContext() -> ModelContext {
        guard let container else {
            fatalError("SwiftDataContainer not initialized. Call initialize() first.")
        }
        return ModelContext(container)
    }
}
