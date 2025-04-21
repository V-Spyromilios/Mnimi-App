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

enum senderView {
    case editInfo, KView
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

    @Published var pineconeErrorFromEdit: PineconeError?
    @Published var pineconeErrorFromAdd: PineconeError?
    @Published var pineconeErrorFromQ: PineconeError?
    @Published var pineconeErrorOnDel: PineconeError?
    @Published var pineconeQueryResponse: PineconeQueryResponse?
    @Published var vectorDeleted: Bool = false
    @Published var accountDeleted: Bool = false
    @Published var pineconeIDResponse: PineconeIDResponse?
    @Published var pineconeIDs: [String] = []
    @Published var pineconeFetchedVectors: [Vector] = []
    @Published var upsertSuccessful: Bool = false
    
    let pineconeActor: PineconeActor
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
    
    func clearManager() {
        self.pineconeErrorFromAdd = nil
        self.pineconeErrorFromEdit = nil
        self.pineconeErrorFromQ = nil
        self.pineconeQueryResponse = nil
        self.upsertSuccessful = false
    }
    
    func deleteVector(withId id: String) {
        print("deleteVector called")
        self.pineconeFetchedVectors.removeAll { $0.id == id }
    }
    
//    func updateUpsertSuccessful(_ success: Bool) {
//        self.upsertSuccessful = success
//    }
    

    //MARK: - Methods for the Views
    func refreshNamespacesIDs() {
        Task {
            do {
                let vectors = try await pineconeActor.refreshNamespacesIDs()
                DispatchQueue.main.async {
                    self.pineconeFetchedVectors = vectors
                }
            } catch DecodingError.keyNotFound(let key, _) where key.stringValue == "usage" || key.stringValue == "vectors" {
                // For the new user or deleted all info to avoid show the ErrorView
                DispatchQueue.main.async {
                    self.pineconeFetchedVectors = []
                    self.pineconeErrorFromQ = nil
                    self.pineconeErrorFromEdit = nil
                    self.pineconeErrorFromAdd = nil
                }
            } catch {
                self.pineconeErrorFromAdd = .refreshFailed(error)
                debugLog("from refreshNamespacesIDs: \(error) - \( error.localizedDescription)")
            }
        }
    }
    
    @MainActor
    func upsertData(id: String, vector: [Float], metadata: [String: Any], from sender: senderView) {
#if DEBUG
        print("upsertData called")
#endif
        Task {
            do {
                try await pineconeActor.upsertDataToPinecone(id: id, vector: vector, metadata: metadata)
                await MainActor.run {
                    if sender == .editInfo {
                        self.upsertSuccessful = true
                        
                    } else if sender == .KView {
                        debugLog("Upsert successful from KView")
                        self.upsertSuccessful = true
                    }
                }
                debugLog("upsertSuccess: \(self.upsertSuccessful)")
            } catch {
                await MainActor.run {
                    debugLog("from upsertData() Error: \(error.localizedDescription)")
                    self.upsertSuccessful = false
                    if sender == .editInfo {
                        self.pineconeErrorFromEdit = .upsertFailed(error)
                    }
                    else if sender == .KView {
                        self.pineconeErrorFromAdd = .upsertFailed(error)
                    }
                }
            }
        }
    }
    
    func deleteVectorFromPinecone(id: String) async {
        debugLog("deleteVectorFromPinecone CALLED") //NO task here the EditInfoView.deleteInfo has spawn Task!
            do {
                try await pineconeActor.deleteVectorFromPinecone(id: id)
                await MainActor.run {
                    self.vectorDeleted = true
                }
            } catch {

                self.pineconeErrorOnDel = .deleteFailed(error)
            }
        
    }
    
    func deleteAllVectorsInNamespace() async {

            do {
                try await pineconeActor.deleteAllVectorsInNamespace()
                self.accountDeleted = true
                self.pineconeFetchedVectors = []
                self.pineconeIDs = []
            } catch {
                self.pineconeErrorOnDel = .deleteFailed(error)
            }
        
    }
  
    
    func queryPinecone(vector: [Float], topK: Int = 1, includeValues: Bool = false) {
        debugLog("queryPinecone CALLED")
        Task {
            do {
                let response = try await pineconeActor.queryPinecone(vector: vector, topK: topK, includeValues: includeValues)
                self.pineconeQueryResponse = response
            } catch {
                self.pineconeErrorFromQ = .queryFailed(error)
            }
        }
    }
    
}
