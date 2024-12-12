//
//  CloudKitViewModel.swift
//  Memory
//
//  Created by Evangelos Spyromilios on 06.03.24.
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
            return "An unknown CK error occurred. Please try again."
        }
    }
}



import Combine
import CloudKit
import SwiftUI

actor CloudKitViewModel: ObservableObject, Sendable {
    
    @MainActor
    @Published var userIsSignedIn: Bool = false
    @MainActor
    @Published var isLoading: Bool = false
    @MainActor
    @Published var CKErrorDesc: String = ""
    @MainActor
    @Published var userID: CKRecord.ID?
    @MainActor
    @Published var fetchedNamespaceDict: [CKRecord.ID: NamespaceItem] = [:]
    @MainActor
    @Published var isFirstLaunch: Bool = false
    @MainActor
    @Published var allImagesDeleted: Bool?
    
    private var db: CKDatabase?
    private var cancellables = Set<AnyCancellable>()
    
    var recordIDDelete: CKRecord.ID? {
        didSet {
            guard let recordIDDelete = recordIDDelete else { return }
            saveRecordNameToKeychain(recordIDDelete)
        }
    }
    
    static let shared = CloudKitViewModel()
    
    
    private func saveRecordNameToKeychain(_ recordID: CKRecord.ID) {
        let recordName = recordID.recordName
        KeychainManager.standard.save(account: "recordIDDelete", data: Data(recordName.utf8))
    }
    
    init() {
        Task {
            // Perform background work first
            let isFirstLaunchResult = await CloudKitViewModel.checkIfFirstLaunch()
            let tempRecordID = KeychainManager.standard.readRecordID(account: "recordIDDelete")
            await self.updateRecordID(tempRecordID) //switching from Task's thread to actor's isolation. check below
            
            
            // switch to the main actor to update UI
            await MainActor.run {
                self.isFirstLaunch = isFirstLaunchResult
            }
            
            // Setup observers and start initial tasks
            await setupCloudKitObservers()
            await startInitialTasks()
        }
    }
    
    ///even when called from a Task, accessing or modifying actor-isolated properties and methods happens in the actor’s context,
    ///provided you use await. The actor’s internal queue guarantees thread safety by isolating those accesses.
    private func updateRecordID(_ tempRecordID: CKRecord.ID?) async {
        if let tempRecordID = tempRecordID {
            self.recordIDDelete = tempRecordID
        }
    }
    
    private func setupCloudKitObservers() {
        NotificationCenter.default.publisher(for: .CKAccountChanged)
            .sink { [weak self] _ in
                guard let self = self else { return }
                Task {
                    try? await self.getiCloudStatus()
                }
            }
            .store(in: &cancellables)
    }
    
    private func startInitialTasks() {
        Task {
            do {
                try await getiCloudStatus()
            } catch {
                await handleCKError(error)
            }
        }
    }


    private static func checkIfFirstLaunch() async -> Bool {
        UserDefaults.standard.synchronize()
        
        let keyExists = await userDefaultsKeyExists("isFirstLaunch")
        if keyExists {
            return UserDefaults.standard.bool(forKey: "isFirstLaunch")
        } else {
            UserDefaults.standard.set(true, forKey: "isFirstLaunch")
            return true
        }
    }
    
    //       private static func userDefaultsKeyExists(_ key: String) -> Bool {
    //           return UserDefaults.standard.object(forKey: key) != nil
    //       }
    
//    private func handleAccountChange() throws {
//        Task {
//            do {
//                try await getiCloudStatus()
//            }
//            catch {
//                throw error
//            }
//        }
//    }
    
    func clearCloudKit() {
        DispatchQueue.main.async {
            self.isLoading = false
            self.CKErrorDesc = ""
        }
    }
    
    //MARK: startCloudKit
    func startCloudKit() {
        DispatchQueue.main.async {
            self.isLoading = true }
        Task {
            do {
                let key = await fetchedNamespaceDict.keys.first
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
        let delayBetweenRetries: UInt64 = 100_000_000
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
                
                if await fetchedNamespaceDict.isEmpty {
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
    
    //MARK: getiCloudStatus
    func getiCloudStatus() async throws {
        let maxRetryAttempts = 3
        let delayBetweenRetries: UInt64 = 100_000_000
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
                        
                    default:
                        self.userIsSignedIn = false
                    }
                }
                self.db = CKContainer.default().privateCloudDatabase
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
        
        throw AppCKError.unknownError(message: "Failed to get user ID after \(maxRetryAttempts) attempts")
    }
    
    //MARK: initializeCloudKitSetup
    private func initializeCloudKitSetup() async throws {
        do {
            try await getiCloudStatus()
            guard await userIsSignedIn else { throw AppCKError.iCloudAccountNotFound }
            
            if let tempuserID = try? await getUserID() {
                await MainActor.run {
                    self.userID = tempuserID
                }
            }
            try await fetchNameSpace()
            if await fetchedNamespaceDict.isEmpty {
                try await makeNewNamespace()
            }
        } catch {
            throw error
        }
    }
    
    private func makeNewNamespace() async throws {
        guard let userID = await userID?.recordName else {
            throw AppCKError.UnableToGetNameSpace
        }
        let name = UUID().uuidString
        let recordID = CKRecord.ID(recordName: name)
        self.recordIDDelete = recordID
        
        let namespace = userID.lowercased()
        let nsItem = NamespaceItem(recordID: recordID, namespace: namespace)
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
                // Delete the record from the database
                try await db.deleteRecord(withID: recordID)
                return // Exit the function after successful deletion
            } catch {
                attempts += 1
                debugLog("Attempt \(attempts) failed: \(error.localizedDescription)")
                
                // Retry mechanism
                if attempts >= maxRetryAttempts {
                    throw error // Throw the error after exceeding retry attempts
                } else {
                    // Add delay between retries
                    try await Task.sleep(nanoseconds: delayBetweenRetries)
                }
            }
        }
        
        throw AppCKError.unknownError(message: "Failed to delete namespace item after \(maxRetryAttempts) attempts")
    }
    //MARK: NEW FOR DELETE ACCOUNT
    
    //MARK: Delete Images functions
    // Function to fetch all records matching a query
    func fetchAllRecords(using query: CKQuery, from database: CKDatabase) async throws -> [CKRecord] {
        var allRecords: [CKRecord] = []
        var currentCursor: CKQueryOperation.Cursor? = nil

        let maxAttempts = 3
        let delayBetweenRetries: UInt64 = 100_000_000

        repeat {
            var attempts = 0
            var lastError: Error?
            
            while attempts < maxAttempts {
                do {
                    let result: (matchResults: [(CKRecord.ID, Result<CKRecord, Error>)], queryCursor: CKQueryOperation.Cursor?)
                    
                    if let cursor = currentCursor {
                        // Fetch next batch using the cursor
                        result = try await database.records(continuingMatchFrom: cursor)
                    } else {
                        // Initial query
                        result = try await database.records(matching: query)
                    }
                    
                    let records = result.matchResults.compactMap { (_, result) -> CKRecord? in
                        switch result {
                        case .success(let record):
                            return record
                        case .failure(let error):
                            debugLog("Error fetching record: \(error.localizedDescription)")
                            return nil
                        }
                    }
                    
                    allRecords.append(contentsOf: records)
                    currentCursor = result.queryCursor
                    break // Break out of the retry loop on success
                } catch {
                    attempts += 1
                    lastError = error
                    if attempts >= maxAttempts {
                        throw lastError ?? AppCKError.unknownError(message: "Failed to fetch records after \(maxAttempts) attempts")
                    } else {
                        try await Task.sleep(nanoseconds: delayBetweenRetries)
                    }
                }
            }
        } while currentCursor != nil

        return allRecords
    }
    
    // Helper function to fetch records with pagination support
    func fetchRecords(withCursor cursor: CKQueryOperation.Cursor?, query: CKQuery?, from database: CKDatabase) async throws -> (records: [CKRecord], cursor: CKQueryOperation.Cursor?) {
        return try await withCheckedThrowingContinuation { continuation in
            var records: [CKRecord] = []
            let operation: CKQueryOperation
            if let cursor = cursor {
                operation = CKQueryOperation(cursor: cursor)
            } else if let query = query {
                operation = CKQueryOperation(query: query)
            } else {
                continuation.resume(throwing: NSError(domain: "Invalid parameters", code: -1, userInfo: nil))
                return
            }
            
            // Updated to use recordMatchedBlock
            operation.recordMatchedBlock = { recordID, result in
                switch result {
                case .success(let record):
                    records.append(record)
                case .failure(let error):
                    // Handle per-record error if necessary
                    debugLog("Error fetching record with ID \(recordID): \(error.localizedDescription)")
                }
            }

            // Updated to use queryResultBlock
            operation.queryResultBlock = { result in
                switch result {
                case .success(let cursor):
                    continuation.resume(returning: (records, cursor))
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            database.add(operation)
        }
    }
    
    
    // Function to delete a record from iCloud using CloudKit's modifyRecords method NOT FOR IMAGES
    func deleteRecordFromICloud(recordID: CKRecord.ID, from database: CKDatabase) async throws {
        let maxAttempts = 3
        var attempts = 0
        var lastError: Error?

        while attempts < maxAttempts {
            do {
                // Call modifyRecords with empty saving array and the record ID in deleting array
                let result = try await database.modifyRecords(
                    saving: [], // No records to save, just deleting
                    deleting: [recordID], // Record ID to delete
                    savePolicy: .ifServerRecordUnchanged, // Save policy; does not affect delete
                    atomically: true // Operation fails entirely if any error occurs
                )
                
                // Check the deletion result for the specific record ID
                if let deleteResult = result.deleteResults[recordID] {
                    switch deleteResult {
                    case .success:
                        debugLog("Successfully deleted record with ID: \(recordID.recordName)")
                        return // Deletion succeeded, exit function
                    case .failure(let error):
                        debugLog("Failed to delete record: \(error.localizedDescription)")
                        throw error // Throw the specific error to handle it further up
                    }
                } else {
                    debugLog("Record ID \(recordID.recordName) not found in delete results.")
                }
                
            } catch {
                // Handle any errors from the modifyRecords call
                debugLog("Attempt \(attempts + 1) failed to delete record from iCloud: \(error.localizedDescription)")
                lastError = error
                attempts += 1
                if attempts < maxAttempts {
                    // Optional delay before retrying
                    try await Task.sleep(nanoseconds: 300_000_000) // 0.5 seconds
                } else {
                    // Max attempts reached, rethrow the last error
                    throw lastError!
                }
            }
        }
        // If all attempts fail, throw the last encountered error
        throw lastError ?? NSError(domain: "UnknownError", code: -1, userInfo: nil)
    }
    
    
    // Function to delete records with specified IDs (ALL IMAGES)
    func deleteRecords(withIDs recordIDs: [CKRecord.ID], from database: CKDatabase) async throws {
        guard !recordIDs.isEmpty else { return }
        
        do {
            // Call modifyRecords with empty saving array and the record IDs in deleting array
            let result = try await database.modifyRecords(
                saving: [], // No records to save
                deleting: recordIDs, // Record IDs to delete
                savePolicy: .ifServerRecordUnchanged, // Save policy; does not affect delete
                atomically: true // Operation fails entirely if any error occurs
            )
            
            // Check deletion results
            for recordID in recordIDs {
                if let deleteResult = result.deleteResults[recordID] {
                    switch deleteResult {
                    case .success:
                        debugLog("Successfully deleted record with ID: \(recordID.recordName)")
                    case .failure(let error):
                        debugLog("Failed to delete record with ID \(recordID.recordName): \(error.localizedDescription)")
                        // Handle individual record deletion error if needed
                    }
                } else {
                    debugLog("Record ID \(recordID.recordName) not found in delete results.")
                }
            }
            
        } catch {
            // Handle any errors from the modifyRecords call
            debugLog("Failed to delete records from iCloud: \(error.localizedDescription)")
            throw error
        }
    }
    
    func deleteAllImageItems() async throws {
        let container = CKContainer.default()
        let privateDatabase = container.privateCloudDatabase
        let query = CKQuery(recordType: "ImageItem", predicate: NSPredicate(value: true))
        
        do {
            // Fetch all records
            let records = try await fetchAllRecords(using: query, from: privateDatabase)
            let recordIDs = records.map { $0.recordID }
            
            // Delete all fetched records
            if !recordIDs.isEmpty {
                try await deleteRecords(withIDs: recordIDs, from: privateDatabase)
            }
            
            // Update the UI on the main thread if needed
            await MainActor.run {
                allImagesDeleted = true
            }
            
        } catch {
            debugLog("Error deleting items from iCloud: \(error.localizedDescription)")
            throw error
        }
    }
    
    //MARK: Delete Images functions
    
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
                    debugLog("Successfully saved image item: \(imageItem)")
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
        
        let maxAttempts = 3
        let delayBetweenRetries: UInt64 = 200_000_000 // 0.2 seconds
        var attempts = 0
        var lastError: Error?
        
        while attempts < maxAttempts {
            do {
                // Use the new async API for fetching records
                let (matchedResults, _) = try await db.records(matching: query)
                let records = matchedResults.compactMap { (_, result) -> CKRecord? in
                    switch result {
                    case .success(let record):
                        return record
                    case .failure(let error):
                        debugLog("Error fetching record: \(error.localizedDescription)")
                        return nil
                    }
                }
                
                guard let record = records.first else {
                    return
                }
                
                try await deleteRecord(withRecordID: record.recordID, in: db)
                return
            } catch {
                attempts += 1
                lastError = error
                if attempts >= maxAttempts {
                    throw lastError ?? AppCKError.unknownError(message: "Failed to delete image after \(maxAttempts) attempts")
                }
                try await Task.sleep(nanoseconds: delayBetweenRetries)
            }
        }
    }
    
    private func deleteRecord(withRecordID recordID: CKRecord.ID, in db: CKDatabase) async throws {
        let maxRetryAttempts = 2
        let delayBetweenRetries: UInt64 = 100_000_000
        var attempts = 0
        var lastError: Error?
        
        while attempts < maxRetryAttempts {
            do {
                try await db.deleteRecord(withID: recordID)
                return
            } catch {
                attempts += 1
                lastError = error
                if attempts >= maxRetryAttempts {
                    throw lastError ?? AppCKError.unableToDeleteRecord
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
        
        let maxAttempts = 3
        let delayBetweenRetries: UInt64 = 100_000_000 // 0.2 seconds
        var attempts = 0
        var lastError: Error?
        
        while attempts < maxAttempts {
            do {
                // Use the new async API for fetching records
                let (matchedResults, _) = try await db.records(matching: query)
                let records = matchedResults.compactMap { (_, result) -> CKRecord? in
                    switch result {
                    case .success(let record):
                        return record
                    case .failure(let error):
                        debugLog("Error fetching record: \(error.localizedDescription)")
                        return nil
                    }
                }
                
                guard let record = records.first,
                      let asset = record["imageAsset"] as? CKAsset,
                      let fileURL = asset.fileURL else {
                    return nil
                }
                
                let data = try Data(contentsOf: fileURL)
                return UIImage(data: data)
            } catch {
                attempts += 1
                lastError = error
                if attempts >= maxAttempts {
                    throw lastError ?? AppCKError.unknownError(message: "Failed to fetch image after \(maxAttempts) attempts")
                }
                try await Task.sleep(nanoseconds: delayBetweenRetries)
            }
        }
        
        return nil
    }
    
    private func performQuery(_ query: CKQuery, in db: CKDatabase) async throws -> [CKRecord] {
        let maxRetryAttempts = 3
        let delayBetweenRetries: UInt64 = 100_000_000
        var attempts = 0

        while attempts < maxRetryAttempts {
            do {
                // Perform the query using the async API
                let (matchedResults, _) = try await db.records(matching: query)
                
                // Extract records from matched results
                let records = matchedResults.compactMap { (_, result) -> CKRecord? in
                    switch result {
                    case .success(let record):
                        return record
                    case .failure(let error):
                        debugLog("Error fetching record: \(error.localizedDescription)")
                        return nil
                    }
                }
                
                return records
            } catch {
                attempts += 1
                if attempts >= maxRetryAttempts {
                    throw error
                } else {
                    // Optional delay before retrying
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
    
}
