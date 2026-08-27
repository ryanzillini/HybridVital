import PhotosUI
import SwiftUI

struct PhotoCaptureStubView: View {
    let repository: FoodLoggingRepository
    let source: FoodLogMethod

    @Environment(\.dismiss) private var dismiss
    @State private var pickerItem: PhotosPickerItem?
    @State private var isAnalyzing = false
    @State private var showingReview = false

    init(repository: FoodLoggingRepository, source: FoodLogMethod = .camera) {
        self.repository = repository
        self.source = source
    }

    var body: some View {
        NavigationStack {
            ZStack {
                HVTheme.background.ignoresSafeArea()

                VStack(spacing: 24) {
                    viewfinder
                    caption
                    shutter
                    if source == .library {
                        PhotosPicker(selection: $pickerItem, matching: .images) {
                            Label("Choose from library", systemImage: "photo.on.rectangle")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(HVTheme.cardElevated)
                                .clipShape(RoundedRectangle(cornerRadius: HVTheme.radiusM, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, HVTheme.pagePadding)
                .padding(.top, 12)
                .padding(.bottom, 24)

                if isAnalyzing {
                    analyzingOverlay
                }
            }
            .navigationTitle("Scan meal")
            .hvInlineNav()
            .hvScreen()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(isPresented: $showingReview) {
                FoodAnalysisReviewSheet(
                    repository: repository,
                    food: DemoCatalog.visionParse,
                    saveSource: .grokVision,
                    onSaved: {
                        showingReview = false
                        dismiss()
                    }
                )
            }
            .onChange(of: pickerItem) { _, newValue in
                guard newValue != nil else { return }
                analyzeThenReview()
            }
        }
        .preferredColorScheme(.dark)
    }

    private var viewfinder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: HVTheme.radiusL, style: .continuous)
                .fill(Color.white.opacity(0.04))
            RoundedRectangle(cornerRadius: HVTheme.radiusL, style: .continuous)
                .stroke(Color.white.opacity(0.22), lineWidth: 1.5)

            ViewfinderGrid()
                .padding(18)

            VStack(spacing: 10) {
                Image(systemName: source == .library ? "photo.on.rectangle" : "fork.knife")
                    .font(.system(size: 44))
                    .foregroundStyle(.white.opacity(0.28))
                    .symbolRenderingMode(.hierarchical)
                Text(source == .library ? "Library preview" : "Viewfinder")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.35))
            }
        }
        .aspectRatio(3 / 4, contentMode: .fit)
        .shadow(color: .black.opacity(0.4), radius: 20, y: 8)
    }

    private var caption: some View {
        Text(source == .library
             ? "Pick a plate photo. Grok Vision will parse it — you always review before save."
             : "Frame the plate and tap the shutter. Nothing is saved until you review the parse.")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }

    private var shutter: some View {
        Button(action: analyzeThenReview) {
            ZStack {
                Circle()
                    .stroke(.white, lineWidth: 4)
                    .frame(width: 78, height: 78)
                Circle()
                    .fill(isAnalyzing ? HVTheme.accent : Color.white)
                    .frame(width: 64, height: 64)
            }
        }
        .buttonStyle(.plain)
        .disabled(isAnalyzing)
        .accessibilityLabel("Shutter")
    }

    private var analyzingOverlay: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 12) {
                ProgressView()
                    .tint(HVTheme.accent)
                Text("Reading the plate…")
                    .font(.headline)
                Text("You’ll edit anything that looks off.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
            .background(HVTheme.cardElevated)
            .clipShape(RoundedRectangle(cornerRadius: HVTheme.radiusM, style: .continuous))
        }
        .allowsHitTesting(true)
    }

    private func analyzeThenReview() {
        guard !isAnalyzing else { return }
        isAnalyzing = true
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(700))
            isAnalyzing = false
            showingReview = true
        }
    }
}

private struct ViewfinderGrid: View {
    var body: some View {
        ZStack {
            HStack {
                Spacer()
                Rectangle().fill(Color.white.opacity(0.18)).frame(width: 1)
                Spacer()
                Rectangle().fill(Color.white.opacity(0.18)).frame(width: 1)
                Spacer()
            }
            VStack {
                Spacer()
                Rectangle().fill(Color.white.opacity(0.18)).frame(height: 1)
                Spacer()
                Rectangle().fill(Color.white.opacity(0.18)).frame(height: 1)
                Spacer()
            }
        }
        .allowsHitTesting(false)
    }
}
