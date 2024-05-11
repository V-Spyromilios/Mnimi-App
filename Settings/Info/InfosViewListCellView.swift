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
            Text("\(data.metadata["description"] ?? "Empty note.")").lineLimit(2).truncationMode(.tail).font(.subheadline)
                .fontDesign(.rounded)
                .fontWeight(.semibold).padding(.horizontal).padding(.top, 4).padding(.bottom)
            HStack {
                
                if let date = dateFromISO8601(isoDate: data.metadata["timestamp"] ?? "") {
                    let displayDate = formatDateForDisplay(date: date)
                    Text(displayDate).italic().font(.footnote).fontWeight(.thin).padding(.horizontal).foregroundStyle(.secondary)
                } else { Text("Date?")}
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
    InfosViewListCellView(data: Vector(id: "2034-1", metadata: ["description": "Charlie likes Pokemon, Charlie likes Pokemon, Charlie likes Pokemon, Charlie likes Pokemon, Charlie likes Pokemon, Charlie likes Pokemon, Charlie likes Pokemon, Charlie likes Pokemon,", "timestamp": "2024-04-28T14:28:00Z"]))
}
