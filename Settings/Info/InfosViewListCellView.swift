//
//  InfosViewListCellView.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 09.04.24.
//

import SwiftUI

struct InfosViewListCellView: View {
    
    let data: Vector
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(data.metadata["description"] ?? "Empty note.")").lineLimit(2).truncationMode(.tail).font(.subheadline)
                .fontDesign(.rounded)
                .fontWeight(.semibold).padding(.horizontal).padding(.top, 4).padding(.bottom)
                .foregroundStyle(.buttonText)
            HStack {
                
                if let date = dateFromISO8601(isoDate: data.metadata["timestamp"] ?? "") {
                    let displayDate = formatDateForDisplay(date: date)
                    Text(displayDate).italic().font(.footnote).fontWeight(.thin).padding(.horizontal).foregroundStyle(colorScheme == .light ? .secondary : Color.gray.opacity(0.9))
                } else { Text("") }
                Spacer()
                
            }.padding(.bottom, 4)
            
        }.background { Color.black }
            VStack {
                Image(systemName: "chevron.right").padding(.trailing)
            }.foregroundStyle(.blue)
                
        }.background { Color.black }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        
        .overlay {
        RoundedRectangle(cornerRadius: 10)
                .stroke(lineWidth: 1)
                .opacity(colorScheme == .light ? 0.3 : 0.7)
                .foregroundColor(colorScheme == .light ? Color.gray : Color.blue)
        }
    }
}


#Preview {
    InfosViewListCellView(data: Vector(id: "2034-1", metadata: ["description": "Charlie likes Pokemon, Charlie likes Pokemon, Charlie likes Pokemon, Charlie likes Pokemon, Charlie likes Pokemon, Charlie likes Pokemon, Charlie likes Pokemon, Charlie likes Pokemon,", "timestamp": "2024-04-28T14:28:00Z"]))
}
