import SwiftUI

struct FoodLogMethodSheet: View {
    var onSelect: (FoodLogMethod) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Pick the fastest path. You can always edit the log after it lands.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 4)

                    ForEach(FoodLogMethod.allCases) { method in
                        Button {
                            onSelect(method)
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: method.systemImage)
                                    .font(.title2)
                                    .foregroundStyle(HVTheme.accent)
                                    .symbolRenderingMode(.hierarchical)
                                    .frame(width: 44, height: 44)
                                    .background(HVTheme.accent.opacity(0.16))
                                    .clipShape(RoundedRectangle(cornerRadius: HVTheme.radiusS, style: .continuous))

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(method.title)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text(method.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer(minLength: 0)

                                Image(systemName: "chevron.right")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(14)
                            .background(HVTheme.card)
                            .clipShape(RoundedRectangle(cornerRadius: HVTheme.radiusM, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: HVTheme.radiusM, style: .continuous)
                                    .stroke(HVTheme.cardStroke, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(method.title)
                        .accessibilityHint(method.subtitle)
                    }
                }
                .padding(HVTheme.pagePadding)
            }
            .navigationTitle("Log a meal")
            .hvInlineNav()
            .hvScreen()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    FoodLogMethodSheet { _ in }
}
