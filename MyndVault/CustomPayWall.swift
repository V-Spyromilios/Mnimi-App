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
            LottieRepresentable(filename: "Gradient Background", loopMode: .loop, speed: Constants.backgroundSpeed, contentMode: .scaleAspectFill)
                .opacity(0.4)
                .ignoresSafeArea()

             ScrollView(showsIndicators: false) {
              
                    LottieRepresentable(filename: "Woman_vault")
                    .frame(height: 250)
                    .ignoresSafeArea()
                 benefits().padding(.all)
            }
        }
        .paywallFooter(condensed: true)
    }
}

#Preview {
    CustomPayWall()
}

@MainActor
@ViewBuilder
private func benefits() -> some View {
    
    Text("Use AI to Remember everything anytime").font(.largeTitle).fontDesign(.rounded).bold().padding(.bottom, 12)
    VStack {
      
        HStack(spacing: 12) {
            Image(systemName: "lock.fill").resizable().frame(width: 20, height: 25).foregroundStyle(.customLightPurple)
            
            Text("Securely save and retrieve your info").fontDesign(.monospaced).bold()
            Spacer()
        }.padding(.bottom, 12)
        
        HStack(spacing: 12) {
            Image(systemName: "lightbulb.fill").resizable().frame(width: 20, height: 25).foregroundStyle(.customLightPurple)
            
           Text("Access the world's most advanced and secure AI").fontDesign(.monospaced).bold()
            Spacer()
        }.padding(.bottom, 12)
        
        HStack(spacing: 12) {
            Image(systemName: "nosign").resizable().frame(width: 20, height: 20).foregroundStyle(.customLightPurple)
            
            Text("F*** Notifications, Ads and Personal Data Collection").fontDesign(.monospaced).bold()
            Spacer()
        }

        
    }.padding(.horizontal)
}

#Preview {
    CustomPayWall()
        .environment(\.locale, Locale(identifier: "de"))
}
