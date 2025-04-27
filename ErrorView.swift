////
////  ErrorView.swift
////  MyndVault
////
////  Created by Evangelos Spyromilios on 15.07.24.
////
//
//import SwiftUI
//
//struct ErrorView: View {
//    
//    var thrownError: String
//    var extraMessage: String?
//    @Environment(\.colorScheme) var colorScheme
//    let haptic = UINotificationFeedbackGenerator()
//    var dismissAction: () -> Void
//    
//    var body: some View {
//        ScrollView {
//            VStack {
//                Spacer()
//                VStack {
//                    LottieRepresentable(filename: "alertWarning", loopMode: .playOnce).frame(height: 80)
//                    
//                    TypingTextView(fullText: thrownError + (extraMessage != nil ? "\n" + extraMessage! : ""))
//                        .shadow(radius: 1)
//
//                    Button(action: {
//                        withAnimation {
//                            dismissAction() }
//                    }) {
//                        Text("Dismiss")
//                            .font(.headline)
//                            .padding()
//                            
//                            .background(Color.yellow)
//                            .foregroundColor(.black)
//                            .cornerRadius(10)
//                    }.padding(.bottom)
//                }
//                .background(Color.clear.background(.ultraThinMaterial))
//                .clipShape(RoundedRectangle(cornerRadius: 30))
//                Spacer()
//            }
//            .padding(.horizontal, 16)
//            .onAppear {
//                haptic.notificationOccurred(.error)
//            }
//        }
//    }
//}
//
//#Preview {
//    ErrorView(thrownError: "Ω να σου γα....", extraMessage: "Please try again.", dismissAction: { print("Error view simulation")})
//}
