//
//  SwiftUIView.swift
//  Memory
//
//  Created by Evangelos Spyromilios on 26.02.24.
//

import SwiftUI

//struct ResponseDetailView: View {
//    
//    let response: ResponseModel
//    let dateFormatter = DateFormatter()
//    
//    init(response: ResponseModel) {
//        self.response = response
//        dateFormatter.dateStyle = .medium
//        dateFormatter.timeStyle = .short
//        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
//    }
//    // AudioManager.shared.playAudioFrom(url: response.recordingPath)
//    var body: some View {
//        HStack {
//            VStack(alignment: .leading) {
//                //THIS IS NOT DETAIL> PUT the button in toolbar (check the AskView)and here put all the details of the Model and also put Delete button that will also handle the Pinecone (check how to delete on Pinecone)
//                let dateString = dateFormatter.string(from: response.timestamp)
//                Text(dateString).bold().padding(.bottom, 8)
//                Text(response.desc).font(.footnote).italic()
//                
//            }.padding(.trailing)
//            VStack {
//                Button("", systemImage: "play.circle.fill") {
//                    AudioManager.shared.playAudioFrom(url: response.recordingPath)
//                }.foregroundStyle(.yellow)
//                
//            }
//        }.padding()
//    }
//}

//#Preview {
//    ResponseDetailView(response: ResponseModel(timestamp: Date(), id: UUID(), type: "Question", desc: "The full Description here"))
//}
