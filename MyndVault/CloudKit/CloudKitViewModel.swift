////
////  CloudKitViewModel.swift
////  Memory
////
////  Created by Evangelos Spyromilios on 06.03.24.
////
//
//
//
//import Foundation
//import CloudKit
//import SwiftUI
//
//final class CloudKitViewModel: ObservableObject {
//    @Published var userIsSignedIn: Bool = false
//    @Published var isLoading: Bool = false
//    @Published var CKErrorDesc: String = ""
//    @Published var userID: CKRecord.ID?
//    @Published var fetchedNamespaceDict: [CKRecord.ID: NamespaceItem] = [:]
////    @Published var fetchedImagesDict: [CKRecord.ID: ImageItem] = [:]
//    @Published var isFirstLaunch: Bool
//    
//    private var db: CKDatabase?
//    
//    static let shared = CloudKitViewModel()
//    
//    init() {
//        if userDefaultsKeyExists("isFirstLaunch") {
//            self.isFirstLaunch = UserDefaults.standard.bool(forKey: "isFirstLaunch")
//        } else {
//            // Key does not exist, set it to true for init setUp
//            UserDefaults.standard.set(true, forKey: "isFirstLaunch")
//            self.isFirstLaunch = true
//        }
//    }
//    
//    func clearCloudKit() {
//
//        isLoading = false
//        CKErrorDesc = ""
//    }
//    
//    //MARK: startCloudKit
//    func startCloudKit() {
//        isLoading = true
//        Task {
//            do {
//                let key = fetchedNamespaceDict.keys.first
//                
//                if key == nil { try await initializeCloudKitSetup() }
//                else {
//                    _ = try? await fetchNamespaceItem(recordID: key!)
//                }
//                await MainActor.run { isLoading = false }
//            }
//            catch {
//                await handleCKError(error)
//                await MainActor.run { isLoading = false }
//            }
//        }
//    }
//    
//    //MARK: fetchNameSpace
//    func fetchNameSpace() async throws {
//
//        guard let db = db else { throw AppCKError.CKDatabaseNotInitialized }
//
//        let maxRetryAttempts = 3
//        let delayBetweenRetries: UInt64 = 200_000_000
//        var attempts = 0
//
//        while attempts < maxRetryAttempts {
//            do {
//                let query = CKQuery(recordType: "NamespaceItem", predicate: NSPredicate(value: true))
//                let rs = try await db.records(matching: query)
//                
//                let returnedRecords = rs.matchResults.compactMap { result in
//                    try? result.1.get()
//                }
//                
//                await MainActor.run {
//                    for record in returnedRecords {
//                        fetchedNamespaceDict[record.recordID] = NamespaceItem(record: record)
//                    }
//                }
//                
//                if fetchedNamespaceDict.isEmpty {
//                    try await makeNewNamespace()
//                }
//                
//                return
//            } catch {
//                attempts += 1
//                if attempts >= maxRetryAttempts {
//                    throw error
//                } else {
//                    try await Task.sleep(nanoseconds: delayBetweenRetries)
//                }
//            }
//        }
//    }
//    
//
//    //MARK: saveNamespaceItem
//    func saveNamespaceItem(ns: NamespaceItem) async throws {
//
//        guard let db = db else { throw AppCKError.CKDatabaseNotInitialized }
//
//        let maxRetryAttempts = 3
//        let delayBetweenRetries: UInt64 = 200_000_000
//        var attempts = 0
//
//        while attempts < maxRetryAttempts {
//            do {
//                try await db.save(ns.record)
//                return
//            } catch {
//                attempts += 1
//                if attempts >= maxRetryAttempts {
//                    throw error
//                } else {
//                    try await Task.sleep(nanoseconds: delayBetweenRetries)
//                }
//            }
//        }
//    }
//    
//    //MARK: getiCloudStatus
//    func getiCloudStatus() async throws {
//
//        let maxRetryAttempts = 3
//        let delayBetweenRetries: UInt64 = 200_000_000 // 0.2 seconds in nanoseconds
//        var attempts = 0
//
//        while attempts < maxRetryAttempts {
//            do {
//                let accountStatus = try await CKContainer.default().accountStatus()
//                await MainActor.run {
//                    switch accountStatus {
//                    case .available:
//                        withAnimation(.easeInOut) {
//                            self.userIsSignedIn = true
//                        }
//                        self.db = CKContainer.default().privateCloudDatabase
//                    default:
//                        self.userIsSignedIn = false
//                    }
//                }
//                return
//            } catch {
//                attempts += 1
//                if attempts >= maxRetryAttempts {
//                    throw error
//                } else {
//                    try await Task.sleep(nanoseconds: delayBetweenRetries)
//                }
//            }
//        }
//    }
//    
//    //MARK: getUserID
//    private func getUserID() async throws -> CKRecord.ID {
//
//        let maxRetryAttempts = 3
//        let delayBetweenRetries: UInt64 = 200_000_000
//        var attempts = 0
//
//        while attempts < maxRetryAttempts {
//            do {
//                let container = CKContainer(identifier: "iCloud.dev.chillvibes.MyndVault")
//                let id = try await container.userRecordID()
//                await MainActor.run {
//                    self.userID = id
//                }
//                return id
//            } catch {
//                attempts += 1
//                if attempts >= maxRetryAttempts {
//                    throw error
//                } else {
//                    try await Task.sleep(nanoseconds: delayBetweenRetries)
//                }
//            }
//        }
//
//        // this line should never be reached, but is required to satisfy the compiler
//        throw AppCKError.unknownError(message: "Failed to get user ID after \(maxRetryAttempts) attempts")
//    }
//    
//    //MARK: initializeCloudKitSetup
//    private func initializeCloudKitSetup() async throws {
//
//        do {
//            try await getiCloudStatus()
//            guard userIsSignedIn == true else { throw AppCKError.iCloudAccountNotFound }
//            
//            if let tempuserID = try? await getUserID() {
//                await MainActor.run {
//                    self.userID = tempuserID
//                }
//            }
//            try await fetchNameSpace()
//            if fetchedNamespaceDict.isEmpty {
//                try await makeNewNamespace()
//            }
//        } catch {
//            throw error
//        }
//    }
//    
//    //MARK: makeNewNamespace
//    private func makeNewNamespace() async throws {
//        
//        guard let userID = userID?.recordName else {
//            throw AppCKError.UnableToGetNameSpace
//        }
//        
//        let namespace = userID.lowercased()
//        let nsItem = NamespaceItem(namespace: namespace)
//        let maxRetryAttempts = 3
//        let delayBetweenRetries: UInt64 = 200_000_000 //0.2 sec in nanoseconds
//        
//        var attempts = 0
//        
//        while attempts < maxRetryAttempts {
//            do {
//                try await saveNamespaceItem(ns: nsItem)
//                await MainActor.run {
//                    fetchedNamespaceDict[nsItem.record.recordID] = nsItem
//                }
//                return
//            } catch {
//                attempts += 1
//                if attempts >= maxRetryAttempts {
//                    throw error
//                } else {
//                    try await Task.sleep(nanoseconds: delayBetweenRetries)
//                }
//            }
//        }
//    }
//
//    //MARK: deleteNamespaceItem
//    func deleteNamespaceItem(recordID: CKRecord.ID) async throws {
//        guard let db = db else { throw AppCKError.CKDatabaseNotInitialized }
//
//        let maxRetryAttempts = 3
//        let delayBetweenRetries: UInt64 = 200_000_000
//
//        var attempts = 0
//
//        while attempts < maxRetryAttempts {
//            do {
//                try await db.deleteRecord(withID: recordID)
//                await _ = MainActor.run { //returns a 'useless' for now value
//                    fetchedNamespaceDict.removeValue(forKey: recordID)
//                }
//                return
//            } catch {
//                attempts += 1
//                if attempts >= maxRetryAttempts {
//                    throw error
//                } else {
//                    try await Task.sleep(nanoseconds: delayBetweenRetries)
//                }
//            }
//        }
//
//        // required to satisfy the compiler
//        throw AppCKError.unknownError(message: "Failed to delete namespace item after \(maxRetryAttempts) attempts")
//    }
//    
//    //MARK: fetchNamespaceItem
//    func fetchNamespaceItem(recordID: CKRecord.ID) async throws -> NamespaceItem? {
//
//        guard let db = db else { throw AppCKError.CKDatabaseNotInitialized }
//
//        let maxRetryAttempts = 3
//        let delayBetweenRetries: UInt64 = 200_000_000
//        var attempts = 0
//
//        while attempts < maxRetryAttempts {
//            do {
//                let record = try await db.record(for: recordID)
//                if let namespaceItem = NamespaceItem(record: record) {
//                    await MainActor.run {
//                        fetchedNamespaceDict[record.recordID] = namespaceItem
//                    }
//                    return namespaceItem // Exit if successful
//                } else {
//                    throw AppCKError.unknownError(message: "Failed to initialize NamespaceItem from record")
//                }
//            } catch {
//                attempts += 1
//                if attempts >= maxRetryAttempts {
//                    throw error
//                } else {
//                    try await Task.sleep(nanoseconds: delayBetweenRetries)
//                }
//            }
//        }
//
//        // is required to satisfy the compiler
//        throw AppCKError.unknownError(message: "Failed to fetch namespace item after \(maxRetryAttempts) attempts")
//    }
//    
//    
//    //MARK: saveImageItem
//    func saveImageItem(image: UIImage, uniqueID: String) async throws {
//
//        guard let db = db else { throw AppCKError.CKDatabaseNotInitialized }
//
//        // Create CKAsset from UIImage
//        guard let data = image.jpegData(compressionQuality: 1.0) else { throw AppCKError.imageConversionFailed }
//
//        // Create a unique temporary file URL for each asset
//        let temporaryURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".jpg")
//        try data.write(to: temporaryURL)
//
//        let imageAsset = CKAsset(fileURL: temporaryURL)
//        let imageItem = ImageItem(imageAsset: imageAsset, uniqueID: uniqueID)
//
//        let maxRetryAttempts = 3
//        let delayBetweenRetries: UInt64 = 200_000_000
//
//        var attempts = 0
//
//        while attempts < maxRetryAttempts {
//            do {
//                try await db.save(imageItem.record)
//                await MainActor.run {
//                    print("Successfully saved image item: \(imageItem)")
//                }
//                try? FileManager.default.removeItem(at: temporaryURL)
//                return
//            } catch {
//                attempts += 1
//                if attempts >= maxRetryAttempts {
//                    await MainActor.run {
//                    }
//                    throw error
//                } else {
//                    try await Task.sleep(nanoseconds: delayBetweenRetries)
//                }
//            }
//        }
//
//        // Clean up temporary file if the operation ultimately fails
//        try? FileManager.default.removeItem(at: temporaryURL)
//        // is required to satisfy the compiler
//        throw AppCKError.unknownError(message: "Failed to save image item")
//    }
//
//
//    //MARK: deleteImageItem
//    func deleteImageItem(uniqueID: String) async throws {
//
//        guard let db = db else { throw AppCKError.CKDatabaseNotInitialized }
//
//        let predicate = NSPredicate(format: "uniqueID == %@", uniqueID)
//        let query = CKQuery(recordType: "ImageItem", predicate: predicate)
//
//        var attempt = 0
//        let maxRetries = 3
//
//        while attempt < maxRetries {
//            do {
//                let records = try await performQuery(query, in: db)
//                guard let record = records.first else {
//                    // If no record found return
//                    return
//                }
//
//                //if record found proceed to delete attempt
//                try await deleteRecord(withRecordID: record.recordID, in: db)
//                return
//            } catch {
//                attempt += 1
//                if attempt == maxRetries {
//                    throw error
//                }
//                try await Task.sleep(nanoseconds: 100_000_000)
//            }
//        }
//    }
//    
//    private func deleteRecord(withRecordID recordID: CKRecord.ID, in db: CKDatabase) async throws {
//
//        let maxRetryAttempts = 2
//        let delayBetweenRetries: UInt64 = 200_000_000
//        var attempts = 0
//
//        while attempts < maxRetryAttempts {
//            do {
//                return try await withCheckedThrowingContinuation { continuation in
//                    db.delete(withRecordID: recordID) { recordID, error in
//                        if let error = error {
//                            continuation.resume(throwing: error)
//                        } else {
//                            continuation.resume(returning: ())
//                        }
//                    }
//                }
//            } catch {
//                attempts += 1
//                if attempts >= maxRetryAttempts {
//                    throw error
//                } else {
//                    try await Task.sleep(nanoseconds: delayBetweenRetries)
//                }
//            }
//        }
//
//        throw AppCKError.unableToDeleteRecord
//    }
//  
//    //MARK: fetchImageItem
//    func fetchImageItem(uniqueID: String) async throws -> UIImage? {
//
//        guard let db = db else { throw AppCKError.CKDatabaseNotInitialized }
//        
//        let predicate = NSPredicate(format: "uniqueID == %@", uniqueID)
//        let query = CKQuery(recordType: "ImageItem", predicate: predicate)
//        
//        var attempt = 0
//        let maxRetries = 3
//        
//        while attempt < maxRetries {
//            do {
//                let records = try await performQuery(query, in: db)
//                guard let record = records.first,
//                      let asset = record["imageAsset"] as? CKAsset,
//                      let fileURL = asset.fileURL else {
//                    return nil
//                }
//                
//                let data = try Data(contentsOf: fileURL)
//                return UIImage(data: data)
//            } catch {
//                attempt += 1
//                if attempt >= maxRetries {
//                    throw error
//                }
//                // Optional: Add a delay before retrying
//                try await Task.sleep(nanoseconds: 100_000) //0.1sec
//            }
//        }
//        return nil
//    }
//
//    //MARK: performQuery
//    private func performQuery(_ query: CKQuery, in db: CKDatabase) async throws -> [CKRecord] {
//
//        let maxRetryAttempts = 3
//        let delayBetweenRetries: UInt64 = 200_000_000
//        var attempts = 0
//
//        while attempts < maxRetryAttempts {
//            do {
//                return try await withCheckedThrowingContinuation { continuation in
//                    db.fetch(withQuery: query, inZoneWith: nil, desiredKeys: nil, resultsLimit: 1) { result in
//                        switch result {
//                        case .success(let (matchedResults, _)):
//                            let records = matchedResults.compactMap { _, result in
//                                switch result {
//                                case .success(let record):
//                                    return record
//                                case .failure:
//                                    return nil
//                                }
//                            }
//                            continuation.resume(returning: records)
//                        case .failure(let error):
//                            continuation.resume(throwing: error)
//                        }
//                    }
//                }
//            } catch {
//                attempts += 1
//                if attempts >= maxRetryAttempts {
//                    throw error
//                } else {
//                    try await Task.sleep(nanoseconds: delayBetweenRetries)
//                }
//            }
//        }
//
//        //is required to satisfy the compiler
//        throw AppCKError.unknownError(message: "Failed to perform query after \(maxRetryAttempts) attempts")
//    }
//
//    
//    private func handleCKError(_ error: Error) async {
//            if let ckError = error as? CKError {
//                await MainActor.run {
//                    self.CKErrorDesc = ckError.customErrorDescription
//                }
//            } else {
//                await MainActor.run {
//                    self.CKErrorDesc = "CloudKit Error. Please try again."
//                }
//            }
//        }
//}
//
extension CKError {
    var customErrorDescription: String {
        switch self.code {
               case .accountTemporarilyUnavailable:
                   return "Your iCloud account is temporarily unavailable. Please try again later."
               case .alreadyShared:
                   return "This item is already shared."
               case .assetFileModified:
                   return "The asset was modified while saving. Please try again."
               case .assetFileNotFound:
                   return "The specified asset could not be found."
               case .assetNotAvailable:
                   return "The asset is not available."
               case .badContainer:
                   return "There is an issue with the iCloud container. Please contact support."
               case .badDatabase:
                   return "There is an issue with the database. Please try again later."
               case .batchRequestFailed:
                   return "The request batch failed. Please try again."
               case .changeTokenExpired:
                   return "The change token has expired. Please refresh and try again."
               case .constraintViolation:
                   return "A constraint violation occurred. Please ensure all data is correct."
               case .incompatibleVersion:
                   return "Your app version is incompatible. Please update to the latest version."
               case .internalError:
                   return "An internal error occurred in CloudKit. Please try again later."
               case .invalidArguments:
                   return "Invalid information was provided. Please check and try again."
               case .limitExceeded:
                   return "The request exceeds the size limit. Please reduce the size and try again."
               case .managedAccountRestricted:
                   return "Your account has restrictions. Please check your Settings."
               case .missingEntitlement:
                   return "The app is missing a required entitlement. Please contact support."
               case .networkFailure:
                   return "A network error occurred. Please check your connection and try again."
               case .networkUnavailable:
                   return "The network is unavailable. Please check your connection and try again."
               case .notAuthenticated:
                   return "You are not authenticated. Please log in to iCloud and try again."
               case .operationCancelled:
                   return "The operation was cancelled."
               case .partialFailure:
                   return "The operation completed with partial failures. Please try again."
               case .participantMayNeedVerification:
                   return "You need to verify your participation in the share."
               case .permissionFailure:
                   return "You do not have permission to perform this action."
               case .quotaExceeded:
                   return "Your iCloud storage quota has been exceeded. Please free up some space."
               case .referenceViolation:
                   return "A reference violation occurred. Please ensure all data is correct."
               case .requestRateLimited:
                   return "You are making requests too frequently. Please slow down and try again later."
               case .serverRecordChanged:
                   return "The record has been changed on the server. Please refresh and try again."
               case .serverRejectedRequest:
                   return "The server rejected the request. Please try again."
               case .serverResponseLost:
                   return "The network connection was lost. Please try again."
               case .serviceUnavailable:
                   return "CloudKit service is currently unavailable. Please try again later."
               case .tooManyParticipants:
                   return "There are too many participants in the share."
               case .unknownItem:
                   return "The specified record does not exist."
               case .userDeletedZone:
                   return "The record zone was deleted by the user."
               case .zoneBusy:
                   return "The server is too busy to handle the request. Please try again later."
               case .zoneNotFound:
                   return "The specified record zone does not exist."
               default:
                   return "An unknown error occurred. Please try again."
               }
        }
    }



import Combine
import CloudKit
import SwiftUI

final class CloudKitViewModel: ObservableObject {
    @Published var userIsSignedIn: Bool = false
    @Published var isLoading: Bool = false
    @Published var CKErrorDesc: String = ""
    @Published var userID: CKRecord.ID?
    @Published var fetchedNamespaceDict: [CKRecord.ID: NamespaceItem] = [:]
    @Published var isFirstLaunch: Bool
    
    private var db: CKDatabase?
    private var cancellables = Set<AnyCancellable>()
    
    static let shared = CloudKitViewModel()
    
    init() {
        self.isFirstLaunch = CloudKitViewModel.checkIfFirstLaunch()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleAccountChange), name: .CKAccountChanged, object: nil)
                Task {
                    do {
                        try await getiCloudStatus()
                    } catch {
                        await handleCKError(error)
                    }
                }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .CKAccountChanged, object: nil)
    }
    
    private static func checkIfFirstLaunch() -> Bool {
           if userDefaultsKeyExists("isFirstLaunch") {
               return UserDefaults.standard.bool(forKey: "isFirstLaunch")
           } else {
               UserDefaults.standard.set(true, forKey: "isFirstLaunch")
               return true
           }
       }
       
       private static func userDefaultsKeyExists(_ key: String) -> Bool {
           return UserDefaults.standard.object(forKey: key) != nil
       }
    
    @objc private func handleAccountChange() {
        Task {
            do {
                try await getiCloudStatus()
            }
            catch {
                throw error
            }
        }
    }
    
    func clearCloudKit() {
        isLoading = false
        CKErrorDesc = ""
    }
    
    func startCloudKit() {
        isLoading = true
        Task {
            do {
                let key = fetchedNamespaceDict.keys.first
                if key == nil {
                    try await initializeCloudKitSetup()
                } else {
                    _ = try? await fetchNamespaceItem(recordID: key!)
                }
                await MainActor.run { isLoading = false }
            } catch {
                await handleCKError(error)
                await MainActor.run { isLoading = false }
            }
        }
    }
    
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
    
    func getiCloudStatus() async throws {
        let maxRetryAttempts = 3
        let delayBetweenRetries: UInt64 = 200_000_000
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
        
        throw AppCKError.unknownError(message: "Failed to get user ID after \(maxRetryAttempts) attempts")
    }
    
    private func initializeCloudKitSetup() async throws {
        do {
            try await getiCloudStatus()
            guard userIsSignedIn else { throw AppCKError.iCloudAccountNotFound }
            
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
    
    private func makeNewNamespace() async throws {
        guard let userID = userID?.recordName else {
            throw AppCKError.UnableToGetNameSpace
        }
        
        let namespace = userID.lowercased()
        let nsItem = NamespaceItem(namespace: namespace)
        let maxRetryAttempts = 3
        let delayBetweenRetries: UInt64 = 200_000_000
        
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
    
    func deleteNamespaceItem(recordID: CKRecord.ID) async throws {
        guard let db = db else { throw AppCKError.CKDatabaseNotInitialized }
        
        let maxRetryAttempts = 3
        let delayBetweenRetries: UInt64 = 200_000_000
        
        var attempts = 0
        
        while attempts < maxRetryAttempts {
            do {
                try await db.deleteRecord(withID: recordID)
                await MainActor.run {
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
        
        throw AppCKError.unknownError(message: "Failed to delete namespace item after \(maxRetryAttempts) attempts")
    }
    
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
                    return namespaceItem
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
        
        throw AppCKError.unknownError(message: "Failed to fetch namespace item after \(maxRetryAttempts) attempts")
    }
    
    func saveImageItem(image: UIImage, uniqueID: String) async throws {
        guard let db = db else { throw AppCKError.CKDatabaseNotInitialized }
        
        guard let data = image.jpegData(compressionQuality: 1.0) else { throw AppCKError.imageConversionFailed }
        
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
                    }
                    throw error
                } else {
                    try await Task.sleep(nanoseconds: delayBetweenRetries)
                }
            }
        }
        
        try? FileManager.default.removeItem(at: temporaryURL)
        throw AppCKError.unknownError(message: "Failed to save image item")
    }
    
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
                    return
                }
                
                try await deleteRecord(withRecordID: record.recordID, in: db)
                return
            } catch {
                attempt += 1
                if attempt == maxRetries {
                    throw error
                }
                try await Task.sleep(nanoseconds: 100_000_000)
            }
        }
    }
    
    private func deleteRecord(withRecordID recordID: CKRecord.ID, in db: CKDatabase) async throws {
        let maxRetryAttempts = 2
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
        
        throw AppCKError.unableToDeleteRecord
    }
    
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
                try await Task.sleep(nanoseconds: 100_000)
            }
        }
        return nil
    }
    
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
    
    private func userDefaultsKeyExists(_ key: String) -> Bool {
        return UserDefaults.standard.object(forKey: key) != nil
    }
}
