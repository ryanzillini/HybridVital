import SwiftUI
import WidgetKit

struct Zone2StartEntry: TimelineEntry {
    let date: Date
}

struct Zone2StartProvider: TimelineProvider {
    func placeholder(in context: Context) -> Zone2StartEntry {
        Zone2StartEntry(date: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (Zone2StartEntry) -> Void) {
        completion(Zone2StartEntry(date: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Zone2StartEntry>) -> Void) {
        completion(Timeline(entries: [Zone2StartEntry(date: .now)], policy: .never))
    }
}

struct Zone2StartWidgetView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "heart.fill")
                .font(.title)
                .foregroundStyle(.green)
            Text("Zone 2")
                .font(.headline)
            Text("Start session")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) {
            Color.black
        }
    }
}

struct Zone2StartWidget: Widget {
    let kind = "Zone2StartWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Zone2StartProvider()) { _ in
            Zone2StartWidgetView()
        }
        .configurationDisplayName("Zone 2")
        .description("Open HybridVital to start a Zone 2 session.")
        .supportedFamilies([.systemSmall])
    }
}
