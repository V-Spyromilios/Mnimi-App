//
//  FullScreenImage.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 02.07.24.
//

import SwiftUI

struct FullScreenImage: View {

    @Environment(\.colorScheme) var colorScheme
    
    var image: UIImage
    
    var body: some View {
            
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .ignoresSafeArea()
    }
}

//struct FullScreenImage_Previews: PreviewProvider {
//   static let imageSample = UIImage(named: "Wolfsburg")
//
//    static var previews: some View {
//
//        if let imageSample = imageSample {
//            FullScreenImage(activeModal: .none, show: .constant(true), image: imageSample)
//        }
//    }
//}

