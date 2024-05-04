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
    @State private var plusIsAnimating: Bool = false
    @State private var archiveIsAnimating: Bool = false
    @State private var todoIsAnimating: Bool = false

    var yellowGradient = LinearGradient(gradient: Gradient(colors: [Color.yellow.opacity(0.3),Color.orange.opacity(0.3), Color.orange.opacity(0.6), Color.orange.opacity(0.8),Color.orange, Color.yellow.opacity(0.4)]), startPoint: .top, endPoint: .bottom)
    
    var brGreenGradient = LinearGradient(gradient: Gradient(colors: [Color.britishRacingGreen.opacity(0.5),Color.britishRacingGreen.opacity(0.8), Color.britishRacingGreen]), startPoint: .top, endPoint: .bottom)
    
    var body: some View {
        ZStack {
            Capsule()
                .foregroundStyle(brGreenGradient)
                .frame(height: 70)
                .shadow(radius: 8)

            HStack(alignment: .bottom, spacing: 45) {
                
                tabBarButton(imageName: questionIsAnimating ? "questionmark.bubble.fill" : "questionmark.bubble", tabId: 1).padding(.leading)
                
                tabBarButton(imageName: plusIsAnimating ? "plus.bubble.fill" : "plus.bubble", tabId: 2)
                
                tabBarButton(imageName: archiveIsAnimating ? "archivebox.fill" : "archivebox", tabId: 3)

                ZStack {
                tabBarButton(imageName: notificationsManager.scheduledNotifications.count > 0
                             ? (todoIsAnimating ? "bell.and.waves.left.and.right.fill" : "bell.and.waves.left.and.right")
                             : (todoIsAnimating ? "bell.fill" : "bell"), tabId: 4).padding(.horizontal)
                    if notificationsManager.scheduledNotifications.count > 0 {
                        
                        // custom badge
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
            }
            .frame(height: 70) // Same as capsule height
        }
    }
    
    private func tabBarButton(imageName: String, tabId: Int) -> some View {
        Button(action: {
                tabSelection = tabId
        }) {
            Image(systemName: imageName)
                .font(.largeTitle)
                .foregroundStyle(tabSelection == tabId ? .white : .white.opacity(0.6))
        }
    }

}
