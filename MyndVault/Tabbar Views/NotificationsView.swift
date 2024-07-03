//
//  ToDoView.swift
//  Memory
//
//  Created by Evangelos Spyromilios on 12.02.24.
//

import SwiftUI
import UserNotifications


import SwiftUI

struct NotificationsView: View {
    
    @EnvironmentObject var manager: NotificationViewModel
    @EnvironmentObject var openAi: OpenAIManager
    @Environment(\.colorScheme) var colorScheme
    @State private var showAddNotification: Bool = false
    @State var isLoadingSummary: Bool = false
    @State var selectedNotification: CustomNotification?
    
    var body: some View {
        NavigationStack {
            VStack {
                if isLoadingSummary {
                    ProgressView()
                        .background(Color.clear)
                } else {
                    ScrollView {
                        if !manager.scheduledNotifications.isEmpty && openAi.notificationsSummary != "" {
                            Text(openAi.notificationsSummary)
                                .fontDesign(.rounded)
                                .multilineTextAlignment(.leading)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(lineWidth: 1)
                                        .opacity(colorScheme == .light ? 0.3 : 0.7)
                                        .foregroundColor(Color.gray)
                                )
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(colorScheme == .light ? Color.white : Color.black)
                                        .shadow(color: Color.customShadow, radius: colorScheme == .light ? 5 : 3, x: 0, y: 0)
                                )
                                .frame(minHeight: 50)
                                .padding(.top, 12)
                                .padding(.horizontal, 7)
                            
                            LazyVStack(alignment: .leading) {
                                if !manager.scheduledNotifications.isEmpty {
                                    ForEach(manager.scheduledNotifications) { notification in
                                        NotificationCellView(notification: notification)
                                            .padding(.bottom)
                                            .padding(.horizontal, 9)
                                    }
                                } else {
                                    ContentUnavailableView("No Notifications yet!", systemImage: "bell.slash.fill", description: Text("Start by adding a new Notification."))
                                        .offset(y: contentUnaivalableOffset)
                                }
                            }
                            .padding(.top, 14)
                        }
                    }
                    .background(Color.primaryBackground.ignoresSafeArea(edges: .bottom))
                }
            }
            .navigationTitle("Notifications 🔔")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        withAnimation {
                            showAddNotification.toggle()
                        }
                    } label: {
                        Circle()
                            .foregroundStyle(Color.gray.opacity(0.6))
                            .frame(height: 30)
                            .shadow(color: Color.customShadow, radius: toolbarButtonShadow)
                            .overlay {
                                Text("➕")
                            }
                    }
                    .padding()
                    .accessibilityLabel("Add new notification")
                }
            }
            .sheet(isPresented: $showAddNotification) {
                AddNotificationView(dismissAction: {
                    showAddNotification = false
                })
            }
            .onChange(of: manager.scheduledNotifications) {
                print("onChange notifications.")
                isLoadingSummary = true
                Task {
                    do {
                        try await openAi.getMonthlySummary(notifications: manager.scheduledNotifications)
                        await MainActor.run {
                            isLoadingSummary = false
                        }
                    } catch(let error) {
                        print("Error getMonthlySummary caught from the View: \(error.localizedDescription)")
                    }
                }
            }
            .onAppear {
                if openAi.notificationsSummary == "" {
                    isLoadingSummary = true
                    Task {
                        do {
                            try await openAi.getMonthlySummary(notifications: manager.scheduledNotifications)
                            await MainActor.run {
                                isLoadingSummary = false
                            }
                        } catch(let error) {
                            print("Error getMonthlySummary caught from the View: \(error.localizedDescription)")
                        }
                    }
                }
            }
        } .background{ Color.primaryBackground.ignoresSafeArea() }
    }
}

struct NotificationsView_Previews: PreviewProvider {
    static var previews: some View {

        let manager = NotificationViewModel()
        return NotificationsView()
            .environmentObject(manager)
    }
}


