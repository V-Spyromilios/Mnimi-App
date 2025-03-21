//
//  test.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 16.03.25.
//

import SwiftUI

struct CADView: View {
    var onCancel: () -> Void
    var body: some View {
        VStack(spacing: 17) {
            Text("Callendar Access Denied")
                .font(Font.custom("SF Mono Semibold", size: 17))
                .fontDesign(.monospaced)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
                .padding(.horizontal)
                .lineLimit(nil) // Ensure text can wrap
                .fixedSize(horizontal: false, vertical: true) // Allows it to expand vertically

            Text("MyndVault needs access to your calendar to schedule events when you want to.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .fontDesign(.rounded)

            CoolButton(title: "Open Settings", systemImage: "arrowshape.turn.up.forward") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
//            .buttonStyle(.borderedProminent)

            Button("Cancel") {
                
            }
            .buttonStyle(.bordered)
        }
//        .padding()
    }
}

#Preview {
    CADView() {
        debugLog("onCancel from Preview")
    }
}
