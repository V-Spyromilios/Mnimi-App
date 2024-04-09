//
//  EditConfirmView.swift
//  Memory
//
//  Created by Evangelos Spyromilios on 21.03.24.
//

import SwiftUI
import MijickPopupView

struct EditConfirmView: TopPopup {
    func createContent() -> some View {
            HStack(spacing: 0) {
                Text("Info Saved")
                Spacer()
                Button(action: dismiss) { Text("OK") }
            }
            .padding(.vertical, 20)
            .padding(.leading, 24)
            .padding(.trailing, 16)
            .background {
                Color.yellow
            }
        }
    
//    var body: some View {
//        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
//    }
}

#Preview {
    EditConfirmView()
}
