//
//  PineconeManager.swift
//  Memory
//
//  Created by Evangelos Spyromilios on 13.02.24.
//

import Foundation
import Combine
import CloudKit
import SwiftUI

// memoryindex HOST: https://memoryindex-g24xjwl.svc.apw5-4e34-81fa.pinecone.io

//MARK: create new index.
final class PineconeManager: ObservableObject {
  

    var CKviewModel: CloudKitViewModel
    @Published var indexesList: String?
    @Published var indexDetails: String?
    @Published var receivedError: Error?
    @Published var indexInfo: String?
    @Published var pineconeQueryResponse: PineconeQueryResponse?
    @Published var upsertSuccesful: Bool = false
    @Published var vectorDeleted: Bool = false
    @Published var accountDeleted: Bool = false

    var isDataSorted: Bool = false
   
    @Published var pineconeIDResponse: PineconeIDResponse?
    @Published var pineconeIDs: [String] = []
    @Published var pineconeFetchedResponseFromID: PineconeFetchResponseFromID?
    @Published var pineconeFetchedVectors: [Vector] = []
    var pineconeIndex: String?
    var cancellables = Set<AnyCancellable>()
    @Published var refreshAfterEditing: Bool = false

    
    init(cloudKitViewModel: CloudKitViewModel = .shared) {
            self.CKviewModel = cloudKitViewModel
        }
    
    func clearManager() async {
        await MainActor.run {
            receivedError = nil
            pineconeQueryResponse = nil
            upsertSuccesful = false
        }
    }
    
    //deletes localy
    func deleteVector(withId id: String) {
            pineconeFetchedVectors.removeAll { $0.id == id }
        }
 
    func refreshNamespacesIDs() async throws {
        do {
            try await fetchAllNamespaceIDs()
            try await fetchDataForIds()
        } catch {
            throw error
        }
    }
    
    func fetchAllNamespaceIDs() async throws {
        guard let namespace = CKviewModel.fetchedNamespaceDict.first?.value.namespace else {
            throw AppCKError.UnableToGetNameSpace
        }

        guard let apiKey = ApiConfiguration.pineconeKey else {
            throw AppNetworkError.apiKeyNotFound
        }

        guard let url = URL(string: "https://memoryindex-g24xjwl.svc.apw5-4e34-81fa.pinecone.io/vectors/list?namespace=\(namespace)") else {
            throw AppNetworkError.unknownError("fetchAllNamespaceIDs() :: Invalid URL")
        }

        var request = URLRequest(url: url)
        request.addValue(apiKey, forHTTPHeaderField: "Api-Key")
        request.httpMethod = "GET"

        let maxAttempts = 2
        var attempts = 0

        while attempts < maxAttempts {
            do {
                let (data, _) = try await URLSession.shared.data(for: request)
                let decodedResponse = try JSONDecoder().decode(PineconeIDResponse.self, from: data)

                await MainActor.run {
                    self.pineconeIDResponse = decodedResponse

                    if let idResponse = self.pineconeIDResponse {
                        self.pineconeIDs.append(contentsOf: idResponse.vectors.map { $0.id })
                    }
                }

                if !self.isDataSorted || self.refreshAfterEditing {
                    do {
                        try await fetchDataForIds()
                    } catch {
                        throw error
                    }
                }

                // 1RU per call
                updateTokenUsage(api: APIs.pinecone, tokensUsed: 1, read: true)

                // If successful, break the loop
                break

            } catch {
                attempts += 1
                if attempts < maxAttempts {
//                    print("Attempt \(attempts) failed, retrying after 0.1 seconds...")
                    try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
                } else {
//                    print("All attempts failed.")
                    throw error
                }
            }
        }
    }

    //MARK: New for proper sorting
    private func fetchDataForIds() async throws {
        guard let namespace = CKviewModel.fetchedNamespaceDict.first?.value.namespace else {
            throw AppCKError.UnableToGetNameSpace
        }

        guard let apiKey = ApiConfiguration.pineconeKey else {
            throw AppNetworkError.apiKeyNotFound
        }

        var urlComponents = URLComponents(string: "https://memoryindex-g24xjwl.svc.apw5-4e34-81fa.pinecone.io/vectors/fetch")!
        urlComponents.queryItems = self.pineconeIDs.map { URLQueryItem(name: "ids", value: $0) }
        urlComponents.queryItems?.append(URLQueryItem(name: "namespace", value: namespace))

        guard let url = urlComponents.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.addValue(apiKey, forHTTPHeaderField: "Api-Key")
        request.httpMethod = "GET"

        let maxAttempts = 2
        var attempts = 0

        while attempts < maxAttempts {
            do {
                let (data, _) = try await URLSession.shared.data(for: request)
                let decodedResponse = try JSONDecoder().decode(PineconeFetchResponseFromID.self, from: data)
                let dateFormatter = ISO8601DateFormatter()
                dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

                let sortedVectors = decodedResponse.vectors.values.sorted { lhs, rhs in

                    guard let lhsTimestamp = lhs.metadata["timestamp"],
                          let rhsTimestamp = rhs.metadata["timestamp"]
                    else { return false }

                    guard let lhsDate = dateFormatter.date(from: lhsTimestamp),
                          let rhsDate = dateFormatter.date(from: rhsTimestamp)
                    else { return false }

                    return lhsDate > rhsDate
                }

                await MainActor.run {
                    self.pineconeFetchedVectors = sortedVectors
                    isDataSorted = true
                }

                let readUnits = self.pineconeFetchedVectors.count / 10 // A fetch request uses 1 RU for every 10 fetched records.
                updateTokenUsage(api: APIs.pinecone, tokensUsed: readUnits, read: true)

                //if the fetch was successful
                break

            } catch {
                attempts += 1
                if attempts < maxAttempts {
                    try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
                } else {
                    throw error
                }
            }
        }
    }

//MARK: deleteVector
    func deleteVectorFromPinecone(id: String) async throws {
        
        struct DeleteVectorsRequest: Codable {
            let ids: [String]
            let namespace: String
        }
        
        guard let namespace = CKviewModel.fetchedNamespaceDict.first?.value.namespace else {
            throw AppCKError.UnableToGetNameSpace
        }
        
        guard let apiKey = ApiConfiguration.pineconeKey else {
            throw AppNetworkError.apiKeyNotFound
        }
        
        let url = URL(string: "https://memoryindex-g24xjwl.svc.apw5-4e34-81fa.pinecone.io/vectors/delete")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(apiKey, forHTTPHeaderField: "Api-Key")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let deleteRequest = DeleteVectorsRequest(ids: [id], namespace: namespace)
        let requestData = try JSONEncoder().encode(deleteRequest)
        request.httpBody = requestData
        
        let maxAttempts = 2
        var attempts = 0
        
        while attempts < maxAttempts {
            do {
                let (_, response) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {

                    DispatchQueue.main.async {
                        self.vectorDeleted = false
                    }
                    throw AppNetworkError.unknownError("Unable to Delete Info (bad Response).")
                }
                
                DispatchQueue.main.async {
                    self.vectorDeleted = true
                    updateTokenUsage(api: APIs.pinecone, tokensUsed: 7, read: false)
                }
                break
                
            } catch {
                attempts += 1
                if attempts < maxAttempts {
                    try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
                } else {
                    throw error
                }
            }
        }
    }
    
    //MARK: Delete Account
    func deleteAllVectorsInNamespace() async throws {
        
        guard let namespace = CKviewModel.fetchedNamespaceDict.first?.value.namespace else {
            throw AppCKError.UnableToGetNameSpace
        }
        
        guard let apiKey = ApiConfiguration.pineconeKey else {
            throw AppNetworkError.apiKeyNotFound
        }
        
        struct DeleteAllVectorsRequest: Codable {
            let deleteAll: Bool
            let namespace: String
        }
        
        let url = URL(string: "https://memoryindex-g24xjwl.svc.apw5-4e34-81fa.pinecone.io/vectors/delete")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(apiKey, forHTTPHeaderField: "Api-Key")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("2024-07", forHTTPHeaderField: "X-Pinecone-API-Version")
        
        let deleteRequest = DeleteAllVectorsRequest(deleteAll: true, namespace: namespace)
        let requestData = try JSONEncoder().encode(deleteRequest)
        request.httpBody = requestData
        
        let maxAttempts = 2
        var attempts = 0
        
        while attempts < maxAttempts {
            do {
                let (_, response) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                    throw AppNetworkError.unknownError("Unable to delete Vectors (bad Response).")
                }
                updateTokenUsage(api: APIs.pinecone, tokensUsed: 10, read: false)
                await MainActor.run {
                    self.pineconeFetchedVectors = []
                    self.pineconeIDs = []
                    self.accountDeleted = true
                    self.refreshAfterEditing = true
                }
                break
                
            } catch {
                attempts += 1
                if attempts < maxAttempts {
                    try await Task.sleep(nanoseconds: 200_000_000)
                } else {
                    throw error
                }
            }
        }
    }


    
    //MARK: Developer View DEPRICATED
//    func listPineconeIndexes() {
//        guard let url = URL(string: "https://api.pinecone.io/indexes") else {
//            print("listPineconeIndexes :: Invalid URL")
//            return
//        }
//        
//        guard let apiKey = ApiConfiguration.pineconeKey else {
//            print("listPineconeIndexes :: unable to get the api key.")
//            return
//        }
//        print("Using API Key: \(apiKey)")
//        var request = URLRequest(url: url)
//        request.httpMethod = "GET"
//        request.addValue(apiKey, forHTTPHeaderField: "Api-Key")
//        
//        let task = URLSession.shared.dataTask(with: request) { data, response, error in
//            guard let data = data, error == nil else {
//                print("Error listing Pinecone indexes: \(error?.localizedDescription ?? "Unknown error")")
//                return
//            }
////            if let httpResponse = response as? HTTPURLResponse {
////                    print("listPineconeIndexes :: HTTP Status Code: \(httpResponse.statusCode)")
////                    print("listPineconeIndexes :: Response Headers: \(httpResponse.allHeaderFields)")
////                }
//            
//            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
//                if let indexesList = String(data: data, encoding: .utf8) {
//                    DispatchQueue.main.async {
//                        self.indexesList = indexesList
//                        print("list Pinecone indexes :: status code OK")
//                    }
//                }
//            } else {
//                print("Failed to list indexes. HTTP Status Code: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
////                throw AppNetworkError.unknownError("Failed to List: \(response as? HTTPURLResponse)?.statusCode ?? -1)")
//                
//            }
//        }
//        task.resume()
//    }
    
    //OLD DEVELOPER VIEW
//    func getIndexInfo(indexName: String) {
//        
//        guard let indexName = UserDefaults.standard.string(forKey: "pineconeIndexName") else {
//            print("PineConeManager :: getIndexInfo :: unable to get indexName")
//            return
//        }
//        
//        guard let url = URL(string: "https://api.pinecone.io/indexes/\(indexName)") else {
//            print("Invalid URL")
//            return
//        }
//        
//        guard let apiKey = ApiConfiguration.pineconeKey else {
//            print("getindexInfo :: unable to get the  api key.")
//            return
//        }
//        
//        var request = URLRequest(url: url)
//        request.httpMethod = "GET"
//        request.addValue(apiKey, forHTTPHeaderField: "Api-Key")
//        
//        let task = URLSession.shared.dataTask(with: request) { data, response, error in
//            // Check for errors
//            if let error = error {
//                print("Error fetching index info: \(error.localizedDescription)")
//                return
//            }
//            
//            // Check the response code
//            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
//                print("Failed to fetch index info. HTTP Status Code: \((response as? HTTPURLResponse)?.statusCode ?? -1)") //TODO: Hits here with status 401
//                return
//            }
//            
//            // Parse the response data
//            guard let data = data, let responseData = String(data: data, encoding: .utf8) else {
//                print("Failed to decode response data")
//                return
//            }
//            DispatchQueue.main.async {
//                self.indexInfo = responseData
//            }
//            print("Index info: \(responseData)")
//        }
//        task.resume()
//    }
    

    //DEVELOPER VIEW
//    func checkPineconeIndex(indexName: String = "memoryindex") {
//        guard let url = URL(string: "https://memoryindex-g24xjwl.svc.apw5-4e34-81fa.pinecone.io") else {
//            print("Invalid  URL")
//            return
//        }
//        
//        guard let apiKey = ApiConfiguration.pineconeKey else {
//            print("checkPineconeIndex :: unable to get the  api key.")
//            return
//        }
//        
//        var request = URLRequest(url: url)
//        request.httpMethod = "GET"
//        request.addValue(apiKey, forHTTPHeaderField: "Api-Key")
//        request.addValue("application/json", forHTTPHeaderField: "accept")
//        
//        let task = URLSession.shared.dataTask(with: request) { data, response, error in
//            guard let httpResponse = response as? HTTPURLResponse else {
//                print("Error: No response from server")
//                return
//            }
//            
//            if httpResponse.statusCode == 200 {
//                print("Index \(indexName) exists.")
//                if let data = data, let responseData = String(data: data, encoding: .utf8) {
//                    DispatchQueue.main.async {
//                        self.indexDetails = responseData
//                    }
//                } else { print("some error getting the responseData") }
//            } else if httpResponse.statusCode == 404 {
//                print("Index \(indexName) does not exist.")
//            } else {
//                print("Received unexpected status code: \(httpResponse.statusCode)")
//            }
//        }
//        task.resume()
//    }
    
    //MARK: upsertData USED in NewAddInfoView
    // https://{index_host}/vectors/upsert
    func upsertDataToPinecone(id: String, vector: [Float], metadata: [String: Any]) async throws {
        print("Upserting to Pinecone...")

        ProgressTracker.shared.setProgress(to: 0.7)
        guard let url = URL(string: "https://memoryindex-g24xjwl.svc.apw5-4e34-81fa.pinecone.io/vectors/upsert") else {
            print("upsertDataToPinecone :: Invalid URL")
            throw AppNetworkError.invalidDBURL
        }
        
        guard let apiKey = ApiConfiguration.pineconeKey else {
            throw AppNetworkError.apiKeyNotFound
        }
        
        guard let namespace = CKviewModel.fetchedNamespaceDict.first?.value.namespace else {
            throw AppCKError.UnableToGetNameSpace
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(apiKey, forHTTPHeaderField: "Api-Key")
        
        let payload: [String: Any] = [
            "vectors": [
                [
                    "id": id,
                    "values": vector,
                    "metadata": metadata
                ]
            ],
            "namespace": namespace
        ]
        ProgressTracker.shared.setProgress(to: 0.8)
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
            request.httpBody = jsonData
            ProgressTracker.shared.setProgress(to: 0.85)
        } catch {
            throw AppNetworkError.serializationError("Upsert :: Data")
        }
        
        let maxAttempts = 2
        var attempts = 0

        while attempts < maxAttempts {
            do {
                let _ = try await performHTTPRequest(request: request)
                await MainActor.run {
                    self.upsertSuccesful = true
                    ProgressTracker.shared.setProgress(to: 0.98)
                    ProgressTracker.shared.setProgress(to: 0.99)
                }
                break
            } catch {
                attempts += 1
                if attempts < maxAttempts {
                    try await Task.sleep(nanoseconds: 200_000_000)
                } else {
                    
                    throw error
                }
            }
        }
        updateTokenUsage(api: APIs.pinecone, tokensUsed: 7, read: false)
    }


    //MARK: USED in NewAddInfoView
    private func performHTTPRequest(request: URLRequest) async throws -> Data {

        try await withCheckedThrowingContinuation { continuation in
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    continuation.resume(throwing: AppNetworkError.invalidResponse)
                    return
                }
                
                if let data = data {
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(throwing: AppNetworkError.noDataReceived)
                }
            }.resume()
        }
    }

    //MARK: queryPinecone USED in QuestionView
    //topK = 2 if they prompt to gpt clearly states that second may be irrelevant!
    
    func queryPinecone(vector: [Float], topK: Int = 1, includeValues: Bool = false) async throws {
        let maxAttempts = 2
        var attempts = 0

        DispatchQueue.main.async {
            ProgressTracker.shared.setProgress(to: 0.42)
        }

        while attempts < maxAttempts {
            var taskResults = [Result<Void, Error>]()

            await withTaskGroup(of: Result<Void, Error>.self) { taskGroup in
                taskGroup.addTask(priority: .background) { [weak self] in
                    guard let self = self else { return .failure(AppCKError.UnableToGetNameSpace) }
                    do {
                        try await self.performQueryPinecone(vector: vector, topK: topK, includeValues: includeValues)
                        return .success(())
                    } catch {
                        await MainActor.run {
                            self.receivedError = error
                        }
//                        print("Error querying Pinecone: \(error)")
                        return .failure(error)
                    }
                }

                for await result in taskGroup {
                    taskResults.append(result)
                }
            }

            // Check the results of the tasks
            if let firstError = taskResults.compactMap({ try? $0.get() }).isEmpty ? taskResults.compactMap({ result -> Error? in
                if case .failure(let error) = result {
                    return error
                }
                return nil
            }).first : nil {
                attempts += 1
                if attempts < maxAttempts {
//                    print("Attempt \(attempts) failed, retrying after 0.1 seconds...")
                    try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
                } else {
//                    print("All attempts failed.")
                    throw firstError
                }
            } else {
                break
            }
        }
    }

    private func performQueryPinecone(vector: [Float], topK: Int, includeValues: Bool) async throws {
        guard let url = URL(string: "https://memoryindex-g24xjwl.svc.apw5-4e34-81fa.pinecone.io/query") else {
            fatalError("Invalid Pinecone URL")
        }
        
        guard let apiKey = ApiConfiguration.pineconeKey else {
            fatalError("Pinecone API Key not found")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(apiKey, forHTTPHeaderField: "Api-Key")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        guard let namespace = CKviewModel.fetchedNamespaceDict.first?.value.namespace else {
            throw AppCKError.UnableToGetNameSpace
        }
        
        DispatchQueue.main.async {
            ProgressTracker.shared.setProgress(to: 0.45)
        }

        let requestBody: [String: Any] = [
            "vector": vector,
            "topK": topK,
            "includeValues": includeValues,
            "includeMetadata": true,
            "namespace": namespace
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        request.httpBody = jsonData

        let (data, response) = try await URLSession.shared.data(for: request)

//        if let responseBody = String(data: data, encoding: .utf8) {
//            print("Response Body: \(responseBody)")
//        }
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {

            throw AppNetworkError.invalidResponse
        }

        let decoder = JSONDecoder()
        let pineconeResponse = try decoder.decode(PineconeQueryResponse.self, from: data)

        await MainActor.run {
            ProgressTracker.shared.setProgress(to: 0.55)
            self.pineconeQueryResponse = pineconeResponse
        }

//        for _ in pineconeResponse.matches {
//            print("Match ID: \(match.id), Score: \(match.score)")
//            print("Query Response: \(match.metadata.debugDescription)")
//        }
        DispatchQueue.main.async {
            ProgressTracker.shared.setProgress(to: 0.62)
        }

        if let response = self.pineconeQueryResponse {
            updateTokenUsage(api: APIs.pinecone, tokensUsed: response.usage.readUnits, read: true)
        }
    }

}
