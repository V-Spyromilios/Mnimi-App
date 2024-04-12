//
//  CloudKitViewModel.swift
//  Memory
//
//  Created by Evangelos Spyromilios on 06.03.24.
//

import Foundation
import CloudKit

final class CloudKitViewModel: ObservableObject {
    
    @Published var permissionStatus: Bool = false
    @Published var userIsSignedIn: Bool = false
    @Published var isLoading: Bool = false
    @Published var CKError: String = ""
    @Published var useriD: CKRecord.ID?
    @Published var fetchedNamespaceDict: [CKRecord.ID: NamespaceItem] = [:]
    
    private var db: CKDatabase?
    
    static let shared = CloudKitViewModel()
    
    init() {
        isLoading = true
        Task {
            await initializeCloudKitSetup()
        }
    }
    
    func fetchNameSpace() async throws {
        
        let query = CKQuery(recordType: "NamespaceItem", predicate: NSPredicate(value: true))
        let rs = try await db?.records(matching: query)
        let returnedRecords = rs?.matchResults.compactMap { try? $0.1.get() }
        print("CK - fetch name seems ok")
        
        await MainActor.run {
            returnedRecords?.forEach { record in
                fetchedNamespaceDict[record.recordID] = NamespaceItem(record: record)
            }
        }
    }
    
    func saveNamespaceItem(ns: NamespaceItem) async throws {
        
        try await db?.save(ns.record) // the record in the extension of the NamepaceItem
    }
    
    func getiCloudStatus() async {
        do {
            let accountStatus = try await CKContainer.default().accountStatus()
            print("(CK) :: AccountStatus :: \(accountStatus)")

            await MainActor.run {
                switch accountStatus {
                case .available:
                    self.userIsSignedIn = true
                    self.db = CKContainer.default().privateCloudDatabase
                case .couldNotDetermine, .restricted, .noAccount, .temporarilyUnavailable:
                    self.userIsSignedIn = false
                @unknown default:
                    self.userIsSignedIn = false
                }
                print("(CK) :: iCloudStatus:: \(self.userIsSignedIn)")
            }
        } catch {
            print("Error checking iCloud status: \(error)")
        }
    }

    
    private func getUserID() async throws -> CKRecord.ID {
        let container = CKContainer(identifier: "iCloud.dev.chillvibes.Memory")
        do {
            let id = try await container.userRecordID()

            await MainActor.run {
                self.useriD = id
            }
            return id
        } catch {
            throw error // Propagate error up to the caller.
        }
    }
    
    
    
    private func initializeCloudKitSetup() async {
        do {
            let _ = await getiCloudStatus()
            print("(CK) Got iCloud Status : \(userIsSignedIn)")
            let _ = try await getUserID()
            print("(CK) Got userID : \(String(describing: self.useriD))")
            try await fetchNameSpace()
            print("(CK) fetched nameSpace :: Dict Value : \(fetchedNamespaceDict.values)")
            if fetchedNamespaceDict.isEmpty {
                try await makeNewNamespace()
                print("(CK) made new namespace")
            }
        } catch {
            await MainActor.run {
                self.CKError = error.localizedDescription
                print("(CK) CKError: \(error.localizedDescription)")
                self.isLoading = false
            }
        }
        await MainActor.run {
              self.isLoading = false
            print("(CK) init of CK finished, isLoading: \(self.isLoading)")
          }
    }
    
    private func makeNewNamespace() async throws {

        guard let userID = useriD?.recordName else {
            print("CloudKitViewModel :: Unable to unwrap 'userID'.")
            return
        }

        let namespace = userID.lowercased()
        do {
            let nsItem = NamespaceItem(namespace: namespace)
            print("(CK) new namespace:: nsItem:: \(nsItem)")
            try await saveNamespaceItem(ns: nsItem)
        } catch {
            print("CloudKitViewModel :: Error saving namespaceItem: \(error.localizedDescription)")
            throw error
        }
        await MainActor.run {
            self.isLoading = false
        }
    }
    
}
