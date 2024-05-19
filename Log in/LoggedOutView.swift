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
               Color.britishRacingGreen.ignoresSafeArea()
            VStack {
                
                Text("Mynd Vault 🗃️").font(.largeTitle).fontWeight(.semibold).foregroundStyle(.white).fontDesign(.rounded).padding(.top)
                Spacer()
                Image(systemName: "lock.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.black)
                Text("You are logged out")
                    .font(.title)
                    .foregroundColor(.gray)
                    .padding()
            Spacer()
            }
           }
    }
}

#Preview {
    LoggedOutView()
}
