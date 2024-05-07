//
//  SwiftUIView.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 01.05.24.
//

import SwiftUI

struct NotificationsListCell: View {

    var notification: CustomNotification
    var body: some View {
        HStack {
        VStack(alignment: .leading, spacing: 8) {
            Text(notification.title).lineLimit(2).truncationMode(.tail).font(.subheadline)
                .fontDesign(.rounded)
                .fontWeight(.semibold).padding(.horizontal).padding(.top, 4)
            HStack {
                Text(notification.notificationBody).lineLimit(1).truncationMode(.tail).font(.footnote).fontWeight(.thin).padding(.leading)
                Spacer()
                if let date = dateFromISO8601(isoDate: notification.date?.description ?? "") {
                    let displayDate = formatDateForDisplay(date: date)
                    Text(displayDate).font(.footnote).fontWeight(.thin).padding(.trailing)
                }
                Spacer()
                
            }.padding(.bottom, 4)
            
        }.foregroundStyle(.black)
            VStack {
                Image(systemName: "chevron.right").padding(.trailing)
            }.foregroundStyle(.blue)
    }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        
        .overlay {
        RoundedRectangle(cornerRadius: 10).stroke(LinearGradient(gradient: Gradient(colors: [.black, .black.opacity(0.7)]), startPoint: .top, endPoint: .bottom), lineWidth: 1)
        }
    }
}

#Preview {
    NotificationsListCell(notification: CustomNotification(id: "A22-C", title: "Demo", notificationBody: "nice notification!"))
}
