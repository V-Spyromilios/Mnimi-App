//
//  testScroll.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 09.07.24.
//

import SwiftUI

struct testScroll: View {
    let screenWidth = UIScreen.main.bounds.width
       let screenHeight = UIScreen.main.bounds.height
    
    var body: some View {
        GeometryReader { geometryProxy in
            VStack {
                ScrollView {
                    Text("Huge text here.\nHuge text here.\nHuge text here.\nHuge text here.\nHuge text here.\nHuge text here.\nHuge text here.\nHuge text here.\nHuge text here.\nHuge text here.\nHuge text here.\nHuge text here.\nHuge text here.\nHuge text here.\nHuge text here.\nHuge text here.\nHuge text here.\nHuge text here.\nHuge text here.\nHuge text here.\nHuge text here.\nHuge text here.\nHuge text here.\nHuge text here.\nHuge text here.\n")
                        .foregroundStyle(.yellow).frame(width: screenWidth).padding()
                }
                
                ScrollView {
                    Text("Huge text here.\nHuge text here.\nHuge text here.\nHuge text here.\nHuge text here.\nHuge text here.\nHuge text here.\nHuge text here.\nHuge text here.\nHuge text here.\nHuge text here.\nHuge text here.\nHuge text here.\nHuge text here.\nHuge text here.\nHuge text here.\nHuge text here.\nHuge text here.\nHuge text here.\nHuge text here.\nHuge text here.\nHuge text here.\nHuge text here.\nHuge text here.\nHuge text here.\n")
                        .foregroundStyle(.green)
                }.padding(.top, 12)
            }.background(Color.blue.ignoresSafeArea())
        }
    }
}

#Preview {
    testScroll()
}
