//
//  ToDoView.swift
//  Memory
//
//  Created by Evangelos Spyromilios on 12.02.24.
//

import SwiftUI
import UserNotifications

struct NotificationsView: View {
    let screenWidth = UIScreen.main.bounds.width
    let screenHeight = UIScreen.main.bounds.height
    
    @EnvironmentObject var manager: NotificationViewModel
    @EnvironmentObject var openAi: OpenAIManager
    @Environment(\.colorScheme) var colorScheme
    @State private var showAddNotification: Bool = false
    @State var isLoadingSummary: Bool = false
    @State var selectedNotification: CustomNotification?
    @State private var selectedOption: viewOptions = .Notifications
    
    
    enum viewOptions: String, CaseIterable, Identifiable {
        case Notifications = "Notifications"
        case Summary = "Summary"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                VStack {
                    Picker("", selection: $selectedOption) {
                        ForEach(viewOptions.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                }.shadow(radius: 8)
                
                if selectedOption == .Summary {
                    if isLoadingSummary {
                        VStack {
                            Spacer()
                            
                            HStack {
                                ProgressView()
                                    .font(.title)
                                    .scaleEffect(1.5)
                                    .bold()
                                    .background(Color.clear.ignoresSafeArea())
                            }
                            Spacer()
                        }
                    }
                    
                    else if !manager.scheduledNotifications.isEmpty && openAi.notificationsSummary != "" {
                        ScrollView {
                            Text(openAi.notificationsSummary)
                                .fontDesign(.rounded)
                                .padding()
                                .multilineTextAlignment(.leading)
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
                                .padding(.horizontal, 7)
                                .padding(.vertical, 9)
                        } .background(Color.primaryBackground.ignoresSafeArea())
                    }
                } else if selectedOption == .Notifications {
                    ScrollView {
                        ForEach(manager.scheduledNotifications.indices, id: \.self) { index in
                            let notification = manager.scheduledNotifications[index]
                            
                            NotificationCellView(notification: notification)
                                .padding(.vertical)
                                .padding(.horizontal, 9)
                        }
                    }
                }
            }.background { Color.primaryBackground.ignoresSafeArea() }
            
                .navigationTitle("Notifications 🔔")
                .navigationBarTitleDisplayMode(.inline)
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
        }
    }
}

struct NotificationsView_Previews: PreviewProvider {
    static var previews: some View {
        
        let manager = NotificationViewModel()
        return NotificationsView()
            .environmentObject(manager)
    }
}


