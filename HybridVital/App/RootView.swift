//
//  RootView.swift
//  HybridVital
//
//  Created by Ryan Zillini on 5/6/26.
//

import SwiftUI
import SwiftData

struct RootView: View {
    @State private var repository: FoodLoggingRepository?
    
    var body: some View {
        TabView {
            DashboardView(repository: repository)
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
            
            Text("Log")
                .tabItem {
                    Label("Log", systemImage: "plus.circle.fill")
                }
            
            Text("AI Coach")
                .tabItem {
                    Label("Coach", systemImage: "sparkles")
                }
            
            Text("Progress")
                .tabItem {
                    Label("Progress", systemImage: "chart.bar.fill")
                }
        }
        .tint(.blue)
        .task {
            do {
                try await SwiftDataContainer.shared.initialize()
                repository = FoodLoggingRepository()
            } catch {
                print("[RootView] Failed to initialize SwiftData: \(error)")
            }
        }
    }
}

struct DashboardView: View {
    let repository: FoodLoggingRepository?
    @State private var showingAddFood = false
    @State private var todayEntries: [FoodEntry] = []
    @State private var todayTotals: NutritionInfo = NutritionInfo()
    @State private var userProfile: UserProfile?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                if let repo = repository {
                    ScrollView {
                        VStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("HybridVital")
                                    .font(.title.bold())
                                
                                Text("Welcome back, Ryan")
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            
                            Button {
                                showingAddFood = true
                            } label: {
                                VStack(spacing: 12) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 60))
                                        .foregroundStyle(.blue)
                                    
                                    Text("Log Meal")
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 140)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Today's Summary")
                                    .font(.headline)
                                
                                HStack(spacing: 16) {
                                    SummaryCard(label: "Calories", value: "\(Int(todayTotals.calories))", color: .blue)
                                    SummaryCard(label: "Protein", value: "\(Int(todayTotals.proteinG))g", color: .red)
                                    SummaryCard(label: "Carbs", value: "\(Int(todayTotals.carbsG))g", color: .orange)
                                }
                                
                                HStack(spacing: 16) {
                                    SummaryCard(label: "Fat", value: "\(Int(todayTotals.fatG))g", color: .yellow)
                                    SummaryCard(label: "Fiber", value: "\(Int(todayTotals.fiberG))g", color: .green)
                                }
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                            .padding(.horizontal)
                            
                            if !todayEntries.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Logged Meals")
                                        .font(.headline)
                                    
                                    ForEach(todayEntries, id: \.id) { entry in
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(entry.foodName)
                                                    .font(.body.bold())
                                                Text(entry.mealType.displayName)
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                            
                                            Spacer()
                                            
                                            VStack(alignment: .trailing, spacing: 4) {
                                                Text("\(Int(entry.nutrition.calories)) cal")
                                                    .font(.body.bold())
                                                Text("\(Int(entry.nutrition.proteinG))g protein")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                        .padding()
                                        .background(Color(.tertiarySystemBackground))
                                        .cornerRadius(8)
                                    }
                                }
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                                .padding(.horizontal)
                            }
                            
                            Spacer(minLength: 40)
                        }
                    }
                } else {
                    ProgressView()
                }
            }
            .sheet(isPresented: $showingAddFood) {
                QuickFoodLogView(repository: repo)
            }
            .task {
                await loadTodayData()
            }
            .refreshable {
                await loadTodayData()
            }
        }
    }
    
    @MainActor
    private func loadTodayData() async {
        guard let repo = repository else { return }
        
        todayEntries = await repo.getTodayEntries()
        todayTotals = await repo.getTodayNutritionTotals()
    }
}

struct SummaryCard: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            
            Text(value)
                .font(.body.bold())
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(8)
    }
}

#Preview {
    RootView()
}
