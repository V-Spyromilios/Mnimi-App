//
//  AboutUsView.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 10.08.24.
//

import SwiftUI

struct AboutUsView: View {
    @State private var animate: Bool = false
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    var body: some View {
        ScrollView {
           
                TypingTextView(fullText: "Hello World !", typingSpeed: 0.1, isTitle: true)
                    .frame(maxWidth: .infinity)
                    .padding()
            
            
            
            LottieRepresentable(filename: "ManWithLaptop").frame(height: 200)
            
            VStack {
                
            }.frame(height: 400)
            
            HStack {
                Spacer()
                madeWith()
                    .padding()
                
               
            }.frame(maxWidth: .infinity)
            
            
                .navigationBarBackButtonHidden(true)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            self.presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Settings")
                            }.font(.title2).bold().foregroundStyle(.blue.opacity(0.7)).fontDesign(.rounded).padding(.trailing, 6)
                        }
                    }
                }
        }  .background {
            LottieRepresentable(filename: "Gradient Background", loopMode: .loop, speed: Constants.backgroundSpeed, contentMode: .scaleAspectFill)
                .opacity(0.4)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
        }
      
    }
    
    
}

#Preview {
    AboutUsView()
}


private func madeWith() -> some View {
    HStack {
       
//        Text("Made with").font(.title3).fontDesign(.rounded)
//            .offset(x: 85)
        LottieRepresentable(filename: "Swift", loopMode: .loop, speed: 0.5)
            
            .frame(width: 80, height: 80)
//        LottieRepresentable(filename: "")
        
        Image("Wolfsburg")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 40, height: 40)
//            .offset(x: -70)
        
    }.padding(.horizontal)
}
