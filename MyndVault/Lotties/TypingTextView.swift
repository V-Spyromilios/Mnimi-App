//
//  TypingTextView.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 19.07.24.
//

import SwiftUI

struct TypingTextView: View {

    @State private var displayedText: String = ""
    @State private var hasTyped: Bool = false
    let fullText: String
    var typingSpeed: Double =  0.1

    var body: some View {
        HStack {
            Text(displayedText)
                .font(Font.custom("SF Mono Semibold", size: 16))
                .multilineTextAlignment(.leading)
                .padding(.horizontal)
                .onAppear {
                    if !hasTyped {
                        typeText() }
                }
            Spacer()
        }.frame(maxWidth: .infinity)
    }

    private func typeText() {

        displayedText = ""
        let characters = Array(fullText)
        var currentIndex = 0
        
        Timer.scheduledTimer(withTimeInterval: typingSpeed, repeats: true) { timer in
            if currentIndex < characters.count {
                displayedText.append(characters[currentIndex])
                currentIndex += 1
            } else {
                timer.invalidate()
                hasTyped = true
            }
        }
    }
}

#Preview {
    TypingTextView(fullText: "AI did that ?!\nLorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book.\nIt has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.")
}
