////
////  NotificationCellView.swift
////  Memory
////
////  Created by Evangelos Spyromilios on 28.02.24.
////
//
//import SwiftUI
//
//struct NotificationCellView: View {
//    
//    @Environment(\.colorScheme) var colorScheme
//    @EnvironmentObject var manager: NotificationViewModel
//    @Environment(\.presentationMode) var presentationMode
//    
//    @State private var popUpOptions: [String] = [
//        NSLocalizedString("Delete", comment: "Option to delete an item"),
//        NSLocalizedString("Edit...", comment: "Option to edit an item")
//    ]
//    
//    @State private var showPopover: Bool = false
//    
//    @Binding var edited: Bool
//    var notification: CustomNotification
//    var shadowRadius: CGFloat = 10
//    @StateObject var viewModel: CountdownTimer
//    
//    @State var showAddNotificationSheet = false
//    @State private var showNotificationEdit: Bool = false
//    @State private var showDeleteAlert: Bool = false
//    @State private var isAnimating: Bool = false
//    
//    init(notification: CustomNotification, edited: Binding<Bool>) {
//        self.notification = notification
//        self._edited = edited
//        _viewModel = StateObject(wrappedValue: CountdownTimer(targetDate: notification.date, repeatInterval: notification.repeatInterval ?? .none))
//    }
//    
//    var body: some View {
//        
//        VStack {
//            HStack {
//                Text(notification.title)
//                    .font(.title)
//                    .foregroundStyle(.notificationsTitle)
//                    .fontWeight(.bold)
//                    .fontDesign(.rounded)
//                    .padding(.bottom, 2)
//                    .padding(.top, 5)
//                    .padding(.leading)
//                Spacer()
//            }
//            HStack {
//                Text(notification.notificationBody)
//                    .foregroundStyle(colorScheme == .light ? .black : .white.opacity(0.6))
//                    .italic()
//                    .multilineTextAlignment(.leading)
//                    .lineLimit(nil)
//                    .padding(.bottom, 10)
//                    .padding(.leading)
//                Spacer()
//            }
//            
//            Text(formatDate(notification.date))
//                .font(.title2)
//                .fontDesign(.rounded)
//                .fontWeight(.medium)
//                .foregroundStyle(.secondary)
//                .padding(.bottom)
//            
//            Text(viewModel.timeRemaining)
//                .font(.footnote)
//                .foregroundStyle(.secondary)
//                .contentTransition(.numericText())
//            //                    .padding(.bottom, 18)
//            
//            HStack {
//                HStack {
//                    if notification.repeats {
//                        HStack {
//                            Text(LocalizedStringKey("Repeats:"))
//                            Text(notification.repeatInterval!.description).padding(.leading, 8)
//                        }
//                        .font(.footnote)
//                        .foregroundStyle(.secondary)
//                        .contentTransition(.numericText())
//                        .padding(.bottom, 18)
//                    }
//                    Spacer()
//                    Button(action: {
//                        
//                        showPopover.toggle()
//                        print("Button pressed: \(showPopover)")
//                    }) {
//                        
//                        LottieRepresentable(filename: "Vertical Dot Menu", loopMode: .playOnce, isPlaying: $isAnimating)
//                            .frame(width: 55, height: 55)
//                            .shadow(color: colorScheme == .dark ? .white : .clear, radius: colorScheme == .dark ? 4 : 0)
//                        
//                    }
//                }
//                
//            }
//        }
//        .frame(maxWidth: .infinity)
//        .padding(.top)
//        .background(Color.cardBackground)
//        .cornerRadius(10)
//        .shadow(radius: shadowRadius)
//        
//        .popover(isPresented: $showPopover, attachmentAnchor: .point(.bottom), arrowEdge: .top) {
//            popOverContent()
//        }
//        .sheet(isPresented: $showNotificationEdit) {
//            NotificationEditView(notification: notification, edited: $edited, showEdit: $showNotificationEdit)
//        }
//    }
//    
//    private func formatDate(_ date: Date?) -> String {
//        guard let date = date else { return "No date provided" }
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateStyle = .full
//        dateFormatter.timeStyle = .short
//        return dateFormatter.string(from: date)
//    }
//    
//    
//    private func popOverContent() -> some View {
//        VStack(alignment: .leading, spacing: 7) {
//            ForEach(popUpOptions, id: \.self) { option in
//                Button(action: {
//                    if option == "Delete" {
//                        Task {
//                            manager.deleteNotification(with: notification.id)
//                        }
//                    } else {
//                        self.showNotificationEdit.toggle()
//                    }
//                }) {
//                    if option == popUpOptions.first {
//                        
//                        Text(option).font(.body).foregroundStyle(.red)
//                        
//                    } else {
//                        Text(option).font(.body).foregroundStyle(Color.primary)
//                    }
//                }
//                .padding(.horizontal)
//                .accessibilityLabel(option == "Delete" ? "Delete" : "Edit")
//                
//                if option != popUpOptions.last {
//                    Divider()
//                }
//            }
//        }
//        .presentationCompactAdaptation(.popover)
//    }
//}
//
//struct NotificationCellView_Preview: PreviewProvider {
//    static var previews: some View {
//        NotificationCellView(
//            notification: CustomNotification(
//                id: "ΦΚΔ-2Δ",
//                title: "Sample Notification",
//                notificationBody: "This is a sample notification body text.",
//                
//                date: Date().addingTimeInterval(3600), repeats: true, // 1 hour from now
//                repeatInterval: .weekdays
//            ),
//            edited: .constant(false)
//        )
//        .environmentObject(NotificationViewModel()) // Add necessary environment objects
//        .preferredColorScheme(.dark) // Preview in light mode
//        //        .previewLayout(.sizeThatFits)
//        .padding(.horizontal, Constants.standardCardPadding)
//    }
//}
//
//// _viewModel = StateObject(wrappedValue: CountdownTimer(targetDate: notification.date ?? .now + 2)
