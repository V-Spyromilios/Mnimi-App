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
    var dismissAction: () -> Void
    
    var body: some View {
        ScrollView {
            VStack {
                Spacer()
                VStack {
                    LottieRepresentable(filename: "alertWarning", loopMode: .loop).frame(height: 80)
                    
                    TypingTextView(fullText: thrownError + (extraMessage != nil ? "\n" + extraMessage! : ""))

                    Button(action: {
                        withAnimation {
                            dismissAction() }
                    }) {
                        Text("Dismiss")
                            .font(.headline)
                            .padding()
                            
                            .background(Color.yellow)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }.padding(.bottom)
                }
                .background(Color.clear.background(.ultraThinMaterial))
                .clipShape(RoundedRectangle(cornerRadius: 30))
                Spacer()
            }
            .padding(.horizontal, 16)
        }
    }
}

#Preview {
    ErrorView(thrownError: "Ω να σου γα....", extraMessage: "Please try again.", dismissAction: { print("Error view simulation")})
}
