////
////  CustomTapBarView.swift
////  Memory
////
////  Created by Evangelos Spyromilios on 12.02.24.
////
//
//import SwiftUI
//
//struct CustomTabBarView: View {
//    @Environment(\.colorScheme) private var colorScheme
//    
//    @Binding var tabSelection: Int
//    @State private var questionIsAnimating: Bool = true
//    @State private var addIsAnimating: Bool = false
//    @State private var vaultIsAnimating: Bool = false
//    @State private var notificationsIsAnimating: Bool = false
//    @EnvironmentObject var languageSettings: LanguageSettings
//    let customTabbarHeight: CGFloat = 80
//    
//    
//    var body: some View {
//        ZStack {
//            
//            VisualEffectBlur(blurStyle: .systemUltraThinMaterial)
//                .background(Color.clear)
//                .frame(height: customTabbarHeight)
//            
//            HStack(alignment: .top) {
//                
//                Spacer()
//                
//                lottieTabBarButton(name: "UploadingFile", tabId: 1, isPlaying: $addIsAnimating)
//                    .frame(width: 45, height: 45)
//                
//                
//                Spacer()
//                
//                lottieTabBarButton(name: "robotForQuestion", tabId: 2, isPlaying: $questionIsAnimating)
//                    .frame(width: 55, height: 58)
//                
//                
//                Spacer()
//                lottieTabBarButton(name: "smallVault", tabId: 3, isPlaying: $vaultIsAnimating)
//                    .frame(width: 50, height: 50)
//                
//                Spacer()
//            }
//            .frame(height: customTabbarHeight) // ! Same as capsule height !
//        }
//    }
//    
//    struct VisualEffectBlur: UIViewRepresentable {
//        var blurStyle: UIBlurEffect.Style
//        var vibrancyStyle: UIVibrancyEffectStyle? = nil
//        
//        func makeUIView(context: Context) -> UIVisualEffectView {
//            let blurView = UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
//            if let vibrancyStyle = vibrancyStyle {
//                let vibrancyEffect = UIVibrancyEffect(blurEffect: UIBlurEffect(style: blurStyle), style: vibrancyStyle)
//                let vibrancyView = UIVisualEffectView(effect: vibrancyEffect)
//                vibrancyView.frame = blurView.contentView.bounds
//                vibrancyView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//                blurView.contentView.addSubview(vibrancyView)
//            }
//            return blurView
//        }
//        
//        func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
//            uiView.effect = UIBlurEffect(style: blurStyle)
//        }
//    }
//
//    private func lottieTabBarButton(name: String, tabId: Int, isPlaying: Binding<Bool>) -> some View {
//        Button(action: {
//            tabSelection = tabId
//            isPlaying.wrappedValue.toggle()
//        }) {
//            LottieRepresentable(filename: name, loopMode: .playOnce,speed: 1.2, isPlaying: isPlaying, contentMode: .scaleAspectFit)
//                .scaleEffect(tabSelection == tabId ? 1.4 : 1.1)
//                .animation(.easeInOut(duration: 0.2), value: tabSelection)
//                .shadow(
//                    color: (colorScheme == .dark ? Color.gray : Color.black).opacity(tabSelection == tabId ? 0.5 : 0),
//                    radius: tabSelection == tabId ? 2 : 0,
//                    x: tabSelection == tabId ? 5 : 0,
//                    y: tabSelection == tabId ? 5 : 0
//                )
//        }
//    }
//    
//}
