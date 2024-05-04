//
//  NotificationDetailView.swift
//  Memory
//
//  Created by Evangelos Spyromilios on 28.02.24.
//

import SwiftUI

struct NotificationDetailView: View {
    
    var notification: CustomNotification
    @State private var showNotificationEdit: Bool = false
    
    var body: some View {

        ScrollView {
            VStack(alignment: .leading) {
                Text(notification.date?.description ?? "default").font(.title2).fontDesign(.rounded).padding(.bottom, 20)
                Text(notification.title).font(.headline).padding(.bottom)
                Text(notification.body).italic().padding(.bottom)
                Text(notification.id)
            }.padding(.vertical).toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edit") { showNotificationEdit = true }
                }
            }.sheet(isPresented: $showNotificationEdit) {
                NotificationEditView(notification: notification)
            }
        }
    }
}

#Preview {
    NotificationDetailView(notification: CustomNotification(id: "2dgev-fj4j2", title: "Custom Notification", body: "Remind me tomorrow to watch Star Wars", date: Date()))
}
