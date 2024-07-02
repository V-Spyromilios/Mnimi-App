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
            .foregroundStyle(.gray.opacity(0.6))
            .frame(width: 35, height: 32)
            .shadow(color: Color.customShadow, radius: toolbarButtonShadow)
            .overlay {
                Image(systemName: "keyboard.chevron.compact.down")
                    .foregroundStyle(.yellow)
                    .padding()
                .accessibilityLabel("Hide Keyboard") }
            }
    }


#Preview {
    HideKeyboardLabel()
}
