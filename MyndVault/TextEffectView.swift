//
//  TextEffectView.swift
//  Memory
//
//  Created by Evangelos Spyromilios on 23.02.24.
//

import SwiftUI

//MARK: DEPRICATED
struct CoolButtonView: View {
    @Environment(\.colorScheme) var colorScheme
    var isRecording: Bool
    var text = ""

    var body: some View {
        Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                           .renderingMode(.template)
                           .resizable()
                           .scaledToFit()
//                           .frame(width: 80, height: 80)
                           .background(Circle().fill(LinearGradient.bluePurpleGradient()))
                           .shadow(color: .gray, radius: 10, x: 0, y: 5)
                           .overlay(Circle().stroke(Color.blue, lineWidth: 2))
                           .foregroundColor(.white)
                   
                   .scaleEffect(isRecording ? 1.1 : 1.0)
                   .animation(.spring(duration: 0.2), value: isRecording)
               
               .padding()
               .background( AnyView(LinearGradient.bluePurpleGradient()))
//               .background(isRecording ? AnyView(bluePurpleGradient) : AnyView(Color.clear))
               .cornerRadius(20)
               .shadow(radius: isRecording ? 20 : 10)
               .padding()
        if !text.isEmpty && isRecording == false {
            Text(text).font(.largeTitle ).fontDesign(.rounded)
                            .padding()
                            .foregroundColor(colorScheme == .dark ? .blue : .black)
                    }
    }
}




#Preview {
    Group {
        CoolButtonView(isRecording: false, text: "Tap to Record").preferredColorScheme(.dark)
        
    }}
