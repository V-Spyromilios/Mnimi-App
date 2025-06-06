//
//  RecentNotesWidget.swift
//  MnimiWidgetExtension
//
//  Created by Evangelos Spyromilios on 06.06.25.
//

import WidgetKit
import SwiftUI

struct RecentNotesEntry: TimelineEntry {
    let date: Date
    let notes: [String]
}

struct RecentNotesProvider: TimelineProvider {
    func placeholder(in context: Context) -> RecentNotesEntry {
        RecentNotesEntry(date: Date(), notes: ["Sample 1", "Sample 2"])
    }

    func getSnapshot(in context: Context, completion: @escaping (RecentNotesEntry) -> ()) {
        completion(RecentNotesEntry(date: Date(), notes: loadNotes()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RecentNotesEntry>) -> ()) {
        let entry = RecentNotesEntry(date: Date(), notes: loadNotes())
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60 * 15)))
        completion(timeline)
    }

    private func loadNotes() -> [String] {
        let defaults = UserDefaults(suiteName: "group.app.mnimi.shared")
        return defaults?.stringArray(forKey: "recent_notes") ?? []
    }
}

struct RecentNotesWidgetEntryView: View {
    var entry: RecentNotesProvider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image("AppIconWidget")
            Text("Recent Notes")
                .font(.custom("New York", size: 17, relativeTo: .title2))
                .fontWeight(.semibold)

            ForEach(entry.notes.prefix(3), id: \.self) { note in
                Text("• \(note)")
                    .font(.custom("New York", size: 12, relativeTo: .body))
                    .italic()
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding(10)
        .containerBackground(.ultraThinMaterial, for: .widget)
    }
}

struct RecentNotesWidget: Widget {
    let kind: String = "RecentNotesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RecentNotesProvider()) { entry in
            RecentNotesWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Recent Notes")
        .description("Your last saved thoughts at a glance.")
        .supportedFamilies([.accessoryRectangular])
    }
}
