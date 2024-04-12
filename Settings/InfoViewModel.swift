//
//  InfoViewModel.swift
//  Memory
//
//  Created by Evangelos Spyromilios on 18.03.24.
//

import Foundation
import SwiftUI

class EditInfoViewModel: ObservableObject {

    @Published var showConfirmation: Bool = false
    @Published var showTopBar: Bool = false

    @Published var id: String
    @Published var timestamp: String
    @Published var relevantFor: String
    @Published var description: String

    init(vector: Vector) {
        self.id = vector.id
        self.timestamp = vector.metadata["timestamp"] ?? ""
        self.relevantFor = vector.metadata["relevantFor"] ?? ""
        self.description = vector.metadata["description"] ?? ""
    }

}
