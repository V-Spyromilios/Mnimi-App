//
//  InfosViewListCellView.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 09.04.24.
//

import SwiftUI

struct InfosViewListCellView: View {
    
    let data: Vector
    
    var body: some View {
        HStack {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(data.metadata["description"] ?? "Empty note.")").lineLimit(2).truncationMode(.tail).font(.subheadline).fontWeight(.semibold).padding(.horizontal).padding(.top, 4)
            HStack {
                Text("\(data.metadata["relevantFor"] ?? "Relevant for?")").lineLimit(1).truncationMode(.tail).font(.footnote).fontWeight(.thin).padding(.leading)
                Spacer()
                if let date = dateFromISO8601(isoDate: data.metadata["timestamp"] ?? "") {
                    let displayDate = formatDateForDisplay(date: date)
                    Text(displayDate).font(.footnote).fontWeight(.thin).padding(.trailing)
                }
                Spacer()
                
            }.padding(.bottom, 4)
            
        }.foregroundStyle(.black)
            VStack {
                Image(systemName: "chevron.right").padding(.trailing)
            }.foregroundStyle(.blue)
    }.overlay {
        RoundedRectangle(cornerRadius: 10).stroke(LinearGradient(gradient: Gradient(colors: [.black, .black.opacity(0.7)]), startPoint: .top, endPoint: .bottom), lineWidth: 1)
        }
//            .background {
//                LinearGradient(gradient: Gradient(colors: [.blue.opacity(0.8), .blue.opacity(0.5)]), startPoint: .top, endPoint: .bottom)
//            }
    }
}


#Preview {
    InfosViewListCellView(data: Vector(id: "2034-1", metadata: ["description": "Charlie likes Pokemon, Charlie likes Pokemon, Charlie likes Pokemon, Charlie likes Pokemon, Charlie likes Pokemon, Charlie likes Pokemon, Charlie likes Pokemon, Charlie likes Pokemon,", "relevantFor": "User1 ithe main user in this app, and this is a long line", "timestamp": "2024-04-28T14:28:00Z"]))
}
