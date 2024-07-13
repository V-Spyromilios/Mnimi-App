//
//  SwiftLogoView.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 13.07.24.
//

import SwiftUI

struct SwiftLogoView: View {
    @State private var isPlaying = false
    
    var body: some View {
        VStack {
            LottieRepresentable(filename: "Swift", isPlaying: $isPlaying).id(UUID())
            
            Button(action: {
                isPlaying.toggle()
            }) {
                Text(isPlaying ? "Stop" : "Go")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
    }
}
