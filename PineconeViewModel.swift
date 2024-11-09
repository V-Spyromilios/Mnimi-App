//
//  PineconeViewModel.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 26.10.24.
//

import Foundation
import SwiftUI
import Combine

enum PineconeError: Error, Identifiable {
    var id: String { localizedDescription }
    
    case upsertFailed(Error)
    case deleteFailed(Error)
    case queryFailed(Error)
    case refreshFailed(Error)
    case unknown(Error)
    
    var localizedDescription: String {
        switch self {
        case .upsertFailed(let error):
            return "Upsert Failed: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Delete Failed: \(error.localizedDescription)"
        case .queryFailed(let error):
            return "Query Failed: \(error.localizedDescription)"
        case .refreshFailed(let error):
            return "Refresh Failed: \(error.localizedDescription)"
        case .unknown(let error):
            return "An unknown error occurred: \(error.localizedDescription)"
        }
    }
}


// MARK: - Equatable
extension PineconeError: Equatable {
    static func == (lhs: PineconeError, rhs: PineconeError) -> Bool {
        return lhs.localizedDescription == rhs.localizedDescription
    }
}

// MARK: - Hashable
extension PineconeError: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(localizedDescription)
    }
}

@MainActor
class PineconeViewModel: ObservableObject {
    
    @Published var pineconeError: PineconeError?
    @Published var indexInfo: String?
    @Published var pineconeQueryResponse: PineconeQueryResponse?
    @Published var upsertSuccesful: Bool = false
    @Published var vectorDeleted: Bool = false
    @Published var accountDeleted: Bool = false
    @Published var pineconeIDResponse: PineconeIDResponse?
    @Published var pineconeIDs: [String] = []
    @Published var pineconeFetchedResponseFromID: PineconeFetchResponseFromID?
    @Published var pineconeFetchedVectors: [Vector] = []
    @Published var refreshAfterEditing: Bool = false
    @Published var isDataSorted: Bool = false
    @Published var upsertSuccessful: Bool = false
    
    private let pineconeActor: PineconeActor
    private let CKviewModel: CloudKitViewModel
    var cancellables = Set<AnyCancellable>()
    
    init(pineconeActor: PineconeActor, CKviewModel: CloudKitViewModel) {
        self.pineconeActor = pineconeActor
        self.CKviewModel = CKviewModel
        self.updateAccountDeletedFromUserDefaults()
    }
    
    func updateAccountDeletedFromUserDefaults() {
        self.accountDeleted = UserDefaults.standard.bool(forKey: "accountDeleted")
        
        // Observe changes to accountDeleted and insert cancellable
        let cancellable = self.$accountDeleted
            .sink { newValue in
                UserDefaults.standard.set(newValue, forKey: "accountDeleted")
            }
        self.cancellables.insert(cancellable)
    }
    
    func resetAfterSuccessfulUpserting() {
        self.isDataSorted = false
        self.refreshAfterEditing = true
    }
    
    func clearManager() {
        self.pineconeError = nil
        self.pineconeQueryResponse = nil
        self.upsertSuccesful = false
    }
    
    func deleteVector(withId id: String) {
        self.pineconeFetchedVectors.removeAll { $0.id == id }
    }
    
    // MARK: - Methods to Update Properties
    
    func updateUpsertSuccessful(_ success: Bool) {
        self.upsertSuccesful = success
    }
    
    func updateVectorDeleted(_ deleted: Bool) {
        self.vectorDeleted = deleted
    }
    
    func updatePineconeIDResponse(_ response: PineconeIDResponse) {
        self.pineconeIDResponse = response
    }
    
    func appendPineconeIDs(_ ids: [String]) {
        self.pineconeIDs.append(contentsOf: ids)
    }
    
    func updatePineconeFetchedVectors(_ vectors: [Vector]) {
        self.pineconeFetchedVectors = vectors
    }
    
    func setIsDataSorted(_ sorted: Bool) {
        self.isDataSorted = sorted
    }
    
    func setRefreshAfterEditing(_ refresh: Bool) {
        self.refreshAfterEditing = refresh
    }
    
    func updateAccountDeleted(_ deleted: Bool) {
        self.accountDeleted = deleted
    }
    
    func updatePineconeQueryResponse(_ response: PineconeQueryResponse) {
        self.pineconeQueryResponse = response
    }
    
    func removeAllPinconeIDs() {
        self.pineconeIDs.removeAll()
    }
    
    //MARK: - Methods for the Views
    func refreshNamespacesIDs() {
        Task {
            do {
                let vectors = try await pineconeActor.refreshNamespacesIDs()
                self.pineconeFetchedVectors = vectors
            } catch {
                self.pineconeError = .refreshFailed(error)
            }
        }
    }
    
    func upsertData(id: String, vector: [Float], metadata: [String: Any]) {
        Task {
            do {
                try await pineconeActor.upsertDataToPinecone(id: id, vector: vector, metadata: metadata)
                self.upsertSuccessful = true
            } catch {
                self.pineconeError = .upsertFailed(error)
            }
        }
    }
    
    func deleteVectorFromPinecone(id: String) {
        Task {
            do {
                try await pineconeActor.deleteVectorFromPinecone(id: id)
                self.vectorDeleted = true
            } catch {
                self.pineconeError = .deleteFailed(error)
            }
        }
    }
    
    func deleteAllVectorsInNamespace() {
        Task {
            do {
                try await pineconeActor.deleteAllVectorsInNamespace()
                self.accountDeleted = true
                self.refreshAfterEditing = true
                self.pineconeFetchedVectors = []
                self.pineconeIDs = []
            } catch {
                self.pineconeError = .deleteFailed(error)
            }
        }
    }
    
    func queryPinecone(vector: [Float], topK: Int = 1, includeValues: Bool = false) {
        Task {
            do {
                let response = try await pineconeActor.queryPinecone(vector: vector, topK: topK, includeValues: includeValues)
                self.pineconeQueryResponse = response
            } catch {
                self.pineconeError = .queryFailed(error)
            }
        }
    }

}
