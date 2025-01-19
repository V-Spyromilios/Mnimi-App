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
    private let dotAnimationDuration = 0.3
    var text : String?

    var body: some View {
        HStack(spacing: 5) {
            Text(String(localized: "loadingDotsViewText"))
                .font(.title2).bold().foregroundStyle(.blue.opacity(0.7)).fontDesign(.rounded)
            
            HStack(spacing: 5) {
                ForEach(0..<3) { index in
                    Circle()
                        .frame(width: 7, height: 7)
                        .foregroundStyle(.blue.opacity(0.8)).fontDesign(.rounded)
                        .opacity(currentDot == index ? 1.0 : 0.6)
                }
            }.offset(y: 3)
            .onAppear {
                startLoadingAnimation()
            }
        }
    }
    
    func startLoadingAnimation() {
        Timer.scheduledTimer(withTimeInterval: dotAnimationDuration, repeats: true) { _ in
            DispatchQueue.main.async {
                withAnimation {
                    currentDot = (currentDot + 1) % dotCount
                }
            }
        }
    }
}
#Preview {
    LoadingDotsView()
}
