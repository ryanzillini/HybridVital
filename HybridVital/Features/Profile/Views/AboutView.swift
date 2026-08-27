import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HVTheme.stackSpacing) {
                HVCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(HVTheme.accent)
                            .accessibilityHidden(true)
                        Text("HybridVital")
                            .font(HVFont.heroMetric(36))
                        Text("Version 0.2.0 (Portfolio)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("A local-first companion for Zone 2, protein, and cholesterol-aware eating.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    aboutRow(
                        title: "iOS 26 · SwiftUI",
                        subtitle: "Native only. Dark-first, built with SwiftData.",
                        systemImage: "swift",
                        tint: HVTheme.warning
                    )
                    aboutRow(
                        title: "Local-first",
                        subtitle: "Logs live on device. HealthKit is the biometric source.",
                        systemImage: "iphone",
                        tint: HVTheme.calories
                    )
                    aboutRow(
                        title: "AI Coach",
                        subtitle: "The differentiator — automatic context from today’s macros, last Zone 2, and your goals. No extra briefing required.",
                        systemImage: "sparkles",
                        tint: HVTheme.coach
                    )
                    aboutRow(
                        title: "Conservative health stance",
                        subtitle: "Not medical advice. Familial hypocholesterolemia stays flagged. We suggest questions for your clinician, not prescriptions.",
                        systemImage: "stethoscope",
                        tint: HVTheme.protein
                    )
                }

                HVDisclaimer()
            }
            .padding(HVTheme.pagePadding)
        }
        .navigationTitle("About")
        .hvInlineNav()
        .hvScreen()
    }

    private func aboutRow(title: String, subtitle: String, systemImage: String, tint: Color) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(tint)
                .frame(width: 36, height: 36)
                .background(tint.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body.weight(.semibold))
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HVTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: HVTheme.radiusM, style: .continuous))
    }
}
