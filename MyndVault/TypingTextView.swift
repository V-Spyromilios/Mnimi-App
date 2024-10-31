//
//  TypingTextView.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 19.07.24.
//

import SwiftUI
import Combine

@MainActor
struct TypingTextView: View {
    @State private var displayedText: String = ""
    @State private var hasTyped: Bool = false
    let fullText: String
    var typingSpeed: Double = 0.01
    var isTitle: Bool = false

    @State private var timerCancellable: AnyCancellable?

    var body: some View {
        HStack {
            Text(displayedText)
                .font(Font.custom(isTitle ? "SF Compact" : "SF Mono Semibold", size: isTitle ? 29 : 16))
                .fontDesign(isTitle ? .rounded : .monospaced)
                .foregroundStyle(isTitle ? Color.customTiel : .primary)
                .multilineTextAlignment(.leading)
                .padding(.horizontal)
                .onAppear {
                    if !hasTyped {
                        startTyping()
                    }
                }
            Spacer()
        }.frame(maxWidth: .infinity)
    }

    private func startTyping() {
        let characters = Array(fullText)
        var currentIndex = 0

        timerCancellable = Timer.publish(every: typingSpeed, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                if currentIndex < characters.count {
                    displayedText.append(characters[currentIndex])
                    currentIndex += 1
                } else {
                    timerCancellable?.cancel()  // cancel the Combine publisher
                    hasTyped = true
                }
            }
    }
}

#Preview {
    TypingTextView(fullText: "AI did that ?!\nLorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book.\nIt has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.")
}
