//
//  LoggedOutView.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 18.05.24.
//

import SwiftUI

struct LoggedOutView: View {
    var body: some View {
        ZStack {
            
            LottieRepresentable(filename: "Background Lines", loopMode: .loop, speed: Constants.backgroundSpeed, contentMode: .scaleAspectFill)
                    .opacity(0.4)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
            
            VStack {
                
                Text("Mynd Vault").font(.largeTitle).fontWeight(.semibold).foregroundStyle(.white).fontDesign(.rounded).padding(.top)
                Spacer()
                Image(systemName: "lock.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundStyle(Color.primaryBackground)
                    .padding(.bottom)
                TypingTextView(fullText: "You are logged out\nYou can close the app")
                    .shadow(radius: 1)
                
            Spacer()
            }
           }.statusBar(hidden: true)
    }
}

#Preview {
    LoggedOutView()
}
