//
//  HideKeyboardLabel.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 25.05.24.
//

import SwiftUI

struct HideKeyboardLabel: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .foregroundStyle(.buttonText)
            .frame(width: 35, height: 32)
            .shadow(color: Color.customShadow, radius: toolbarButtonShadow)
            .overlay {
                Image(systemName: "keyboard.chevron.compact.down")
                    .padding()
                .accessibilityLabel("Hide Keyboard") }
            }
    }


#Preview {
    HideKeyboardLabel()
}
