//
//  KErrorView.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 17.05.25.
//

import SwiftUI

struct KErrorView: View {
    let title: String
    let message: String
    let ButtonText: String
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text(title)
                .font(.custom("New York", size: 20))
                .foregroundStyle(.black)
                .italic()
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)


            Text(message)
                .font(.custom("New York", size: 16))
                .foregroundStyle(.black)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .padding(.horizontal)

            Button(action: retryAction) {
                           Text(ButtonText)
                               .font(.custom("New York", size: 17))
                               .padding(.horizontal, 24)
                               .padding(.vertical, 10)
                               .background(
                                   Capsule()
                                       .fill(Color.gray.opacity(0.85))
                               )
                               .foregroundColor(.white)
                               .shadow(radius: 2)
                       }
                       .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.softWhite.opacity(0.7))
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
        )
        .padding(40)
        .transition(.opacity.combined(with: .scale))
    }
}
#Preview {
    
    KErrorView(title: "Error while loading and Error while loading", message: "Please check your connection Please check your connection Please check your connection", ButtonText: "Retry", retryAction: {})
        .background(KiokuBackgroundView()).ignoresSafeArea()
}
