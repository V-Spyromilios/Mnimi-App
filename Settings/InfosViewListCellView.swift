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
    
        VStack(spacing: 8) {
            Text("\(data.metadata["description"] ?? "Empty note.")").font(.subheadline).fontWeight(.semibold).padding(.horizontal)
            HStack {
                Text("\(data.metadata["relevantFor"] ?? "Relevant for?")").font(.footnote).fontWeight(.thin).padding(.leading)
                Spacer()
                Text("\(data.metadata["timestamp"] ?? "No Timestamp.")").font(.footnote).fontWeight(.thin).padding(.trailing)
            }
        }
    }
}

#Preview {
    InfosViewListCellView(data: Vector(id: "2034-1", metadata: ["description": "Charlie likes Pokemon", "relevantFor": "User", "Timestamp": "18-04-2024"]))
}
