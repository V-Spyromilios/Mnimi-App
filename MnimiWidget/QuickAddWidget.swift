//
//  QuickAddWidget.swift
//  QuickAddWidget
//
//  Created by Evangelos Spyromilios on 06.06.25.
//

import WidgetKit
import SwiftUI


struct QuickAddEntry: TimelineEntry {
    let date: Date
}

struct QuickAddProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuickAddEntry {
        QuickAddEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (QuickAddEntry) -> ()) {
        completion(QuickAddEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickAddEntry>) -> ()) {
        let entry = QuickAddEntry(date: Date())
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}


struct QuickAddWidgetEntryView: View {
    var entry: QuickAddEntry

    var body: some View {
        HStack(spacing: 6) {
            Text("Mnimi")
                .font(.custom("New York", size: 18))
                .fontWeight(.semibold)
                .foregroundStyle(.primary)

            Image(systemName: "arrow.up.forward")
                .resizable()
                .scaledToFit()
                .frame(width: 15, height: 15)
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.15), lineWidth: 1)
        )
        .widgetURL(URL(string: "mnimi://add"))
    }
}

struct QuickAddWidget: Widget {
    let kind: String = "QuickAddWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuickAddProvider()) { entry in
            if #available(iOS 17.0, *) {
                QuickAddWidgetEntryView(entry: entry)
                    .containerBackground(.clear, for: .widget)
            } else {
                QuickAddWidgetEntryView(entry: entry)
                    .padding()
                    
            }
        }
        .configurationDisplayName("Open Mnimi")
        .description("Tap to quickly add info or ask a question to Mnimi App.")
        .supportedFamilies([.accessoryRectangular]) // 🔥 Lock screen support
    }
}
