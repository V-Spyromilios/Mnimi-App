//
//  KEditInfoViewModel.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 25.04.25.
//

import Foundation

@MainActor
final class KEditInfoViewModel: ObservableObject {
    @Published var id: String
    @Published var description: String
    @Published var timestamp: String

    init(vector: Vector) {
        self.id = vector.id
        self.description = vector.metadata["description"] ?? "Default desc from init"
        self.timestamp =  dateFromISO8601(isoDate: vector.metadata["timestamp"] ?? "").map { formatDateForDisplay(date: $0) } ?? ""
    }
}

extension KEditInfoViewModel {
    static var empty: KEditInfoViewModel {
        KEditInfoViewModel(vector: Vector(id: "", metadata: [:]))
    }

    func update(with vector: Vector) {
        self.description = vector.metadata["description"] ?? "Default desc from update"
        self.timestamp = dateFromISO8601(isoDate: vector.metadata["timestamp"] ?? "")
            .map { formatDateForDisplay(date: $0) } ?? ""
        self.id = vector.id
    }
}
