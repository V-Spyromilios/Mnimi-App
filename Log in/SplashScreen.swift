//
//  SplashScreen.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 13.06.24.
//

import SwiftUI

struct SplashScreen: View {
    @EnvironmentObject var cloudKit: CloudKitViewModel //use this to check of loading is ok, check Notes
    
    @State private var greenHeight: CGFloat = 0
    @State private var showLogo: Bool = false
    @State private var currentSymbolIndex: Int = 0
    @State private var loadingComplete: Bool = false
    
    let symbols = ["link.icloud", "tray", "tray.2", "" ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    //                    Spacer()
                    Rectangle()
                        .fill(greenGradient)
                    //                        .fill(Color.britishRacingGreen)
                        .frame(height: greenHeight)
                        .ignoresSafeArea(.all)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 1)) {
                                greenHeight = geometry.size.height
                                + (geometry.size.height * 0.15)
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation(.easeInOut(duration: 0.6)) {
                                    showLogo = true
                                }
                            }
                        }
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
                
                if showLogo {
                    carousel()
                   
                }
            }.onChange(of: currentSymbolIndex) {
                if currentSymbolIndex == 3 { //the index of symbols[""]
                    showLogo = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        loadingComplete = true //just to mimic the loading ok
                    }
                }
            }
            .onChange(of: loadingComplete) {
                if loadingComplete {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        greenHeight = 0
                    }
                }
            }
        }
    }
    
    
    @ViewBuilder
    private func carousel() -> some View {
        
        VStack {
            Image(systemName: symbols[currentSymbolIndex])
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .transition(.opacity)
                .onAppear {
                    Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                        withAnimation(.easeInOut) {
                            currentSymbolIndex = (currentSymbolIndex + 1) % symbols.count
                        }
                    }
                }
        }
    }
}
#Preview {
    SplashScreen()
}
