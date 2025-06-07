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
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }

    private func loadNotes() -> [String] {
        let defaults = UserDefaults(suiteName: "group.app.mnimi.shared")
        let notes = defaults?.stringArray(forKey: "recent_notes") ?? []
        if notes.isEmpty {
            return ["No recent notes"]
        }
        return notes
    }
}

struct RecentNotesWidgetEntryView: View {
    var entry: RecentNotesProvider.Entry

    var body: some View {
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Spacer()
                    Text("Mnimi – Recent Notes")
                        .font(.custom("New York", size: 19, relativeTo: .title2))
                        .foregroundStyle(.black)
                        .fontWeight(.semibold)
                        .padding(.bottom, 9)
                    Spacer()
                }

                ForEach(entry.notes.prefix(5), id: \.self) { note in
                    Text("“\(note.trimmingCharacters(in: .whitespacesAndNewlines))”")
                        .font(.custom("New York", size: 14, relativeTo: .body))
                        .foregroundStyle(.black.opacity(0.9))
                        .lineLimit(3)
                        .minimumScaleFactor(0.8)
                        .padding(.bottom, 8)
                }
                Spacer()
            }
            .padding()
            .shadow(radius: 3)
        
        .widgetURL(URL(string: "mnimi://vault"))
        .containerBackground(for: .widget) {
            Image("oldPaper")
                .resizable()
                .scaledToFill()
                .clipped()
        }
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
        .supportedFamilies([.systemLarge])
    }
}
