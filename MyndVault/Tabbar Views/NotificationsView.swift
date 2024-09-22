////
////  ToDoView.swift
////  Memory
////
////  Created by Evangelos Spyromilios on 12.02.24.
////
//
//import SwiftUI
//import UserNotifications
//
//
//struct NotificationsView: View {
//    let screenWidth = UIScreen.main.bounds.width
//    let screenHeight = UIScreen.main.bounds.height
//    
//    @EnvironmentObject var manager: NotificationViewModel
//    @EnvironmentObject var openAi: OpenAIManager
//    @EnvironmentObject var networkManager: NetworkManager
//    @Environment(\.colorScheme) var colorScheme
//    @EnvironmentObject var apiCalls: ApiCallViewModel
//
//    @State private var showAddNotification: Bool = false
//    @State var isLoadingSummary: Bool = false
//    @State private var errorMessage: String = ""
//    @State private var showNoInternet = false
//    @State var selectedNotification: CustomNotification?
//    @State private var selectedOption: ViewOptions = .notifications
//    @State private var showEmpty: Bool = false
//    @State private var plusIsAnimating: Bool = false
//    @State private var emptyIsAnimating: Bool = false
//    @State private var showError: Bool = false
//    @State private var hasBeenEdited: Bool = false
//    
//    
//    enum ViewOptions: String, CaseIterable, Identifiable {
//        case notifications = "Notifications"
//        case monthAhead = "Month Ahead"
//        
//        var id: String { self.rawValue }
//        
//        var localizedName: String {
//            switch self {
//            case .notifications:
//                return NSLocalizedString("Notifications", comment: "")
//            case .monthAhead:
//                return NSLocalizedString("Month Ahead", comment: "")
//            }
//        }
//    }
//
//    var body: some View {
//        NavigationStack {
//            VStack {
//                VStack {
//                    Picker("", selection: $selectedOption) {
//                        ForEach(ViewOptions.allCases) { option in
//                            Text(option.localizedName).tag(option)
//                        }
//                    }
//                    .pickerStyle(SegmentedPickerStyle())
//                    .padding()
//                }
//                .shadow(radius: 8)
//                
//                GeometryReader { geometry in
//                    VStack {
//                        if selectedOption == .monthAhead {
//                            VStack {
//                                
//                                if isLoadingSummary {
//                                    VStack {
//                                        Spacer()
//                                        ProgressView()
//                                            .font(.title)
//                                            .scaleEffect(1.5)
//                                            .bold()
//                                            .background(Color.clear.ignoresSafeArea())
//                                        Spacer()
//                                    }
//                                } else if !manager.scheduledNotifications.isEmpty && !openAi.notificationsSummary.isEmpty {
//                                    ScrollView {
//                                        Text(openAi.notificationsSummary)
//                                            .fontDesign(.rounded)
//                                            .padding()
//                                            .multilineTextAlignment(.leading)
//                                            .background(
//                                                RoundedRectangle(cornerRadius: 10)
//                                                    .stroke(lineWidth: 1)
//                                                    .opacity(colorScheme == .light ? 0.3 : 0.7)
//                                                    .foregroundColor(Color.gray)
//                                            )
//                                            .background(
//                                                RoundedRectangle(cornerRadius: 10)
//                                                    .fill(Color.cardBackground)
//                                                    .shadow(color: Color.customShadow, radius: colorScheme == .light ? 5 : 3, x: 0, y: 0)
//                                            )
//                                            .padding(.horizontal, Constants.standardCardPadding)
//                                            .padding(.vertical, 9)
//                                    }
//                                }
//                            }.frame(maxWidth: .infinity, maxHeight: screenWidth)
//                            
//                            .overlay {
//                                if showError {
//                                    ErrorView(thrownError: errorMessage, dismissAction: clearError)
//                                        
//                                        .transition(AnyTransition.slide)
//                                        .zIndex(1)
//                                }
//                            }
//                            
//                            
//                        } else if selectedOption == .notifications && !manager.scheduledNotifications.isEmpty {
//                            ScrollView {
//                                ForEach(manager.scheduledNotifications.indices, id: \.self) { index in
//                                    let notification = manager.scheduledNotifications[index]
//                                    NotificationCellView(notification: notification, edited: $hasBeenEdited)
//                                        .padding(.vertical)
//                                        .padding(.horizontal, Constants.standardCardPadding)
//                                        .id(UUID())
//                                }
//                            }
//                        }
//                        
//                        if !isLoadingSummary && manager.scheduledNotifications.isEmpty && showEmpty {
//                            VStack {
//                                LottieRepresentable(filename: "noNotifications", loopMode: .playOnce, isPlaying: $emptyIsAnimating)
//                                    .frame(height: 300)
//                                TypingTextView(fullText: "All quiet for now!\nScheduled Notifications will appear here")
//                                    .shadow(radius: 1)
//                                    .frame(width: screenWidth)
//                                    .padding(.horizontal)
//                                Spacer()
//                            }
//                        }
//                    }
//                    .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
//                    
//                }
//            }
//            .background {
//                LottieRepresentable(filename: "Gradient Background", loopMode: .loop, speed: Constants.backgroundSpeed, contentMode: .scaleAspectFill)
//                    .opacity(0.4)
//                    .frame(maxWidth: .infinity, maxHeight: .infinity)
//                    .ignoresSafeArea()
//            }
//            .navigationBarTitleView {
//                HStack {
//                    Text("Notifications")
//                        .font(.title2)
//                        .bold()
//                        .foregroundStyle(.blue.opacity(0.7))
//                        .fontDesign(.rounded)
//                        .padding(.trailing, 6)
//                    LottieRepresentableNavigation(filename: "Bell ringing notification")
//                        .frame(width: 55, height: 55)
//                        .padding(.bottom, 5)
//                        .shadow(color: colorScheme == .dark ? .white : .clear, radius: colorScheme == .dark ? 4 : 0)
//                }
//            }
//            .statusBar(hidden: true)
//            .toolbar {
//                ToolbarItemGroup(placement: .navigationBarTrailing) {
//                    Button {
//                        withAnimation {
//                            showAddNotification.toggle()
//                        }
//                    } label: {
//                        LottieRepresentable(filename: "Add", loopMode: showEmpty == true && manager.scheduledNotifications.isEmpty ? .loop : .playOnce, speed: 0.5)
//                            .frame(width: 45, height: 45)
//                            .padding(.bottom, 5)
//                            .shadow(color: colorScheme == .dark ? .white : .clear, radius: colorScheme == .dark ? 4 : 0)
//                            .opacity(0.8)
//                    }
//                    .padding()
//                    .accessibilityLabel("Add new notification")
//                }
//            }
//            .fullScreenCover(isPresented: $showAddNotification) {
//                AddNotificationView(show : $showAddNotification)
//            }
//            .onChange(of: manager.scheduledNotifications) {
//                if manager.scheduledNotifications.isEmpty {
//                    showEmpty = true
//                    emptyIsAnimating = true
//                } else {
//                    emptyIsAnimating = false
//                    Task { await getSummary() }
//                }
//            }
//            .onChange(of: hasBeenEdited) { _, edited in
//                if edited {
//                    manager.refreshNotifications()
//                    hasBeenEdited = false
//                }
//            }
//            .onChange(of: networkManager.hasInternet) { _, hasInternet in
//                if !hasInternet {
//                    showNoInternet = true
//                }
//            }
//            .onAppear {
//                if manager.scheduledNotifications.isEmpty {
//                    showEmpty = true
//                    emptyIsAnimating = true
//                } else if openAi.notificationsSummary.isEmpty {
//                    emptyIsAnimating = false
//                    Task { await getSummary() }
//                }
//            }
//            .alert(isPresented: $showNoInternet) {
//                Alert(
//                    title: Text("You are not connected to the Internet"),
//                    message: Text("Please check your connection"),
//                    dismissButton: .cancel(Text("OK"))
//                )
//            }
//        }
//    }
//    
//    private func clearError() {
//        withAnimation {
//            self.errorMessage = ""
//            showError = false
//            Task {
//                await openAi.clearManager()
//            }
//        }
//    }
//    
//    private func getSummary() async {
//        await MainActor.run { isLoadingSummary = true }
//        do {
//            try await openAi.getMonthlySummary(notifications: manager.scheduledNotifications)
//            apiCalls.incrementApiCallCount()
//            await MainActor.run { isLoadingSummary = false }
//        } 
//        catch let error as AppNetworkError {
//            await MainActor.run {
//                isLoadingSummary = false
//                self.errorMessage = error.errorDescription
//                showError = true
//            }
//        } catch let error as AppCKError {
//            await MainActor.run {
//                self.errorMessage = error.errorDescription
//                isLoadingSummary = false
//                showError = true
//            }
//        } catch(let error) {
//            await MainActor.run {
//                self.errorMessage = error.localizedDescription
//                isLoadingSummary = false
//                showError = true
//            }
//        }
//    }
//}
//
//struct NotificationsView_Previews: PreviewProvider {
//    static var previews: some View {
//        
//        let manager = NotificationViewModel()
//        return NotificationsView()
//            .environmentObject(manager)
//    }
//}
//
//
