//
//  Test.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 20.07.24.
//

import SwiftUI

struct Test: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LottieRepresentable(filename: "Gradient Background", loopMode: .loop, speed: Constants.backgroundSpeed, contentMode: .scaleAspectFill)
                    .opacity(0.4)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                   .ignoresSafeArea()
//                Color.white.ignoresSafeArea().opacity(0.3)
//                ScrollView {
                    //                Text("COOL").bold()
                    Text("OH YES").bold()
//                }
            }
//            NavigationStack {
//            VStack {
//                Text("Height: \(geometry.size.height)").bold()
//                    .foregroundStyle(colorScheme == .light ? .black : .red)
//                
//                
//               
//            }
//                }
               
                    
//                .navigationBarTitleView {
//                    
//                    
//                    HStack {
//                        Text("Save New Info").font(.title2).bold().foregroundStyle(.yellow)
//                        //                        .opacity(0.9))
//                            .fontDesign(.rounded)
//                            .padding(.trailing, 6)
//                        LottieRepresentable(filename: "Cloud Upload").frame(width: 55, height: 55).padding(.bottom, 5).shadow(color: colorScheme == .dark ? .white : .clear, radius: colorScheme == .dark ? 4 : 0)
//                    }.frame(width: .infinity)
//                    
//                }
//                .toolbarBackground(colorScheme == .light ? .yellow.opacity(0.1) : .black.opacity(0.2), for: .navigationBar)
//                .toolbarBackground(.visible, for: .navigationBar)
                //            .toolbarColorScheme(.light)
            
        
        }
        
        
    }
}


#Preview {
    Test()
}
