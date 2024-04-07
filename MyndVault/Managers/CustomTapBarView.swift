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
    @Namespace private var animation
    
    // State variables for animation
    @State private var gearIsAnimating: Bool = false
    @State private var quoteIsAnimating: Bool = true
    @State private var listIsAnimating: Bool = false
    var yellowGradient = LinearGradient(gradient: Gradient(colors: [Color.yellow.opacity(0.3),Color.orange.opacity(0.3), Color.orange.opacity(0.6), Color.orange.opacity(0.8),Color.orange, Color.yellow.opacity(0.4)]), startPoint: .top, endPoint: .bottom)
   
    
    var body: some View {
        ZStack {
            Capsule()
                .foregroundStyle(yellowGradient)
                .frame(height: 70)

            HStack(alignment: .bottom) {

                // quote.bubble Button
                tabBarButton(imageName: quoteIsAnimating ? "quote.bubble.fill" : "quote.bubble", tabId: 1, isAnimating: $quoteIsAnimating).padding(.leading)

                ZStack {
                tabBarButton(imageName: listIsAnimating ? "list.clipboard.fill": "list.clipboard", tabId: 2, isAnimating: $listIsAnimating, notificationsCount: notificationsManager.scheduledNotifications.count).padding(.horizontal)
                    if notificationsManager.scheduledNotifications.count > 0 {
                        
                        // custom badge implementation
                        Text("\(notificationsManager.scheduledNotifications.count)")
                            .font(.caption2)
                            .bold()
                            .foregroundColor(.white)
                            .frame(width: 18, height: 18)
                            .background(Color.red)
                            .clipShape(Circle())
                        
                            .offset(x: 10, y: -10)
                    }
                }
                // Gear Button
                tabBarButton(imageName: gearIsAnimating ? "gearshape.2.fill" : "gearshape.2", tabId: 3, isAnimating: $gearIsAnimating, isGear: true).padding(.trailing)
            }
            .frame(height: 70) // Same as capsule height
        }
    }
    
    private func tabBarButton(imageName: String, tabId: Int, isAnimating: Binding<Bool>, isGear: Bool = false, notificationsCount: Int = 0) -> some View {

            Button(action: {
                withAnimation {
                    tabSelection = tabId
                }
                toggleAnimation(for: tabId - 1)
            }) {
                Image(systemName: imageName)
                                   .font(.title)
                                   .foregroundStyle(.white)
                                   .padding(.horizontal)
            }
            //                if tabSelection == tabId {
            //                    Capsule()
            //                        .frame(height: 8)
            //                        .offset(y: 7)
            //                        .foregroundStyle(.white)
            //                        .matchedGeometryEffect(id: "SelectedTabId", in: animation)
            //                        .clipped()
            //                } else {
            //                    Capsule()
            //                        .frame(height: 8)
            //                        .foregroundStyle(.clear)
            //                        .offset(y: 7)
            //                        .clipped()
            //                }

    }
    
    private func toggleAnimation(for index: Int) {

        gearIsAnimating = false
        listIsAnimating = false
        quoteIsAnimating = false

//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            switch index + 1 {
            case 1:
                quoteIsAnimating = true
            case 2:
                listIsAnimating = true
            case 3:
                gearIsAnimating = true

            default: break
            }
//        }
    }
}
