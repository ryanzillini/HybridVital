import SwiftUI

struct PrivacySettingsView: View {
    @State private var showingExportInfo = false
    @State private var showingDeleteConfirm = false
    @State private var showingDeleteAck = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HVTheme.stackSpacing) {
                HVCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Local-first")
                            .font(.headline)
                        Text("Food logs, training sessions, and your profile live in SwiftData on this iPhone. HybridVital is built to work without an account. Nothing here is uploaded unless a future sync is explicitly turned on.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                HVCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("HealthKit")
                            .font(.headline)
                        Text("Apple Health is the biometric source for heart rate and workouts. HybridVital reads what you authorize and can write a workout back. Health data stays under Apple’s Health permissions — we don’t sell it.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                HVCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Future cloud mirror")
                            .font(.headline)
                        Text("A later build may offer an optional Supabase mirror so Coach memory can sync across devices. That path is designed with a HIPAA-ready posture (encryption, least privilege, auditability). HybridVital is not HIPAA certified today, and this app is not medical care.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                HVPrimaryButton(title: "Export my data", systemImage: "square.and.arrow.up") {
                    showingExportInfo = true
                }

                Button(role: .destructive) {
                    showingDeleteConfirm = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "trash")
                        Text("Delete local data")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(HVTheme.danger.opacity(0.18))
                    .foregroundStyle(HVTheme.danger)
                    .clipShape(RoundedRectangle(cornerRadius: HVTheme.radiusM, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Delete local data")

                HVDisclaimer(
                    text: "HybridVital is not medical advice and is not a covered entity under HIPAA. Talk with your clinician before changing diet, training, or medication."
                )
            }
            .padding(HVTheme.pagePadding)
        }
        .navigationTitle("Privacy & data")
        .hvInlineNav()
        .hvScreen()
        .alert("Export", isPresented: $showingExportInfo) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Full export lands in a later build. Session JSON/CSV already exists on individual Zone 2 workouts. Your food and profile stay on this device.")
        }
        .alert("Delete local data?", isPresented: $showingDeleteConfirm) {
            Button("Delete", role: .destructive) {
                showingDeleteAck = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This confirmation is wired for the portfolio build. It does not wipe SwiftData or Apple Health. A future version will offer a real on-device reset.")
        }
        .alert("Request noted", isPresented: $showingDeleteAck) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("No local data was removed.")
        }
    }
}
