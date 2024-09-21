//
//  FullScreenImage.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 02.07.24.
//

import SwiftUI

struct FullScreenImage: View {

    @Binding var show: Bool
    @Environment(\.colorScheme) var colorScheme
    @State private var dismissInfoIsVisible: Bool = true

    var image: UIImage
    
    var body: some View {

            ZStack {

                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .onTapGesture {
                withAnimation {
                    show = false
                }
            }
            .background {
                LottieRepresentable(filename: "Gradient Background", loopMode: .loop, speed: Constants.backgroundSpeed, contentMode: .scaleAspectFill)
                    .opacity(0.4)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
            }
            .statusBar(hidden: true)
            .overlay {
                if  dismissInfoIsVisible {
                    VStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: Constants.rectCornerRad)
                                .fill(Color.customLightBlue)
                                .shadow(color: Color.customShadow, radius: colorScheme == .light ? 5 : 3, x: 0, y: 0)
                                .frame(width: 220, height: 30)
                            
                            HStack {
                                Spacer()

                                Image(systemName: "hand.tap.fill").bold()
                                Text("Tap image to dismiss").bold()
                                
                                Spacer()
                            }.font(.footnote).padding(.top, 12).padding(.bottom, 8).padding(.horizontal, Constants.standardCardPadding).foregroundStyle(.gray)
//                                .shadow(radius: 2)
                            
                                .onAppear {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                                        withAnimation {
                                            dismissInfoIsVisible = false
                                        }
                                    }
                                }
                        }
                            Spacer()
                            
                        } .transition(.blurReplace(.upUp))
                    
                }
            }
    }
    
}

struct FullScreenImage_Previews: PreviewProvider {
   static let imageSample = UIImage(named: "Wolfsburg")
    
    static var previews: some View {
       
        if let imageSample = imageSample {
            FullScreenImage(show: .constant(true), image: imageSample)
        }
    }
}

