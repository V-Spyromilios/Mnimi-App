//
//  ErrorView.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 15.07.24.
//

import SwiftUI

struct ErrorView2: View {
    
    var thrownError: String
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        
        VStack {
            LottieRepresentable(filename: "alertWarning", loopMode: .loop).frame(height: 80)
            Text(thrownError).font(.caption).bold().multilineTextAlignment(.leading).padding(.bottom)
        }

        .background(colorScheme == .light ? Color.white : Color.gray)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: Color.customShadow, radius: colorScheme == .light ? 5 : 3, x: 0, y: 0)
        .overlay(
            RoundedRectangle(cornerRadius: 10.0)
                .stroke(lineWidth: 1)
                .opacity(colorScheme == .light ? 0.3 : 0.7)
                .foregroundColor(Color.gray)
        )
        .animation(.easeOut, value: thrownError)
    }
}

#Preview {
    ErrorView2(thrownError: "Something is wrong here.")
}
