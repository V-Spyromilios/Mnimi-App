////
////  PineconeManager.swift
////  Memory
////
////  Created by Evangelos Spyromilios on 13.02.24.
////
//
//import Foundation
//import Combine
//import CloudKit
//import SwiftUI
//
//// memoryindex HOST: https://memoryindex-g24xjwl.svc.apw5-4e34-81fa.pinecone.io
//
//actor PineconeManager: Sendable {
//    
//    //TODO: Move Published to viewModel. Actor should call viewModel funcs to update them
//    var CKviewModel: CloudKitViewModel? = nil
//    @MainActor
//    @Published var receivedError: Error?
//    @MainActor
//    @Published var indexInfo: String?
//    @MainActor
//    @Published var pineconeQueryResponse: PineconeQueryResponse?
//    @MainActor
//    @Published var upsertSuccesful: Bool = false
//    @MainActor
//    @Published var vectorDeleted: Bool = false
//    @MainActor
//    @Published var accountDeleted: Bool = false
//    @MainActor
//    @Published var pineconeIDResponse: PineconeIDResponse?
//    @Published var pineconeIDs: [String]
//    @Published var pineconeFetchedResponseFromID: PineconeFetchResponseFromID?
//    @MainActor @Published var pineconeFetchedVectors: [Vector] = []
//    @MainActor @Published var refreshAfterEditing: Bool = false
//
//    @MainActor
//    @Published var isDataSorted: Bool = false
//
//    var cancellables = Set<AnyCancellable>()
//    
//    init(cloudKitViewModel: CloudKitViewModel = .shared) {
//        self.CKviewModel = cloudKitViewModel
//        
//        Task {
//            // Ensure access to actor-isolated property within the actor's context
//            await self.updateAccountDeletedFromUserDefaults()
//        }
//        
//    }
//    
//    func resetAfterSuccessfulUpserting() {
//        Task { @MainActor in
//            self.isDataSorted = false
//            self.refreshAfterEditing = true
//        }
//    }
//    
//    func updateAccountDeletedFromUserDefaults() async {
//        await MainActor.run {
//            self.accountDeleted = UserDefaults.standard.bool(forKey: "accountDeleted")
//        }
//        
//        // Observe changes to accountDeleted and insert cancellable
//        let cancellable = self.$accountDeleted
//            .sink { newValue in
//                UserDefaults.standard.set(newValue, forKey: "accountDeleted")
//            }
//        
//        // Store the cancellable inside the actor context
//        self.cancellables.insert(cancellable)
//    }
//    
//    func clearManager() async {
//        await MainActor.run {
//            self.receivedError = nil
//            self.pineconeQueryResponse = nil
//            self.upsertSuccesful = false
//        }
//    }
//    
//    //deletes localy
//    func deleteVector(withId id: String) async {
//        await MainActor.run {
//            pineconeFetchedVectors.removeAll { $0.id == id }
//        }
//    }
//    
//    func refreshNamespacesIDs() async throws {
//        do {
//            try await fetchAllNamespaceIDs()
//            try await fetchDataForIds() //these should return !!!
//        } catch {
//            throw error
//        }
//    }
//    
//    func fetchAllNamespaceIDs() async throws {
//        guard let namespace = await CKviewModel?.fetchedNamespaceDict.first?.value.namespace else {
//            throw AppCKError.UnableToGetNameSpace
//        }
//        
//        guard let apiKey = ApiConfiguration.pineconeKey else {
//            throw AppNetworkError.apiKeyNotFound
//        }
//        
//        guard let url = URL(string: "https://memoryindex-g24xjwl.svc.apw5-4e34-81fa.pinecone.io/vectors/list?namespace=\(namespace)") else {
//            throw AppNetworkError.unknownError("fetchAllNamespaceIDs() :: Invalid URL")
//        }
//        
//        var request = URLRequest(url: url)
//        request.addValue(apiKey, forHTTPHeaderField: "Api-Key")
//        request.httpMethod = "GET"
//        
//        let maxAttempts = 2
//        var attempts = 0
//        
//        while attempts < maxAttempts {
//            do {
//                let (data, _) = try await URLSession.shared.data(for: request)
//                let decodedResponse = try JSONDecoder().decode(PineconeIDResponse.self, from: data)
//                
//                await MainActor.run {
//                    self.pineconeIDResponse = decodedResponse
//                }
//                    
//                if let idResponse = await self.pineconeIDResponse {
//                    await MainActor.run {
//                        self.pineconeIDs.append(contentsOf: idResponse.vectors.map { $0.id })
//                    }
//                    }
//                var needsRefrash: Bool = await MainActor.run {
//                    self.refreshAfterEditing == true
//                }
//                    if await !self.isDataSorted || needsRefrash {
//                        do {
//                            try await fetchDataForIds()
//                        } catch {
//                            throw error
//                        }
//                    }
//                
//                
//                // 1RU per call
//                updateTokenUsage(api: APIs.pinecone, tokensUsed: 1, read: true)
//                
//                // If successful, break the loop
//                break
//                
//            } catch {
//                attempts += 1
//                if attempts < maxAttempts {
//                    //                    print("Attempt \(attempts) failed, retrying after 0.1 seconds...")
//                    try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
//                } else {
//                    //                    print("All attempts failed.")
//                    throw error
//                }
//            }
//        }
//    }
//    
//    //MARK: New for proper sorting
//    private func fetchDataForIds() async throws {
//        guard let namespace = await CKviewModel?.fetchedNamespaceDict.first?.value.namespace else {
//            throw AppCKError.UnableToGetNameSpace
//        }
//        
//        guard let apiKey = ApiConfiguration.pineconeKey else {
//            throw AppNetworkError.apiKeyNotFound
//        }
//        
//        let queryItems: [URLQueryItem] = await MainActor.run {
//                self.pineconeIDs.map { URLQueryItem(name: "ids", value: $0) }
//            }
//            
//            // Ensure namespace is added to query items
//            var urlComponents = URLComponents(string: "https://memoryindex-g24xjwl.svc.apw5-4e34-81fa.pinecone.io/vectors/fetch")!
//            urlComponents.queryItems = queryItems
//            urlComponents.queryItems?.append(URLQueryItem(name: "namespace", value: namespace))
//        
//        
//        guard let url = urlComponents.url else {
//            throw URLError(.badURL)
//        }
//        
//        var request = URLRequest(url: url)
//            
//        request.addValue(apiKey, forHTTPHeaderField: "Api-Key")
//        request.httpMethod = "GET"
//        
//        let maxAttempts = 2
//        var attempts = 0
//        
//        while attempts < maxAttempts {
//            do {
//                let (data, _) = try await URLSession.shared.data(for: request)
//                let decodedResponse = try JSONDecoder().decode(PineconeFetchResponseFromID.self, from: data)
//                let dateFormatter = ISO8601DateFormatter()
//                dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
//                
//                let sortedVectors = decodedResponse.vectors.values.sorted { lhs, rhs in
//                    guard let lhsTimestamp = lhs.metadata["timestamp"],
//                          let rhsTimestamp = rhs.metadata["timestamp"]
//                    else { return false }
//                    
//                    guard let lhsDate = dateFormatter.date(from: lhsTimestamp),
//                          let rhsDate = dateFormatter.date(from: rhsTimestamp)
//                    else { return false }
//                    
//                    return lhsDate > rhsDate
//                }
//                
//                // Safely update properties inside `MainActor.run`
//                await MainActor.run {
//                    self.pineconeFetchedVectors = sortedVectors
//                    self.isDataSorted = true
//                }
//                
//                
//                
//                let readUnits = sortedVectors.count / 10 // A fetch request uses 1 RU for every 10 fetched records.
//                updateTokenUsage(api: APIs.pinecone, tokensUsed: readUnits, read: true)
//                
//                // If the fetch was successful
//                break
//                
//            } catch {
//                attempts += 1
//                if attempts < maxAttempts {
//                    try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
//                } else {
//                    throw error
//                }
//            }
//        }
//    }
//    
//    //MARK: deleteVector
//    func deleteVectorFromPinecone(id: String) async throws {
//        
//        struct DeleteVectorsRequest: Codable {
//            let ids: [String]
//            let namespace: String
//        }
//        
//        guard let namespace = await CKviewModel?.fetchedNamespaceDict.first?.value.namespace else {
//            throw AppCKError.UnableToGetNameSpace
//        }
//        
//        guard let apiKey = ApiConfiguration.pineconeKey else {
//            throw AppNetworkError.apiKeyNotFound
//        }
//        
//        let url = URL(string: "https://memoryindex-g24xjwl.svc.apw5-4e34-81fa.pinecone.io/vectors/delete")!
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.addValue(apiKey, forHTTPHeaderField: "Api-Key")
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//        
//        let deleteRequest = DeleteVectorsRequest(ids: [id], namespace: namespace)
//        let requestData = try JSONEncoder().encode(deleteRequest)
//        request.httpBody = requestData
//        
//        let maxAttempts = 2
//        var attempts = 0
//        
//        while attempts < maxAttempts {
//            do {
//                let (_, response) = try await URLSession.shared.data(for: request)
//                
//                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
//                    
//                    await MainActor.run {
//                        self.vectorDeleted = false
//                    }
//                    
//                    throw AppNetworkError.unknownError("Unable to Delete Info (bad Response).")
//                }
//                await MainActor.run {
//                    self.vectorDeleted = true
//                }
//                updateTokenUsage(api: APIs.pinecone, tokensUsed: 7, read: false)
//                
//                break
//                
//            } catch {
//                attempts += 1
//                if attempts < maxAttempts {
//                    try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
//                } else {
//                    throw error
//                }
//            }
//        }
//    }
//    
//    //MARK: Delete Account
//    func deleteAllVectorsInNamespace() async throws {
//        
//        guard let namespace = await CKviewModel?.fetchedNamespaceDict.first?.value.namespace else {
//            throw AppCKError.UnableToGetNameSpace
//        }
//        
//        guard let apiKey = ApiConfiguration.pineconeKey else {
//            throw AppNetworkError.apiKeyNotFound
//        }
//        
//        struct DeleteAllVectorsRequest: Codable {
//            let deleteAll: Bool
//            let namespace: String
//        }
//        
//        let url = URL(string: "https://memoryindex-g24xjwl.svc.apw5-4e34-81fa.pinecone.io/vectors/delete")!
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.addValue(apiKey, forHTTPHeaderField: "Api-Key")
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.addValue("2024-07", forHTTPHeaderField: "X-Pinecone-API-Version")
//        
//        let deleteRequest = DeleteAllVectorsRequest(deleteAll: true, namespace: namespace)
//        let requestData = try JSONEncoder().encode(deleteRequest)
//        request.httpBody = requestData
//        
//        let maxAttempts = 2
//        var attempts = 0
//        
//        while attempts < maxAttempts {
//            do {
//                let (_, response) = try await URLSession.shared.data(for: request)
//                
//                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
//                    throw AppNetworkError.unknownError("Unable to delete Vectors (bad Response).")
//                }
//                updateTokenUsage(api: APIs.pinecone, tokensUsed: 10, read: false)
//                
//                await MainActor.run {
//                    self.pineconeFetchedVectors = []
//                    self.pineconeIDs = []
//                    self.accountDeleted = true
//                    self.refreshAfterEditing = true
//                }
//                
//                break
//                
//            } catch {
//                attempts += 1
//                if attempts < maxAttempts {
//                    try await Task.sleep(nanoseconds: 200_000_000)
//                } else {
//                    throw error
//                }
//            }
//        }
//    }
//    
//    
//    //MARK: upsertData USED in NewAddInfoView
//    // https://{index_host}/vectors/upsert
//    func upsertDataToPinecone(id: String, vector: [Float], metadata: [String: Any]) async throws {
//        print("Upserting to Pinecone...")
//        
//        await ProgressTracker.shared.setProgress(to: 0.7)
//        guard let url = URL(string: "https://memoryindex-g24xjwl.svc.apw5-4e34-81fa.pinecone.io/vectors/upsert") else {
//            print("upsertDataToPinecone :: Invalid URL")
//            throw AppNetworkError.invalidDBURL
//        }
//        
//        guard let apiKey = ApiConfiguration.pineconeKey else {
//            throw AppNetworkError.apiKeyNotFound
//        }
//        
//        guard let namespace = await CKviewModel?.fetchedNamespaceDict.first?.value.namespace else {
//            throw AppCKError.UnableToGetNameSpace
//        }
//        
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.addValue(apiKey, forHTTPHeaderField: "Api-Key")
//        
//        let payload: [String: Any] = [
//            "vectors": [
//                [
//                    "id": id,
//                    "values": vector,
//                    "metadata": metadata
//                ]
//            ],
//            "namespace": namespace
//        ]
//        await ProgressTracker.shared.setProgress(to: 0.8)
//        
//        do {
//            let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
//            request.httpBody = jsonData
//            await ProgressTracker.shared.setProgress(to: 0.85)
//        } catch {
//            throw AppNetworkError.serializationError("Upsert :: Data")
//        }
//        
//        let maxAttempts = 2
//        var attempts = 0
//        
//        while attempts < maxAttempts {
//            do {
//                let _ = try await performHTTPRequest(request: request)
//                
//                await ProgressTracker.shared.setProgress(to: 0.98)
//                await ProgressTracker.shared.setProgress(to: 0.99)
//                
//                await MainActor.run {
//                    self.upsertSuccesful = true
//                }
//                
//                break
//            } catch {
//                attempts += 1
//                if attempts < maxAttempts {
//                    try await Task.sleep(nanoseconds: 200_000_000)
//                } else {
//                    
//                    throw error
//                }
//            }
//        }
//        updateTokenUsage(api: APIs.pinecone, tokensUsed: 7, read: false)
//    }
//    
//    
//    //MARK: USED in NewAddInfoView
//    private func performHTTPRequest(request: URLRequest) async throws -> Data {
//        
//        try await withCheckedThrowingContinuation { continuation in
//            URLSession.shared.dataTask(with: request) { data, response, error in
//                if let error = error {
//                    continuation.resume(throwing: error)
//                    return
//                }
//                
//                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
//                    continuation.resume(throwing: AppNetworkError.invalidResponse)
//                    return
//                }
//                
//                if let data = data {
//                    continuation.resume(returning: data)
//                } else {
//                    continuation.resume(throwing: AppNetworkError.noDataReceived)
//                }
//            }.resume()
//        }
//    }
//    
//    //MARK: queryPinecone USED in QuestionView
//    //topK = 2 if they prompt to gpt clearly states that second may be irrelevant!
//    
//    func queryPinecone(vector: [Float], topK: Int = 1, includeValues: Bool = false) async throws {
//        let maxAttempts = 2
//        var attempts = 0
//
//        DispatchQueue.main.async {
//            ProgressTracker.shared.setProgress(to: 0.42)
//        }
//
//        while attempts < maxAttempts {
//            var taskResults = [Result<Void, Error>]()
//
//            await withTaskGroup(of: Result<Void, Error>.self) { taskGroup in
//                taskGroup.addTask(priority: .background) { [weak self] in
//                    guard let self = self else { return .failure(AppCKError.UnableToGetNameSpace) }
//                    do {
//                        try await self.performQueryPinecone(vector: vector, topK: topK, includeValues: includeValues)
//                        return .success(())
//                    } catch {
//                        // Use `await` here to ensure we're inside the actor's context when updating `receivedError`
//                        await self.updateReceivedError(error: error)
//                        return .failure(error)
//                    }
//                }
//
//                for await result in taskGroup {
//                    taskResults.append(result)
//                }
//            }
//
//            // Check the results of the tasks
//            if let firstError = taskResults.compactMap({ try? $0.get() }).isEmpty ? taskResults.compactMap({ result -> Error? in
//                if case .failure(let error) = result {
//                    return error
//                }
//                return nil
//            }).first : nil {
//                attempts += 1
//                if attempts < maxAttempts {
//                    try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
//                } else {
//                    throw firstError
//                }
//            } else {
//                break
//            }
//        }
//    }
//
//    // Helper function to update `receivedError` safely within the actor's context
//    func updateReceivedError(error: Error) async {
//        await MainActor.run {
//            self.receivedError = error
//        }
//    }
//    
//    private func performQueryPinecone(vector: [Float], topK: Int, includeValues: Bool) async throws {
//        guard let url = URL(string: "https://memoryindex-g24xjwl.svc.apw5-4e34-81fa.pinecone.io/query") else {
//            fatalError("Invalid Pinecone URL")
//        }
//        
//        guard let apiKey = ApiConfiguration.pineconeKey else {
//            fatalError("Pinecone API Key not found")
//        }
//        
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.addValue(apiKey, forHTTPHeaderField: "Api-Key")
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//        
//        // Capture necessary data from self before entering the task
//        guard let namespace = await CKviewModel?.fetchedNamespaceDict.first?.value.namespace else {
//            throw AppCKError.UnableToGetNameSpace
//        }
//        
//        DispatchQueue.main.async {
//            ProgressTracker.shared.setProgress(to: 0.45)
//        }
//        
//        let requestBody: [String: Any] = [
//            "vector": vector,
//            "topK": topK,
//            "includeValues": includeValues,
//            "includeMetadata": true,
//            "namespace": namespace
//        ]
//        
//        let jsonData = try JSONSerialization.data(withJSONObject: requestBody, options: [])
//        request.httpBody = jsonData
//        
//        let (data, response) = try await URLSession.shared.data(for: request)
//        
//        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
//            throw AppNetworkError.invalidResponse
//        }
//        
//        let decoder = JSONDecoder()
//        let pineconeResponse = try decoder.decode(PineconeQueryResponse.self, from: data)
//        
//        
//        await ProgressTracker.shared.setProgress(to: 0.55)
//        await MainActor.run {
//            self.pineconeQueryResponse = pineconeResponse
//        }
//        
//        
//        DispatchQueue.main.async {
//            ProgressTracker.shared.setProgress(to: 0.62)
//        }
//        let queryResponse = await MainActor.run { [weak self] in
//            return self?.pineconeQueryResponse
//        }
//        
//        if let response = queryResponse {
//            updateTokenUsage(api: APIs.pinecone, tokensUsed: response.usage.readUnits, read: true)
//        }
//    }
//    
//}
