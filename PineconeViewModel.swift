//
//  PineconeViewModel.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 26.10.24.
//

import Foundation
import SwiftUI
import Combine
import SwiftData


enum PineconeError: DisplayableError {
    case upsertFailed(Error)
    case deleteFailed(Error)
    case queryFailed(Error)
    case refreshFailed(Error)
    case networkUnavailable
    case unknown(Error)

    var id: String { message }

    var title: String {
        switch self {
        case .upsertFailed: return "Save Error"
        case .deleteFailed: return "Delete Error"
        case .queryFailed: return "Search Error"
        case .refreshFailed: return "Load Error"
        case .networkUnavailable: return "Connection Lost"
        case .unknown: return "Unexpected Error"
        }
    }

    var message: String {
        switch self {
        case .upsertFailed(let err),
             .deleteFailed(let err),
             .queryFailed(let err),
             .refreshFailed(let err),
             .unknown(let err):
            return err.localizedDescription
        case .networkUnavailable:
            return "You're offline. Please check your connection."
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

    private let namespaceKey = "pineconeUserNamespace"
    private var modelContext: ModelContext?
    @Published var pineconeErrorFromEdit: PineconeError?
    @Published var pineconeErrorFromAdd: PineconeError?
    @Published var pineconeErrorFromRefreshNamespace: PineconeError?
    @Published var pineconeErrorFromQ: PineconeError?
    @Published var pineconeErrorOnDel: PineconeError?
    @Published var pineconeQueryResponse: PineconeQueryResponse?
    @Published var accountDeleted: Bool = false
    @Published var pineconeIDResponse: PineconeIDResponse?
    @Published var pineconeIDs: [String] = []
    @Published var pineconeFetchedVectors: [Vector] = []
    
    @Published var namespace: String
    
    let pineconeActor: PineconeActor
    var cancellables = Set<AnyCancellable>()
    
    init(pineconeActor: PineconeActor) {
        self.pineconeActor = pineconeActor

        
        // Get or create namespace
        if let saved = UserDefaults.standard.string(forKey: namespaceKey) {
            self.namespace = saved
        } else {
            let new = UUID().uuidString
            self.namespace = new
            UserDefaults.standard.set(new, forKey: namespaceKey)
        }
        
        updateAccountDeletedFromUserDefaults()
    }
    
    func updateModelContext(to newContext: ModelContext) {
        self.modelContext = newContext
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
    
    func loadLocalVectors() {
        debugLog("loadLocalVectors CALLED")
        let fetchDescriptor = FetchDescriptor<VectorEntity>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        if modelContext == nil {
            debugLog("modelContext is nil in loadLocalVectors")
        }
        do {
            let entities = try modelContext?.fetch(fetchDescriptor) ?? []
            let vectors = entities.map { $0.toVector }
            DispatchQueue.main.async {
                self.pineconeFetchedVectors = vectors
            }
        } catch {
            debugLog("Failed to load local vectors: \(error.localizedDescription)")
            self.pineconeErrorFromRefreshNamespace = .refreshFailed(error)
        }
    }
    
    func clearManager() {
        self.pineconeErrorFromAdd = nil
        self.pineconeErrorFromRefreshNamespace = nil
        self.pineconeErrorFromEdit = nil
        self.pineconeErrorFromQ = nil
        self.pineconeQueryResponse = nil
       
    }
    
    func deleteVector(withId id: String) {
        debugLog("deleteVector called")
        // localy
        self.pineconeFetchedVectors.removeAll { $0.id == id }
        
        //swiftData
        let descriptor = FetchDescriptor<VectorEntity>(predicate: #Predicate { $0.id == id })
        
        do {
            if let entity = try modelContext?.fetch(descriptor).first {
                modelContext?.delete(entity)
                try modelContext?.save()
            }
        } catch {
            debugLog("Failed to delete vector from SwiftData: \(error.localizedDescription)")
        }
    }

    //MARK: - Methods for the Views
    func refreshNamespacesIDs() {
        Task {
            do {
                let vectors = try await pineconeActor.refreshNamespacesIDs(namespaceKey: namespace)
                DispatchQueue.main.async {
                    self.pineconeFetchedVectors = vectors
                }
            } catch DecodingError.keyNotFound(let key, _) where key.stringValue == "usage" || key.stringValue == "vectors" {
                // For the new user or deleted all info to avoid show the ErrorView
                DispatchQueue.main.async {
                    self.pineconeFetchedVectors = []
                    self.pineconeErrorFromQ = nil
                    self.pineconeErrorFromEdit = nil
                    self.pineconeErrorFromRefreshNamespace = nil
                }
            } catch {
                self.pineconeErrorFromRefreshNamespace = .refreshFailed(error)
                debugLog("from refreshNamespacesIDs: \(error) - \( error.localizedDescription)")
            }
        }
    }
    
    @MainActor
    func upsertData(id: String, vector: [Float], metadata: [String: String], from sender: senderView) async -> Bool {
    #if DEBUG
        print("upsertData called")
    #endif
        do {
            let safeMetadata = metadata.mapValues { String(describing: $0) }
            try await pineconeActor.upsertDataToPinecone(id: id, vector: vector, metadata: safeMetadata, namespaceKey: namespace)
            return true
        } catch {
            debugLog("from upsertData() Error: \(error.localizedDescription)")
            if sender == .editInfo {
                self.pineconeErrorFromEdit = .upsertFailed(error)
            } else if sender == .KView {
                self.pineconeErrorFromAdd = .upsertFailed(error)
            }
            return false
        }
    }
    
    func deleteVectorFromPinecone(id: String) async -> Bool {
        debugLog("deleteVectorFromPinecone CALLED")
        do {
            try await pineconeActor.deleteVectorFromPinecone(id: id, namespaceKey: namespace)
            return true
        } catch {
            if pineconeErrorFromEdit == nil {
                pineconeErrorFromEdit = .deleteFailed(error)
            }
            return false
        }
    }
    
    func deleteAllVectorsInNamespace() async -> Bool {

            do {
                try await pineconeActor.deleteAllVectorsInNamespace(namespaceKey: namespace)
                
                self.pineconeFetchedVectors = []
                self.pineconeIDs = []
                return true
            } catch {
                self.pineconeErrorOnDel = .deleteFailed(error)
                return false
            }
    }
  
    
    func queryPinecone(vector: [Float], topK: Int = 1, includeValues: Bool = false) {
        debugLog("queryPinecone CALLED")
        Task {
            do {
                let response = try await pineconeActor.queryPinecone(vector: vector, topK: topK, includeValues: includeValues, namespaceKey: namespace)
                self.pineconeQueryResponse = response
            } catch {
                self.pineconeErrorFromQ = .queryFailed(error)
            }
        }
    }
    
}
