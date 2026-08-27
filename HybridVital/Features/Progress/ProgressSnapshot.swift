import SwiftUI

enum ProgressTimeRange: String, CaseIterable, Identifiable {
    case week
    case month

    var id: String { rawValue }

    var title: String {
        switch self {
        case .week: "Week"
        case .month: "Month"
        }
    }

    var dayCount: Int {
        switch self {
        case .week: 7
        case .month: 28
        }
    }
}

struct ProgressSnapshot {
    var macroDays: [DemoCatalog.MacroDay]
    var macrosAreSample: Bool
    var trainingDays: [DemoCatalog.TrainingDay]
    var trainingIsSample: Bool
    var zone2CompletedMinutes: Int
    var zone2TargetMinutes: Int
    var proteinTarget: Int
    var fiberTarget: Int
    var calorieTarget: Int
    var sessions: [TrainingSession]
    var todayTotals: NutritionInfo
    var todayIsSample: Bool

    var averageProtein: Double { average(\.proteinG) }
    var averageFiber: Double { average(\.fiberG) }
    var averageCalories: Double { average(\.calories) }
    var averageEnergy: Double { average { Double($0.energy) } }
    var averageConstipation: Double { average { Double($0.constipation) } }

    var proteinAdherence: Double {
        guard proteinTarget > 0 else { return 0 }
        return averageProtein / Double(proteinTarget)
    }

    var fiberAdherence: Double {
        guard fiberTarget > 0 else { return 0 }
        return averageFiber / Double(fiberTarget)
    }

    var calorieAdherence: Double {
        guard calorieTarget > 0 else { return 0 }
        return averageCalories / Double(calorieTarget)
    }

    var zone2Progress: Double {
        guard zone2TargetMinutes > 0 else { return 0 }
        return Double(zone2CompletedMinutes) / Double(zone2TargetMinutes)
    }

    var trainedDayCount: Int {
        trainingDays.filter { $0.zone2Minutes > 0 }.count
    }

    var averageZone2Percent: Int? {
        let active = trainingDays.filter { $0.zone2Minutes > 0 }
        guard !active.isEmpty else { return nil }
        let total = active.reduce(0) { $0 + $1.z2Percent }
        return Int((Double(total) / Double(active.count)).rounded())
    }

    static func load(services: AppServices, range: ProgressTimeRange) -> ProgressSnapshot {
        let profile = services.training.getOrCreateProfile()
        let macros = loadMacros(food: services.food, range: range)
        let training = loadTraining(training: services.training, range: range)
        let today = services.food.getTodayNutritionTotals()
        let todayIsSample = today.calories == 0 && today.proteinG == 0 && today.fiberG == 0

        let weekTraining = loadTraining(training: services.training, range: .week)
        let zone2Completed: Int
        if weekTraining.isSample {
            zone2Completed = DemoCatalog.weeklyZone2CompletedMinutes
        } else {
            zone2Completed = weekTraining.days.reduce(0) { $0 + $1.zone2Minutes }
        }

        let protein = profile.targetMacros.proteinG
        let carbs = profile.targetMacros.carbsG
        let fat = profile.targetMacros.fatG
        let calories = (protein * 4) + (carbs * 4) + (fat * 9)

        return ProgressSnapshot(
            macroDays: macros.days,
            macrosAreSample: macros.isSample,
            trainingDays: training.days,
            trainingIsSample: training.isSample,
            zone2CompletedMinutes: zone2Completed,
            zone2TargetMinutes: profile.weeklyZone2TargetMinutes,
            proteinTarget: protein,
            fiberTarget: 35,
            calorieTarget: max(calories, 1),
            sessions: services.training.recentSessions(),
            todayTotals: todayIsSample ? sampleTodayTotals(from: macros.days) : today,
            todayIsSample: todayIsSample
        )
    }

    private static func loadMacros(
        food: FoodLoggingRepository,
        range: ProgressTimeRange
    ) -> (days: [DemoCatalog.MacroDay], isSample: Bool) {
        let logs = food.logs(inLastDays: range.dayCount)
        let fallback = range == .week ? DemoCatalog.weekMacros : DemoCatalog.monthMacros
        guard !logs.isEmpty else {
            return (fallback, true)
        }

        let days = logs
            .map(macroDay(from:))
            .sorted { $0.date < $1.date }
        return (days, false)
    }

    private static func loadTraining(
        training: TrainingRepository,
        range: ProgressTimeRange
    ) -> (days: [DemoCatalog.TrainingDay], isSample: Bool) {
        let sessions = training.recentSessions(limit: 80)
        let calendar = Calendar.current
        let start = calendar.date(
            byAdding: .day,
            value: -(range.dayCount - 1),
            to: calendar.startOfDay(for: .now)
        ) ?? .now
        let inRange = sessions.filter { $0.startedAt >= start }

        guard !sessions.isEmpty, !inRange.isEmpty else {
            return (sampleTraining(dayCount: range.dayCount), true)
        }

        let grouped = Dictionary(grouping: inRange) { calendar.startOfDay(for: $0.startedAt) }
        let days: [DemoCatalog.TrainingDay] = (0..<range.dayCount).reversed().compactMap { offset in
            guard let date = calendar.date(
                byAdding: .day,
                value: -offset,
                to: calendar.startOfDay(for: .now)
            ) else {
                return nil
            }
            let daySessions = grouped[date] ?? []
            let zone2Seconds = daySessions.reduce(0.0) { $0 + $1.zoneDurations.zone2Seconds }
            let totalSeconds = daySessions.reduce(0.0) { $0 + $1.zoneDurations.totalSeconds }
            let avgHR = daySessions.compactMap(\.avgHR)
            let avgHRValue = avgHR.isEmpty ? 0 : avgHR.reduce(0, +) / Double(avgHR.count)
            return DemoCatalog.TrainingDay(
                date: date,
                zone2Minutes: Int((zone2Seconds / 60).rounded()),
                avgHR: Int(avgHRValue.rounded()),
                z2Percent: totalSeconds > 0 ? Int((zone2Seconds / totalSeconds * 100).rounded()) : 0
            )
        }
        return (days, false)
    }

    private static func macroDay(from log: DailyLog) -> DemoCatalog.MacroDay {
        var totals = NutritionInfo()
        for entry in log.foodEntries {
            totals.calories += entry.nutrition.calories
            totals.proteinG += entry.nutrition.proteinG
            totals.carbsG += entry.nutrition.carbsG
            totals.fatG += entry.nutrition.fatG
            totals.fiberG += entry.nutrition.fiberG
        }
        return DemoCatalog.MacroDay(
            date: log.date,
            calories: totals.calories,
            proteinG: totals.proteinG,
            carbsG: totals.carbsG,
            fatG: totals.fatG,
            fiberG: totals.fiberG,
            energy: log.energyLevel ?? 0,
            constipation: log.constipationSeverity ?? 0
        )
    }

    private static func sampleTraining(dayCount: Int) -> [DemoCatalog.TrainingDay] {
        if dayCount <= 7 {
            return DemoCatalog.weekTraining
        }
        let template = [0, 42, 0, 55, 0, 38, 48]
        let calendar = Calendar.current
        return (0..<dayCount).reversed().compactMap { offset in
            guard let date = calendar.date(
                byAdding: .day,
                value: -offset,
                to: calendar.startOfDay(for: .now)
            ) else {
                return nil
            }
            let value = template[offset % template.count]
            return DemoCatalog.TrainingDay(
                date: date,
                zone2Minutes: value,
                avgHR: value == 0 ? 0 : 138 + (offset % 7),
                z2Percent: value == 0 ? 0 : 72 + (offset % 7)
            )
        }
    }

    private static func sampleTodayTotals(from days: [DemoCatalog.MacroDay]) -> NutritionInfo {
        guard let latest = days.max(by: { $0.date < $1.date }) else {
            return NutritionInfo()
        }
        return NutritionInfo(
            calories: latest.calories,
            proteinG: latest.proteinG,
            carbsG: latest.carbsG,
            fatG: latest.fatG,
            fiberG: latest.fiberG
        )
    }

    private func average(_ keyPath: KeyPath<DemoCatalog.MacroDay, Double>) -> Double {
        guard !macroDays.isEmpty else { return 0 }
        return macroDays.map { $0[keyPath: keyPath] }.reduce(0, +) / Double(macroDays.count)
    }

    private func average(_ value: (DemoCatalog.MacroDay) -> Double) -> Double {
        guard !macroDays.isEmpty else { return 0 }
        return macroDays.map(value).reduce(0, +) / Double(macroDays.count)
    }
}

struct HVSampleCaption: View {
    var body: some View {
        Text("Sample data")
            .font(.caption2)
            .foregroundStyle(.tertiary)
    }
}
