//
//  CustomTapBarView.swift
//  Memory
//
//  Created by Evangelos Spyromilios on 12.02.24.
//

import SwiftUI

struct CustomTabBarView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var notificationsManager: NotificationViewModel
    @Binding var tabSelection: Int
    @State private var questionIsAnimating: Bool = true
    @State private var addIsAnimating: Bool = false
    @State private var vaultIsAnimating: Bool = false
    @State private var notificationsIsAnimating: Bool = false
    
    let customTabbarHeight: CGFloat = 80
    
    
    
    var body: some View {
        ZStack {
            //            Rectangle()
            VisualEffectBlur(blurStyle: .systemUltraThinMaterial)
                .background(Color.clear) // Adjust opacity to your liking
                .frame(height: customTabbarHeight)
            
            HStack(alignment: .top) {
                
                Spacer()
                
                lottieTabBarButton(name: "UploadingFile", tabId: 1, isPlaying: $addIsAnimating)
                    .frame(width: 45, height: 45)
                
                Spacer()
                
                lottieTabBarButton(name: "robotForQuestion", tabId: 2, isPlaying: $questionIsAnimating)
                    .frame(width: 55, height: 58)
                
                Spacer()
                lottieTabBarButton(name: "smallVault", tabId: 3, isPlaying: $vaultIsAnimating)
                    .frame(width: 50, height: 50)
                //                tabBarButton(imageName: archiveIsAnimating ? "tray.fill" : "tray", tabId: 3) .offset(y: -1)
                
                Spacer()
                
                lottieTabBarButton(name: "Bell ringing notification", tabId: 4, isPlaying: $notificationsIsAnimating)
                    .frame(width: 50, height: 50)
                //                ZStack {
                //                tabBarButton(imageName: notificationsManager.scheduledNotifications.count > 0
                //                             ? (todoIsAnimating ? "bell.and.waves.left.and.right.fill" : "bell.and.waves.left.and.right")
                //                             : (todoIsAnimating ? "bell.fill" : "bell"), tabId: 4)
                //                    if notificationsManager.scheduledNotifications.count > 0 {
                //
                //                        // custom badge
                //                        Text("\(notificationsManager.scheduledNotifications.count)")
                //                            .font(.caption2)
                //                            .bold()
                //                            .foregroundColor(.white)
                //                            .frame(width: 18, height: 18)
                //                            .background(Color.red)
                //                            .clipShape(Circle())
                //                            .offset(x: 10, y: -10)
                //                    }
                //                }
                Spacer()
            }
            .frame(height: customTabbarHeight) // ! Same as capsule height !
        }
    }
    
    struct VisualEffectBlur: UIViewRepresentable {
        var blurStyle: UIBlurEffect.Style
        var vibrancyStyle: UIVibrancyEffectStyle? = nil
        
        func makeUIView(context: Context) -> UIVisualEffectView {
            let blurView = UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
            if let vibrancyStyle = vibrancyStyle {
                let vibrancyEffect = UIVibrancyEffect(blurEffect: UIBlurEffect(style: blurStyle), style: vibrancyStyle)
                let vibrancyView = UIVisualEffectView(effect: vibrancyEffect)
                vibrancyView.frame = blurView.contentView.bounds
                vibrancyView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                blurView.contentView.addSubview(vibrancyView)
            }
            return blurView
        }
        
        func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
            uiView.effect = UIBlurEffect(style: blurStyle)
        }
    }
    
    private func tabBarButton(imageName: String, tabId: Int) -> some View {
        Button(action: {
            tabSelection = tabId
        }) {
            Image(systemName: imageName)
                .font(.largeTitle)
                .foregroundStyle(tabSelection == tabId ? .white : Color.darkGray2)
        }
    }
    private func lottieTabBarButton(name: String, tabId: Int, isPlaying: Binding<Bool>) -> some View {
        Button(action: {
            tabSelection = tabId
            isPlaying.wrappedValue.toggle()
        }) {
            LottieRepresentable(filename: name, loopMode: .playOnce,speed: 1.2, isPlaying: isPlaying, contentMode: .scaleAspectFit)
                .scaleEffect(tabSelection == tabId ? 1.4 : 1.1)
                .animation(.easeInOut(duration: 0.2), value: tabSelection)
                .shadow(radius:  tabSelection == tabId ? 2 : 0, x: tabSelection == tabId ? 5 : 0, y: tabSelection == tabId ? 5 : 0)
            
        
        }
    }
    
}
