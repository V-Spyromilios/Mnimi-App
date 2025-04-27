////
////  CoolButton.swift
////  MyndVault
////
////  Created by Evangelos Spyromilios on 08.01.25.
////
//
//import SwiftUI
//
//struct CoolButton: View {
//    @Environment(\.isEnabled) private var isEnabled
//    let title: String
//    let systemImage: String
//    let action: () -> Void
//
//    var body: some View {
//        Button(action: action) {
//            HStack(spacing: 12) {
//                Image(systemName: systemImage)
//                    .renderingMode(.template)
//                    .resizable()
//                    .aspectRatio(contentMode: .fit)
//                    .frame(height: 24)
//                    .foregroundColor(.blue)
//                Text(title)
//                    .font(.system(size: 18, weight: .bold))
//                    .minimumScaleFactor(0.8)
//                    .fontDesign(.rounded)
//                    .foregroundColor(.blue)
//            }
//            .padding(.top)
//            .padding(.bottom)
//            .padding(.horizontal, 24)
//            .frame(height: Constants.buttonHeight)
//            .background(
//                RoundedRectangle(cornerRadius: 10)
//                    .fill(
//                        LinearGradient(
//                            gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.blue.opacity(0.2), Color.blue.opacity(0.3), Color.blue.opacity(0.4)]),
//                            startPoint: .top,
//                            endPoint: .bottom
//                        )
//                    )
//                    .shadow(color: isEnabled ? Color.blue.opacity(0.5) : Color.blue.opacity(0.3),
//                            radius: isEnabled ? 3 : 1,
//                            x: isEnabled ? 4 : 2, y: isEnabled ? 4 : 2)
//            )
//        }
//    }
//}
//
//#Preview {
//    CoolButton(title: "Save", systemImage: "cloud.fill") {
//        print("Button pressed - Preview")
//    }
//    .frame(width: 160)
//}
