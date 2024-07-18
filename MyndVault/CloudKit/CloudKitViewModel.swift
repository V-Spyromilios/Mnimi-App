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
    @Published var CKErrorDesc: String = ""
    @Published var userID: CKRecord.ID?
    @Published var fetchedNamespaceDict: [CKRecord.ID: NamespaceItem] = [:]
//    @Published var fetchedImagesDict: [CKRecord.ID: ImageItem] = [:]
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
    
    func clearCloudKit() {

        isLoading = false
        CKErrorDesc = ""
    }
    
    //MARK: startCloudKit
    func startCloudKit() {
print("CloudKit started")
        isLoading = true
        Task {
            do {
                let key = fetchedNamespaceDict.keys.first
                
                if key == nil { try await initializeCloudKitSetup() }
                else {
                    _ = try? await fetchNamespaceItem(recordID: key!)
                }
            }
            catch {
                await handleCKError(error)
                await MainActor.run { isLoading = false }
            }
            await MainActor.run { isLoading = false }
        }
    }
    
    //MARK: fetchNameSpace
    func fetchNameSpace() async throws {

        guard let db = db else { throw AppCKError.CKDatabaseNotInitialized }

        let maxRetryAttempts = 3
        let delayBetweenRetries: UInt64 = 200_000_000
        var attempts = 0

        while attempts < maxRetryAttempts {
            do {
                let query = CKQuery(recordType: "NamespaceItem", predicate: NSPredicate(value: true))
                let rs = try await db.records(matching: query)
                
                let returnedRecords = rs.matchResults.compactMap { result in
                    try? result.1.get()
                }
                
                await MainActor.run {
                    for record in returnedRecords {
                        fetchedNamespaceDict[record.recordID] = NamespaceItem(record: record)
                    }
                }
                
                if fetchedNamespaceDict.isEmpty {
                    try await makeNewNamespace()
                }
                
                return
            } catch {
                attempts += 1
                if attempts >= maxRetryAttempts {
                    throw error
                } else {
                    try await Task.sleep(nanoseconds: delayBetweenRetries)
                }
            }
        }
    }
    

    //MARK: saveNamespaceItem
    func saveNamespaceItem(ns: NamespaceItem) async throws {

        guard let db = db else { throw AppCKError.CKDatabaseNotInitialized }

        let maxRetryAttempts = 3
        let delayBetweenRetries: UInt64 = 200_000_000
        var attempts = 0

        while attempts < maxRetryAttempts {
            do {
                try await db.save(ns.record)
                return
            } catch {
                attempts += 1
                if attempts >= maxRetryAttempts {
                    throw error
                } else {
                    try await Task.sleep(nanoseconds: delayBetweenRetries)
                }
            }
        }
    }
    
    //MARK: getiCloudStatus
    func getiCloudStatus() async throws {

        let maxRetryAttempts = 3
        let delayBetweenRetries: UInt64 = 200_000_000 // 0.2 seconds in nanoseconds
        var attempts = 0

        while attempts < maxRetryAttempts {
            do {
                let accountStatus = try await CKContainer.default().accountStatus()
                await MainActor.run {
                    switch accountStatus {
                    case .available:
                        withAnimation(.easeInOut) {
                            self.userIsSignedIn = true
                        }
                        self.db = CKContainer.default().privateCloudDatabase
                    default:
                        self.userIsSignedIn = false
                    }
                }
                return
            } catch {
                attempts += 1
                if attempts >= maxRetryAttempts {
                    throw error
                } else {
                    try await Task.sleep(nanoseconds: delayBetweenRetries)
                }
            }
        }
    }
    
    //MARK: getUserID
    private func getUserID() async throws -> CKRecord.ID {

        let maxRetryAttempts = 3
        let delayBetweenRetries: UInt64 = 200_000_000
        var attempts = 0

        while attempts < maxRetryAttempts {
            do {
                let container = CKContainer(identifier: "iCloud.dev.chillvibes.MyndVault")
                let id = try await container.userRecordID()
                await MainActor.run {
                    self.userID = id
                }
                return id
            } catch {
                attempts += 1
                if attempts >= maxRetryAttempts {
                    throw error
                } else {
                    try await Task.sleep(nanoseconds: delayBetweenRetries)
                }
            }
        }

        // this line should never be reached, but is required to satisfy the compiler
        throw AppCKError.unknownError(message: "Failed to get user ID after \(maxRetryAttempts) attempts")
    }
    
    //MARK: initializeCloudKitSetup
    private func initializeCloudKitSetup() async throws {

        do {
            try await getiCloudStatus()
            guard userIsSignedIn == true else { throw AppCKError.iCloudAccountNotFound }
            
            if let tempuserID = try? await getUserID() {
                await MainActor.run {
                    self.userID = tempuserID
                }
            }
            try await fetchNameSpace()
            if fetchedNamespaceDict.isEmpty {
                try await makeNewNamespace()
            }
        } catch {
            throw error
        }
    }
    
    //MARK: makeNewNamespace
    private func makeNewNamespace() async throws {
        
        guard let userID = userID?.recordName else {
            throw AppCKError.UnableToGetNameSpace
        }
        
        let namespace = userID.lowercased()
        let nsItem = NamespaceItem(namespace: namespace)
        let maxRetryAttempts = 3
        let delayBetweenRetries: UInt64 = 200_000_000 //0.2 sec in nanoseconds
        
        var attempts = 0
        
        while attempts < maxRetryAttempts {
            do {
                try await saveNamespaceItem(ns: nsItem)
                await MainActor.run {
                    fetchedNamespaceDict[nsItem.record.recordID] = nsItem
                }
                return
            } catch {
                attempts += 1
                if attempts >= maxRetryAttempts {
                    throw error
                } else {
                    try await Task.sleep(nanoseconds: delayBetweenRetries)
                }
            }
        }
    }

    //MARK: deleteNamespaceItem
    func deleteNamespaceItem(recordID: CKRecord.ID) async throws {
        guard let db = db else { throw AppCKError.CKDatabaseNotInitialized }

        let maxRetryAttempts = 3
        let delayBetweenRetries: UInt64 = 200_000_000

        var attempts = 0

        while attempts < maxRetryAttempts {
            do {
                try await db.deleteRecord(withID: recordID)
                await _ = MainActor.run { //returns a 'useless' for now value
                    fetchedNamespaceDict.removeValue(forKey: recordID)
                }
                return
            } catch {
                attempts += 1
                if attempts >= maxRetryAttempts {
                    throw error
                } else {
                    try await Task.sleep(nanoseconds: delayBetweenRetries)
                }
            }
        }

        // required to satisfy the compiler
        throw AppCKError.unknownError(message: "Failed to delete namespace item after \(maxRetryAttempts) attempts")
    }
    
    //MARK: fetchNamespaceItem
    func fetchNamespaceItem(recordID: CKRecord.ID) async throws -> NamespaceItem? {

        guard let db = db else { throw AppCKError.CKDatabaseNotInitialized }

        let maxRetryAttempts = 3
        let delayBetweenRetries: UInt64 = 200_000_000
        var attempts = 0

        while attempts < maxRetryAttempts {
            do {
                let record = try await db.record(for: recordID)
                if let namespaceItem = NamespaceItem(record: record) {
                    await MainActor.run {
                        fetchedNamespaceDict[record.recordID] = namespaceItem
                    }
                    return namespaceItem // Exit if successful
                } else {
                    throw AppCKError.unknownError(message: "Failed to initialize NamespaceItem from record")
                }
            } catch {
                attempts += 1
                if attempts >= maxRetryAttempts {
                    throw error
                } else {
                    try await Task.sleep(nanoseconds: delayBetweenRetries)
                }
            }
        }

        // is required to satisfy the compiler
        throw AppCKError.unknownError(message: "Failed to fetch namespace item after \(maxRetryAttempts) attempts")
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

        let maxRetryAttempts = 3
        let delayBetweenRetries: UInt64 = 200_000_000

        var attempts = 0

        while attempts < maxRetryAttempts {
            do {
                try await db.save(imageItem.record)
                await MainActor.run {
                    print("Successfully saved image item: \(imageItem)")
                }
                try? FileManager.default.removeItem(at: temporaryURL)
                return
            } catch {
                attempts += 1
                if attempts >= maxRetryAttempts {
                    await MainActor.run {
                        print("Failed to save image item: \(error.localizedDescription)")
                        self.CKErrorDesc = "CloudKit Error. Please try again."
                    }
                    throw error
                } else {
                    try await Task.sleep(nanoseconds: delayBetweenRetries)
                }
            }
        }

        // Clean up temporary file if the operation ultimately fails
        try? FileManager.default.removeItem(at: temporaryURL)
        // is required to satisfy the compiler
        throw AppCKError.unknownError(message: "Failed to save image item after \(maxRetryAttempts) attempts")
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

        let maxRetryAttempts = 3
        let delayBetweenRetries: UInt64 = 200_000_000
        var attempts = 0

        while attempts < maxRetryAttempts {
            do {
                return try await withCheckedThrowingContinuation { continuation in
                    db.delete(withRecordID: recordID) { recordID, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume(returning: ())
                        }
                    }
                }
            } catch {
                attempts += 1
                if attempts >= maxRetryAttempts {
                    throw error
                } else {
                    try await Task.sleep(nanoseconds: delayBetweenRetries)
                }
            }
        }

        throw AppCKError.unknownError(message: "Failed to delete record after \(maxRetryAttempts) attempts")
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
                if attempt >= maxRetries {
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

        let maxRetryAttempts = 3
        let delayBetweenRetries: UInt64 = 200_000_000
        var attempts = 0

        while attempts < maxRetryAttempts {
            do {
                return try await withCheckedThrowingContinuation { continuation in
                    db.fetch(withQuery: query, inZoneWith: nil, desiredKeys: nil, resultsLimit: 1) { result in
                        switch result {
                        case .success(let (matchedResults, _)):
                            let records = matchedResults.compactMap { _, result in
                                switch result {
                                case .success(let record):
                                    return record
                                case .failure:
                                    return nil
                                }
                            }
                            continuation.resume(returning: records)
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    }
                }
            } catch {
                attempts += 1
                if attempts >= maxRetryAttempts {
                    throw error
                } else {
                    try await Task.sleep(nanoseconds: delayBetweenRetries)
                }
            }
        }

        //is required to satisfy the compiler
        throw AppCKError.unknownError(message: "Failed to perform query after \(maxRetryAttempts) attempts")
    }

    
    private func handleCKError(_ error: Error) async {
            if let ckError = error as? CKError {
                await MainActor.run {
                    self.CKErrorDesc = ckError.customErrorDescription
                }
            } else {
                await MainActor.run {
                    self.CKErrorDesc = "CloudKit Error. Please try again."
                }
            }
        }
}

extension CKError {
    var customErrorDescription: String {
        switch self.code {
        case .networkUnavailable:
            return "No internet connection. Please check your network settings."
        case .networkFailure:
            return "Network error. Please try again later."
        case .serviceUnavailable:
            return "Service is currently unavailable. Please try again later."
        case .requestRateLimited:
            return "You're making too many requests. Please slow down and try again later."
        case .quotaExceeded:
            return "You've exceeded your iCloud storage quota. Please free up some space."
        case .notAuthenticated:
            return "You're not logged into iCloud. Please log in to your iCloud account."
        case .permissionFailure:
            return "You don't have permission to perform this action."
        default:
            return "An unexpected error occurred. Please try again."
        }
    }
}
