//
//  FullScreenImage.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 02.07.24.
//

import SwiftUI

struct FullScreenImage: View {
    @Binding var show: Bool
    //    @Environment(\.dismiss) private var dismiss
    var image: UIImage
    
    var body: some View {
        ZStack {
            
            Color.britishRacingGreen.ignoresSafeArea()
            
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onTapGesture {
                    withAnimation {
                        show = false
                        //                            dismiss()
                    }
                }
        } .statusBar(hidden: true)
    }
    
}
