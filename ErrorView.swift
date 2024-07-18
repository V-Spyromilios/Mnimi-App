//
//  ErrorView.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 15.07.24.
//

import SwiftUI

struct ErrorView: View {
    
    var thrownError: String
    var extraMessage: String?
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        
        VStack {
            LottieRepresentable(filename: "alertWarning", loopMode: .loop).frame(height: 80)
            Text(thrownError).font(.title2).bold().multilineTextAlignment(.leading).padding(.bottom)
            if extraMessage != nil {
                Text(extraMessage ?? "").font(.title3).bold().multilineTextAlignment(.leading).padding(.bottom) }
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
    ErrorView(thrownError: "Something is wrong here.")
}
