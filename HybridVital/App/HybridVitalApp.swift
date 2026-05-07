//
//  File.swift
//  HybridVital
//
//  Created by Ryan Zillini on 5/6/26.
//

import SwiftUI
import SwiftData

@main
struct HybridVitalApp: App {
    let container: ModelContainer
    
    init() {
        do {
            container = try ModelContainer(for: UserProfile.self, DailyLog.self, FoodEntry.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(container)
        }
    }
}
