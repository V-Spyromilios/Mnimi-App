//
//  ImageView.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 07.11.24.
//

import SwiftUI

struct ImageView: View {
    let index: Int
    let image: UIImage
    @Binding var activeModal: QuestionView.ActiveModal?
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(height: isIPad() ? 440 : 160)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(color: Color.customShadow, radius: colorScheme == .light ? 5 : 3)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut) {
                activeModal = .fullImage(image)
            }
        }
    }
}
