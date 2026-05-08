// Features/FoodLogging/Repository/FoodLoggingRepository.swift
import SwiftData
import Foundation
import Observation

@Observable
final class FoodLoggingRepository {
    
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    // MARK: - Today Log
    
    func fetchTodayLog() -> DailyLog? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        let predicate = #Predicate<DailyLog> { log in
            log.date >= today && log.date < tomorrow
        }
        
        let descriptor = FetchDescriptor<DailyLog>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            let logs = try context.fetch(descriptor)
            return logs.first
        } catch {
            print("[FoodLogging] Error fetching today's log: \(error)")
            return nil
        }
    }
    
    func getOrCreateTodayLog() -> DailyLog {
        if let existing = fetchTodayLog() {
            return existing
        }
        
        let newLog = DailyLog(date: Calendar.current.startOfDay(for: .now))
        context.insert(newLog)
        
        do {
            try context.save()
            print("[FoodLogging] Created new DailyLog for today")
        } catch {
            print("[FoodLogging] Error creating today's log: \(error)")
        }
        
        return newLog
    }
    
    // MARK: - CRUD
    
    func save(entry: FoodEntry) {
        let today = getOrCreateTodayLog()
        entry.dailyLog = today
        today.foodEntries.append(entry)
        
        context.insert(entry)
        
        do {
            try context.save()
            print("[FoodLogging] Entry saved: \(entry.foodName)")
        } catch {
            print("[FoodLogging] Error saving entry: \(error)")
        }
    }
    
    func delete(entry: FoodEntry) {
        context.delete(entry)
        
        do {
            try context.save()
            print("[FoodLogging] Entry deleted: \(entry.foodName)")
        } catch {
            print("[FoodLogging] Error deleting entry: \(error)")
        }
    }
    
    func getTodayEntries() -> [FoodEntry] {
        if let log = fetchTodayLog() {
            return log.foodEntries.sorted { $0.timestamp > $1.timestamp }
        }
        return []
    }
    
    func getTodayNutritionTotals() -> NutritionInfo {
        let entries = getTodayEntries()
        var totals = NutritionInfo()
        
        for entry in entries {
            totals.calories += entry.nutrition.calories
            totals.proteinG += entry.nutrition.proteinG
            totals.carbsG += entry.nutrition.carbsG
            totals.fatG += entry.nutrition.fatG
            totals.fiberG += entry.nutrition.fiberG
            totals.sugarG += entry.nutrition.sugarG
            totals.cholesterolMg += entry.nutrition.cholesterolMg
            totals.sodiumMg += entry.nutrition.sodiumMg
        }
        
        return totals
    }
}