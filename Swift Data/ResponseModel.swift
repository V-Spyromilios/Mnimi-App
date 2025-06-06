//
//  RecordingModel.swift
//  Memory
//
//  Created by Evangelos Spyromilios on 05.02.24.
//

import Foundation
import SwiftData

@Model
final class ResponseModel {
    var timestamp: Date = Date()
    var id: UUID = UUID()
    var type: String = ""
    var desc: String = ""
    var relevantFor: String = ""
    
    init(timestamp: Date = Date(), id: UUID = UUID(), type: String = "", desc: String = "", relevantFor: String = "") {
        self.timestamp = timestamp
        self.id = id
        self.type = type
        self.desc = desc
        self.relevantFor = relevantFor
    }
}
