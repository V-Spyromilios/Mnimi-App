//
//  LoadingDotsView.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 25.09.24.
//

import SwiftUI

struct LoadingDotsView: View {
    @State private var currentDot = 0
    private let dotCount = 3
    private let dotAnimationDuration = 0.5
    
    var body: some View {
        HStack(spacing: 5) {
            Text("Loading")
                .font(.title2).bold().foregroundStyle(.blue.opacity(0.7)).fontDesign(.rounded)
            
            HStack(spacing: 5) {
                ForEach(0..<3) { index in
                    Circle()
                        .frame(width: 8, height: 8)
                        .foregroundStyle(.blue.opacity(0.7)).fontDesign(.rounded)
                        .opacity(currentDot == index ? 1.0 : 0.5)
                }
            }.offset(y: 3)
            .onAppear {
                startLoadingAnimation()
            }
        }
    }
    
    func startLoadingAnimation() {
        Timer.scheduledTimer(withTimeInterval: dotAnimationDuration, repeats: true) { _ in
            withAnimation {
                currentDot = (currentDot + 1) % dotCount
            }
        }
    }
}
#Preview {
    LoadingDotsView()
}
