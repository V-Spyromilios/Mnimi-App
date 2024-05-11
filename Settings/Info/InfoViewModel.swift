//
//  InfoViewModel.swift
//  Memory
//
//  Created by Evangelos Spyromilios on 18.03.24.
//

import Foundation
import SwiftUI

final class EditInfoViewModel: ObservableObject {

    enum ActiveAlert: Identifiable {

        case editConfirmation, deleteWarning
        var id: Self { self }
    }

    @Published var activeAlert: ActiveAlert?

    @Published var id: String
    @Published var timestamp: String
    @Published var description: String

    init(vector: Vector) {
        self.timestamp = vector.metadata["timestamp"] ?? ""
        self.description = vector.metadata["description"] ?? ""
        self.id = vector.id
    }

}
