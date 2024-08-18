//
//  CustomPayWall.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 18.08.24.
//

import SwiftUI
import RevenueCat
import RevenueCatUI

struct CustomPayWall: View {
    var body: some View {
        ZStack {
            LottieRepresentable(filename: "Gradient Background", loopMode: .loop, speed: backgroundSpeed, contentMode: .scaleAspectFill)
                .opacity(0.4)
            //                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
            ScrollView {
               
              
                LottieRepresentable(filename: "Woman_vault")
                    .frame(height: 300)
                Spacer()
                
                
            }
        }.paywallFooter(condensed: true)
            
    }
}

#Preview {
    CustomPayWall()
}
