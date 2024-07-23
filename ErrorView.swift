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
    var dismissAction: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            Spacer()
            VStack {
                LottieRepresentable(filename: "alertWarning", loopMode: .loop).frame(height: 80)
                Text(thrownError).font(.title2).bold().multilineTextAlignment(.leading).padding(.bottom)
                if extraMessage != nil {
                    Text(extraMessage ?? "").font(.title3)
                    //.bold()
                        .multilineTextAlignment(.leading).padding(.bottom)
                }
                Button(action: {
                    dismissAction()
                }) {
                    Text("Dismiss")
                        .font(.headline)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }.background(colorScheme == .light ? Color.white : Color.darkGray2)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(color: colorScheme == .light ? Color.customShadow : Color.yellow, radius: colorScheme == .light ? 5 : 5, x: 0, y: 0)
                .overlay(
                    RoundedRectangle(cornerRadius: 10.0)
                        .stroke(lineWidth: 1)
                        .opacity(colorScheme == .light ? 0.3 : 0.7)
                        .foregroundColor(colorScheme == .light ? Color.gray: Color.yellow)
                )
            Spacer()
        }
        .padding(.horizontal, standardCardPadding)
        .background {  Color.clear.background(.ultraThinMaterial).ignoresSafeArea() }
        
        
    }
}

#Preview {
    ErrorView(thrownError: "Ω να σου γα....", extraMessage: "Please try again.", dismissAction: { print("Error view simulation")})
}
