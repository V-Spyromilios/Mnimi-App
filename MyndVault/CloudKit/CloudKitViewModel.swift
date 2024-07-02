//
//  CloudKitViewModel.swift
//  Memory
//
//  Created by Evangelos Spyromilios on 06.03.24.
//



import Foundation
import CloudKit
import SwiftUI

final class CloudKitViewModel: ObservableObject {
    @Published var userIsSignedIn: Bool = false
    @Published var isLoading: Bool = false
    @Published var CKError: String = ""
    @Published var userID: CKRecord.ID?
    @Published var fetchedNamespaceDict: [CKRecord.ID: NamespaceItem] = [:]
//    @Published var fetchedImagesDict: [CKRecord.ID: ImageItem] = [:]
    @Published var log: [String] = []
    @Published var isFirstLaunch: Bool
    
    private var db: CKDatabase?
    
    static let shared = CloudKitViewModel()
    
    init() {
        if userDefaultsKeyExists("isFirstLaunch") {
            self.isFirstLaunch = UserDefaults.standard.bool(forKey: "isFirstLaunch")
        } else {
            // Key does not exist, set it to true for init setUp
            UserDefaults.standard.set(true, forKey: "isFirstLaunch")
            self.isFirstLaunch = true
        }
    }
    
    //MARK: startCloudKit
    func startCloudKit() {
        
        Task {
            let key = fetchedNamespaceDict.keys.first
            if key == nil {
                await initializeCloudKitSetup()
            } else {
                _ = try? await fetchNamespaceItem(recordID: key!)
            }
        }
    }
    
    //MARK: fetchNameSpace
    func fetchNameSpace() async throws {
        guard let db = db else { throw AppCKError.CKDatabaseNotInitialized }
        
        let query = CKQuery(recordType: "NamespaceItem", predicate: NSPredicate(value: true))
        await MainActor.run {
            log.append("query: \(query)") }
        let rs = try await db.records(matching: query)
        
        await MainActor.run {
            log.append("rs: \(rs)") }
        let returnedRecords = rs.matchResults.compactMap { try? $0.1.get() }
        await MainActor.run {
            log.append("returnedRecords \(returnedRecords)") }
        
        await MainActor.run {
            returnedRecords.forEach { record in
                fetchedNamespaceDict[record.recordID] = NamespaceItem(record: record)
            }
        }
        if fetchedNamespaceDict.isEmpty {
            await MainActor.run {
                log.append("No namespaces found. Creating a new namespace.") }
            try await makeNewNamespace()
        } else {
            await MainActor.run {
                log.append("Namespaces found: \(fetchedNamespaceDict)") }
        }
    }
    //MARK: saveNamespaceItem
    func saveNamespaceItem(ns: NamespaceItem) async throws {
        guard let db = db else { throw AppCKError.CKDatabaseNotInitialized }
        
        do {
            try await db.save(ns.record)
            await MainActor.run {
                log.append("Successfully saved namespace item: \(ns)")
            }
        } catch {
            if let ckError = error as? CKError {
                switch ckError.code {
                case .networkUnavailable, .networkFailure:
                    await MainActor.run {
                        log.append("Network error occurred: \(ckError.localizedDescription)")
                        self.CKError = "Network Failure. Network is available, but CloudKit is inaccessible."
                    }
                case .serviceUnavailable:
                    await MainActor.run {
                        log.append("Service unavailable: \(ckError.localizedDescription)")
                        self.CKError = "iCloud Unavailable."
                    }
                case .requestRateLimited:
                    await MainActor.run {
                        log.append("Request rate limited: \(ckError.localizedDescription)")
                        self.CKError = "CloudKit rate-limits requests"
                    }
                case .quotaExceeded:
                    await MainActor.run {
                        log.append("Quota exceeded: \(ckError.localizedDescription)")
                        self.CKError = "Not enough iCloud storage. Check iCloud settings to manage your storage."
                    }
                case .notAuthenticated:
                    await MainActor.run {
                        log.append("User not authenticated: \(ckError.localizedDescription)")
                        self.CKError = "User not authenticated"
                    }
                case .permissionFailure:
                    await MainActor.run {
                        log.append("Permission failure: \(ckError.localizedDescription)")
                        self.CKError = "User doesn’t have permission to save or fetch data."
                    }
                default:
                    await MainActor.run {
                        log.append("CloudKit error: \(ckError.localizedDescription)")
                        self.CKError = "CloudKit Error. Please try again."
                    }
                }
            } else {
                await MainActor.run {
                    log.append("Failed to save namespace item: \(error.localizedDescription)")
                    self.CKError = "CloudKit Error E.2. Please try again."
                    
                }
            }
            throw error
        }
    }
    
    //MARK: getiCloudStatus
    func getiCloudStatus() async {
        do {
            let accountStatus = try await CKContainer.default().accountStatus()
            await MainActor.run {
                switch accountStatus {
                case .available:
                    withAnimation(.easeInOut) {
                        self.userIsSignedIn = true }
                    self.db = CKContainer.default().privateCloudDatabase
                default:
                    self.userIsSignedIn = false
                }
            }
        } catch {
            await MainActor.run {
                log.append("Error checking iCloud status: \(error)") }
        }
    }
    
    //MARK: getUserID
    private func getUserID() async throws -> CKRecord.ID {
        let container = CKContainer(identifier: "iCloud.dev.chillvibes.MyndVault")
        let id = try await container.userRecordID()
        await MainActor.run {
            self.userID = id
        }
        return id
    }
    
    //MARK: initializeCloudKitSetup
    private func initializeCloudKitSetup() async {
        await MainActor.run { isLoading = true }
        defer {
            Task { @MainActor in
                self.isLoading = false
            }
        }
        do {
            await getiCloudStatus()
            guard userIsSignedIn == true else { throw AppCKError.iCloudAccountNotFound }
            await MainActor.run {
                log.append("User is signed in to iCloud.") }
            
            
            let tempuserID = try await getUserID()
            await MainActor.run {
                self.userID = tempuserID
            }
            
            try await fetchNameSpace()
            await MainActor.run {
                log.append("Fetched namespaces. Current namespace dict: \(fetchedNamespaceDict)") }
            
            
        } catch {
            if fetchedNamespaceDict.isEmpty {
                do {
                    try await makeNewNamespace() }
                catch(let error) {
                    log.append("New 133 catch: \(error)")
                }
            }
            
            await MainActor.run {
                log.append("Initialization failed: \(error.localizedDescription)") }
            await MainActor.run {
                self.CKError = error.localizedDescription
            }
        }
    }
    
    //MARK: makeNewNamespace
    private func makeNewNamespace() async throws {
        print("makeNewNamespace")
        await MainActor.run {
            log.append("makeNewNamespace Called.")
        }
        
        guard let userID = userID?.recordName else {
            await MainActor.run {
                log.append("Unable to get namespace: UserID is nil")
            }
            throw AppCKError.UnableToGetNameSpace
        }
        
        let namespace = userID.lowercased()
        let nsItem = NamespaceItem(namespace: namespace)
        do {
            try await saveNamespaceItem(ns: nsItem)
            await MainActor.run {
                fetchedNamespaceDict[nsItem.record.recordID] = nsItem
                log.append("Successfully created and saved new namespace item: \(nsItem)")
            }
        } catch {
            await MainActor.run {
                log.append("Failed to save new namespace item: \(error.localizedDescription)")
            }
            throw error
        }
    }

    //MARK: deleteNamespaceItem
    func deleteNamespaceItem(recordID: CKRecord.ID) async throws {
        guard let db = db else { throw AppCKError.CKDatabaseNotInitialized }
        do {
            try await db.deleteRecord(withID: recordID)
            await MainActor.run {
                fetchedNamespaceDict.removeValue(forKey: recordID)
                log.append("Deleted namespace item with record ID: \(recordID)")
            }
        } catch {
            log.append("Failed to delete namespace item: \(error.localizedDescription)")
            throw error
        }
    }
    
    //MARK: fetchNamespaceItem
    func fetchNamespaceItem(recordID: CKRecord.ID) async throws -> NamespaceItem? {
        log.append("fetcNamespaceItem called")
        guard let db = db else { throw AppCKError.CKDatabaseNotInitialized }
        do {
            let record = try await db.record(for: recordID)
            if let namespaceItem = NamespaceItem(record: record) {
                await MainActor.run {
                    fetchedNamespaceDict[record.recordID] = namespaceItem
                    log.append("Fetched namespace item: \(namespaceItem)")
                }
                return namespaceItem
            } else {
                throw AppCKError.unknownError(message: "Failed to initialize NamespaceItem from record")
            }
        } catch {
            log.append("Failed to fetch namespace item: \(error.localizedDescription)")
            throw error
        }
    }
    
    
    //MARK: saveImageItem
        func saveImageItem(image: UIImage, uniqueID: String) async throws {
            guard let db = db else { throw AppCKError.CKDatabaseNotInitialized }
    
            // Create CKAsset from UIImage
            guard let data = image.jpegData(compressionQuality: 1.0) else { throw AppCKError.imageConversionFailed }
    
            // Create a unique temporary file URL for each asset
            let temporaryURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".jpg")
            try data.write(to: temporaryURL)
    
            let imageAsset = CKAsset(fileURL: temporaryURL)
            let imageItem = ImageItem(imageAsset: imageAsset, uniqueID: uniqueID)
    
            do {
                try await db.save(imageItem.record)
                await MainActor.run {
//                    fetchedImagesDict[imageItem.record.recordID] = imageItem
                   print("Successfully saved image item: \(imageItem)")
                }
            } catch {
                await MainActor.run {
                   print("Failed to save image item: \(error.localizedDescription)")
                    self.CKError = "CloudKit Error. Please try again."
                }
                throw error
            }
    
            // Clean up temporary file
            try? FileManager.default.removeItem(at: temporaryURL)
        }
    //MARK: deleteImageItem
    func deleteImageItem(uniqueID: String) async throws {
            guard let db = db else { throw AppCKError.CKDatabaseNotInitialized }

            let predicate = NSPredicate(format: "uniqueID == %@", uniqueID)
            let query = CKQuery(recordType: "ImageItem", predicate: predicate)

            var attempt = 0
            let maxRetries = 3

            while attempt < maxRetries {
                do {
                    let records = try await performQuery(query, in: db)
                    guard let record = records.first else {
                        throw AppCKError.recordNotFound
                    }

                    try await deleteRecord(withRecordID: record.recordID, in: db)
                    await MainActor.run {
                        print("Successfully deleted image item with uniqueID: \(uniqueID)")
                    }
                    return
                } catch {
                    attempt += 1
                    if attempt == maxRetries {
                        print("Error about to be thrown: \(error.localizedDescription)")
                        throw error
                    }
                    try await Task.sleep(nanoseconds: 100_000)
                }
            }
        }
    
    private func deleteRecord(withRecordID recordID: CKRecord.ID, in db: CKDatabase) async throws {
            return try await withCheckedThrowingContinuation { continuation in
                db.delete(withRecordID: recordID) { recordID, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: ())
                    }
                }
            }
        }
  
    //MARK: fetchImageItem
    func fetchImageItem(uniqueID: String) async throws -> UIImage? {

        guard let db = db else { throw AppCKError.CKDatabaseNotInitialized }
        
        let predicate = NSPredicate(format: "uniqueID == %@", uniqueID)
        let query = CKQuery(recordType: "ImageItem", predicate: predicate)
        
        var attempt = 0
        let maxRetries = 3
        
        while attempt < maxRetries {
            do {
                let records = try await performQuery(query, in: db)
                guard let record = records.first,
                      let asset = record["imageAsset"] as? CKAsset,
                      let fileURL = asset.fileURL else {
                    return nil
                }
                
                let data = try Data(contentsOf: fileURL)
                return UIImage(data: data)
            } catch {
                attempt += 1
                if attempt == maxRetries {
                    print("Error about to be thrown: \(error.localizedDescription)")
                    throw error
                }
                // Optional: Add a delay before retrying
                try await Task.sleep(nanoseconds: 100_000) //0.1sec
            }
        }
        
        return nil
    }

    //MARK: performQuery
    private func performQuery(_ query: CKQuery, in db: CKDatabase) async throws -> [CKRecord] {
        print("performQuery() called with query: \(query)")
        
        return try await withCheckedThrowingContinuation { continuation in
            db.fetch(withQuery: query, inZoneWith: nil, desiredKeys: nil, resultsLimit: 1) { result in
                switch result {
                case .success(let (matchedResults, _)):
                    let records = matchedResults.compactMap { _, result in
                        switch result {
                        case .success(let record):
                            print("Perform Query - received record: \(record)")
                            return record
                        case .failure(let error):
                            print("Perform Query - record error: \(error.localizedDescription)")
                            return nil
                        }
                    }
                    print("Perform Query - returning records: \(records)")
                    continuation.resume(returning: records)
                case .failure(let error):
                    print("Perform Query - query error: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
