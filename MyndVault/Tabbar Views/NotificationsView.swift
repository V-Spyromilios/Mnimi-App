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
    @EnvironmentObject var networkManager: NetworkManager
    @Environment(\.colorScheme) var colorScheme
    @State private var showAddNotification: Bool = false
    @State var isLoadingSummary: Bool = false
    @State private var errorMessage: String = ""
    @State private var showNoInternet = false
    @State var selectedNotification: CustomNotification?
    @State private var selectedOption: viewOptions = .Notifications
    @State private var showEmpty: Bool = false
    @State private var plusIsAnimating: Bool = false
    @State private var emptyIsAnimating: Bool = false
    @State private var showError: Bool = false
    
    
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
                }
                .shadow(radius: 8)
                
                GeometryReader { geometry in
                    VStack {
                        if selectedOption == .Summary {
                            if isLoadingSummary && errorMessage.isEmpty {
                                VStack {
                                    Spacer()
                                    ProgressView()
                                        .font(.title)
                                        .scaleEffect(1.5)
                                        .bold()
                                        .background(Color.clear.ignoresSafeArea())
                                    // .foregroundStyle(Color.customLightBlue)
                                    Spacer()
                                }
                            } else if !manager.scheduledNotifications.isEmpty && !openAi.notificationsSummary.isEmpty {
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
                                        .padding(.horizontal, standardCardPadding)
                                        .padding(.vertical, 9)
                                }.refreshable {
                                    if !errorMessage.isEmpty {
                                        errorMessage = ""
                                    }
                                    await getSummary()
                                }
                                
                            } 
                            //TODO: Delete this we call .overlay
//                            else if !errorMessage.isEmpty {
//                                ScrollView {
//                                    VStack {
//                                        ErrorView(thrownError: errorMessage, extraMessage: "Scroll down to try again!")
//                                            .padding(.horizontal, standardCardPadding)
//                                            .padding(.top, 9)
//                                        Spacer()
//                                    }
//                                }
//                                
//                            }
                        } else if selectedOption == .Notifications && !manager.scheduledNotifications.isEmpty  {
                            ScrollView {
                                ForEach(manager.scheduledNotifications.indices, id: \.self) { index in
                                    let notification = manager.scheduledNotifications[index]
                                    
                                    NotificationCellView(notification: notification)
                                        .padding(.vertical)
                                        .padding(.horizontal, standardCardPadding)
                                }
                            }
                        }
                        
                        if !isLoadingSummary && manager.scheduledNotifications.isEmpty && showEmpty {
                            VStack {
                            //TODO: Check if this animation plays only once in view appearance first time, and when the nots become empty
                                LottieRepresentable(filename: "noNotifications", loopMode: .playOnce, isPlaying: $emptyIsAnimating)
                                    .frame(height: 300)
                                TypingTextView(fullText: "All quiet for now!\nScheduled Notifications will appear here")
                                    .frame(width: screenWidth)
                                    .padding(.horizontal)
                             
                                Spacer()
                            }
                        }
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
                }
            }
            .overlay {
                if showError {
                    ErrorView(thrownError: errorMessage) {
                        errorMessage = ""
                        
                    }
                        .transition(AnyTransition(.move(edge: .bottom)))
//                        .transition(AnyTransition(.opacity))
                }
            }
            .background {
                LottieRepresentable(filename: "Gradient Background", loopMode: .loop, speed: backgroundSpeed, contentMode: .scaleAspectFill)
                    .opacity(0.4)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
            }
            .navigationBarTitleView {
                HStack {
                    Text("Notifications").font(.title2).bold().foregroundStyle(.blue.opacity(0.7)).fontDesign(.rounded).padding(.trailing, 6)
                    LottieRepresentableNavigation(filename: "Bell ringing notification").frame(width: 55, height: 55).padding(.bottom, 5).shadow(color: colorScheme == .dark ? .white : .clear, radius: colorScheme == .dark ? 4 : 0) }
            }
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        withAnimation {
                            showAddNotification.toggle()
                        }
                    } label: {
                        LottieRepresentable(filename: "Add",loopMode: showEmpty == true && manager.scheduledNotifications.isEmpty  ? .loop : .playOnce).frame(width: 45, height: 45).padding(.bottom, 5).shadow(color: colorScheme == .dark ? .white : .clear, radius: colorScheme == .dark ? 4 : 0).opacity(0.8)
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
                if manager.scheduledNotifications.isEmpty {
                    showEmpty = true
                    emptyIsAnimating = true
                }
                else {
                    emptyIsAnimating = false
                    Task { await getSummary() }
                }
            }
            .onChange(of: networkManager.hasInternet) { _, hasInternet in
                if !hasInternet {
                    showNoInternet = true
                }
            }
            .onChange(of: errorMessage) { message in
                if message != "" {
                    showError = true
                }
                else { showError = false }
            }
            .onAppear {
                if manager.scheduledNotifications.isEmpty {
                    showEmpty = true
                    emptyIsAnimating = true
                }
                else {
                    emptyIsAnimating = false
                    Task { await getSummary() }
                }
            }
            .alert(isPresented: $showNoInternet) {
                Alert(
                    title: Text("You are not connected to the Internet"),
                    message: Text("Please check your connection"),
                    dismissButton: .cancel(Text("OK"))
                )
            }
        }
    }
    
    private func getSummary() async {
        await MainActor.run { isLoadingSummary = true }
        do {
            throw AppCKError.iCloudAccountNotFound
            try await openAi.getMonthlySummary(notifications: manager.scheduledNotifications)
            await MainActor.run { isLoadingSummary = false }
        } catch let error as AppNetworkError {
            await MainActor.run {
                self.errorMessage = error.errorDescription
            }
        } catch let error as AppCKError {
            await MainActor.run {
                self.errorMessage = error.errorDescription
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
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


