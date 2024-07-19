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
        Text(displayedText)
            .font(Font.custom("SF Mono Semibold", size: 16))
            .multilineTextAlignment(.leading)
            .padding(.horizontal)
            .onAppear {
                if !hasTyped {
                    typeText() }
            }
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
    TypingTextView(fullText: "AI did that ?!")
}
