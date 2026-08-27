import SwiftUI

struct NotificationsSettingsView: View {
    let services: AppServices
    @State private var enabled: Bool
    @State private var mealReminders = true
    @State private var zone2Nudge = true
    @State private var coachBriefing = true

    init(services: AppServices) {
        self.services = services
        _enabled = State(initialValue: services.training.getOrCreateProfile().notificationPreferences.enabled)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HVTheme.stackSpacing) {
                HVCard {
                    Toggle("Notifications", isOn: $enabled)
                        .tint(HVTheme.accent)
                        .onChange(of: enabled) { _, newValue in
                            persistEnabled(newValue)
                        }
                    Text("Master switch stored on this device with your profile.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 10) {
                    HVSectionHeader(title: "Preview cues")
                    mockToggle("Meal reminders", subtitle: "Log protein before the day gets away", isOn: $mealReminders)
                    mockToggle("Zone 2 nudge", subtitle: "A quiet prompt on rest-heavy weeks", isOn: $zone2Nudge)
                    mockToggle("Coach briefing", subtitle: "Morning context from macros and last session", isOn: $coachBriefing)
                    Text("These extra toggles are local previews for the portfolio build. They are not scheduled on the system yet.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                HVDisclaimer()
            }
            .padding(HVTheme.pagePadding)
        }
        .navigationTitle("Notifications")
        .hvInlineNav()
        .hvScreen()
        .onDisappear {
            persistEnabled(enabled)
        }
    }

    private func mockToggle(_ title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body.weight(.semibold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .tint(HVTheme.accent)
        .padding(14)
        .background(HVTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: HVTheme.radiusM, style: .continuous))
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.45)
    }

    private func persistEnabled(_ value: Bool) {
        services.training.saveProfile { profile in
            profile.notificationPreferences.enabled = value
        }
    }
}
