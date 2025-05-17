//
//  VectorEntity.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 17.05.25.
//

import Foundation
import SwiftData

@Model
final class VectorEntity {
    @Attribute(.unique) var id: String
    var descriptionText: String
    var timestamp: String

    init(id: String, descriptionText: String, timestamp: String) {
        self.id = id
        self.descriptionText = descriptionText
        self.timestamp = timestamp
    }

    var toVector: Vector {
        .init(id: id, metadata: [
            "description": descriptionText,
            "timestamp": timestamp
        ])
    }

    static func fromVector(_ vector: Vector) -> VectorEntity {
        VectorEntity(
            id: vector.id,
            descriptionText: vector.metadata["description"] ?? "",
            timestamp: vector.metadata["timestamp"] ?? ""
        )
    }
}
