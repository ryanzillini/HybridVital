import SwiftData
import SwiftUI

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var services: AppServices?

    var body: some View {
        Group {
            if let services {
                if hasCompletedOnboarding {
                    mainTabs(services)
                } else {
                    OnboardingFlowView(services: services) {
                        hasCompletedOnboarding = true
                    }
                }
            } else {
                ZStack {
                    HVScreenBackground()
                    ProgressView()
                        .tint(HVTheme.accent)
                }
            }
        }
        .preferredColorScheme(.dark)
        .tint(HVTheme.accent)
        .task {
            if services == nil {
                services = AppServices(
                    food: FoodLoggingRepository(context: modelContext),
                    training: TrainingRepository(context: modelContext)
                )
            }
        }
    }

    private func mainTabs(_ services: AppServices) -> some View {
        TabView {
            DashboardView(services: services)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            TrainingHubView(repository: services.training)
                .tabItem {
                    Label("Train", systemImage: "heart.fill")
                }

            FoodLogHubView(repository: services.food)
                .tabItem {
                    Label("Food", systemImage: "fork.knife")
                }

            CoachHomeView(services: services)
                .tabItem {
                    Label("Coach", systemImage: "sparkles")
                }

            ProgressHubView(services: services)
                .tabItem {
                    Label("Progress", systemImage: "chart.bar.fill")
                }
        }
        .toolbarBackground(HVTheme.background, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}

#Preview {
    let container = try! ModelContainer(
        for: UserProfile.self,
        DailyLog.self,
        FoodEntry.self,
        TrainingSession.self,
        WorkoutInterval.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    RootView()
        .modelContainer(container)
        .preferredColorScheme(.dark)
}
