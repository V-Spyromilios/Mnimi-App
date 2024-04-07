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
    
    private var isDataSorted: Bool = false
   
    @Published var pineconeIDResponse: PineconeIDResponse?
    @Published var pineconeIDs: [String] = []
    @Published var pineconeFetchedResponseFromID: PineconeFetchResponseFromID?
    @Published var pineconeFetchedVectors: [Vector] = []
    @Published var progressText: String = ""
    var pineconeIndex: String?
    var cancellables = Set<AnyCancellable>()
    
    
    init(cloudKitViewModel: CloudKitViewModel = .shared) {
            self.CKviewModel = cloudKitViewModel

   
        }
    
    func clearManager() {
        progressText = ""
        receivedError = nil
        pineconeQueryResponse = nil
        upsertSuccesful = false
        
    }
    
    private func getIDs() {
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 1.3) {
            Task {
                do {
                    try await self.fetchAllNamespaceIDs()
                } catch {
                    print("Error fetchAllNamespaceIDs: \(error)")
                }
            }
        }
    }
//    var pineconeIndexCreated: Bool {
//        didSet {
//            UserDefaults.standard.set(pineconeIndexCreated, forKey: "pineconeIndexCreated")
//        }
//    }
//    
    
//    init() {
//        pineconeIndexCreated = UserDefaults.standard.bool(forKey: "pineconeIndexCreated") //if not exist defaults to false
//    }
//    
//    func createPineconeIndex(indexName: String, dimension: Int = 3072) {
//        
//        guard let url = URL(string: "https://api.pinecone.io/v1/indexes/\(indexName)") else { return }
//        
//        guard let apiKey = ApiConfiguration.pineconeKey else {
//            print("checkPineconeIndex :: unable to get the api key.")
//            return
//        }
//        
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.addValue("ApiKey \(apiKey)", forHTTPHeaderField: "Authorization")
//        
//        let requestBody: [String: Any] = [
//            "dimension": dimension,
//            "metric": "cosine"
//        ]
//        
//        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
//        
//        let task = URLSession.shared.dataTask(with: request) { data, response, error in
//            guard let data = data, error == nil else {
//                print("Error creating index: \(error?.localizedDescription ?? "Unknown error")")
//                return
//            }
//            
//            print("Index created successfully:", String(data: data, encoding: .utf8) ?? "")
//            self.pineconeIndexCreated = true
//            UserDefaults.standard.set(indexName, forKey: "pineconeIndexName")
//        }
//        task.resume()
//    }

    func fetchAllNamespaceIDs() async throws {
        
        guard let namespace = CKviewModel.fetchedNamespaceDict.first?.value.namespace else {
            throw AppCKError.UnableToGetNameSpace
        }
        
        guard let apiKey = ApiConfiguration.pineconeKey else {
            throw AppNetworkError.apiKeyNotFound
        }
        
        guard let url = URL(string: "https://memoryindex-g24xjwl.svc.apw5-4e34-81fa.pinecone.io/vectors/list?namespace=\(namespace)") else {
            throw AppNetworkError.unknownError("fetchAllNamespaceIDs() :: Invalid URL to fetch!")
        }
        
        var request = URLRequest(url: url)
        request.addValue(apiKey, forHTTPHeaderField: "Api-Key")
        request.httpMethod = "GET"
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        let decodedResponse = try JSONDecoder().decode(PineconeIDResponse.self, from: data)
        
        await MainActor.run { //TODO: too slow for main thread ??
            self.pineconeIDResponse = decodedResponse
            
            
            if let idResponse = self.pineconeIDResponse {
                
                for vector in idResponse.vectors {
                    self.pineconeIDs.append(vector.id)
                }
            }
        }
        if !self.isDataSorted {
            do {
                try await fetchDataForIds()
                
            } catch {
                print("Error  fetchDataForIds():: \(error)")
            }
        }
    }
    
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
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        let decodedResponse = try JSONDecoder().decode(PineconeFetchResponseFromID.self, from: data)
        let dateFormatter = ISO8601DateFormatter()
        let sortedVectors = decodedResponse.vectors.map { (id, vector) -> Vector in
            // given that `Vector(metadata:)`  & has the timestamp in the metadata
            Vector(id: id, metadata: vector.metadata)
        }
            .sorted { lhs, rhs in
                guard let lhsTimestamp = lhs.metadata["relevantFor"], //TODO: change to timestamp
                      let rhsTimestamp = rhs.metadata["relevantFor"],
                      let lhsDate = dateFormatter.date(from: lhsTimestamp),
                      let rhsDate = dateFormatter.date(from: rhsTimestamp) else {
                    return false
                }
                return lhsDate > rhsDate // Sort in descending order; use `<` for ascending
            }
        
        await MainActor.run {
//            self.pineconeFetchedResponseFromID = decodedResponse
            self.pineconeFetchedVectors = sortedVectors
        }
        self.isDataSorted = true
    }

    func deleteVector(id: String) async throws -> Bool {
        
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
        
        let (_, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            // Handle non-200 responses or throw an error as needed
            print("Failed to delete vectors. Status code: \(httpResponse.statusCode)")
            return false
        }

        print("Vectors successfully deleted")
        return true
    }

    
    func listPineconeIndexes() {
        guard let url = URL(string: "https://api.pinecone.io/indexes") else {
            print("Invalid URL")
            return
        }
        
        guard let apiKey = ApiConfiguration.pineconeKey else {
            print("checkPineconeIndex :: unable to get the api key.")
            return
        }
        print("Using API Key: \(apiKey)")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(apiKey, forHTTPHeaderField: "Api-Key")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Error listing Pinecone indexes: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                    print("HTTP Status Code: \(httpResponse.statusCode)")
                    print("Response Headers: \(httpResponse.allHeaderFields)")
                }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                if let indexesList = String(data: data, encoding: .utf8) {
                    DispatchQueue.main.async {
                        self.indexesList = indexesList
                        print("list Pinecone indexes :: status code OK")
                    }
                }
            } else {
                print("Failed to list indexes. HTTP Status Code: \((response as? HTTPURLResponse)?.statusCode ?? -1)") //TODO: Hits here with status 401
                
            }
        }
        task.resume()
    }
    
    func getIndexInfo(indexName: String) {
        
        guard let indexName = UserDefaults.standard.string(forKey: "pineconeIndexName") else {
            print("PineConeManager :: getIndexInfo :: unable to get indexName")
            return
        }
        
        guard let url = URL(string: "https://api.pinecone.io/indexes/\(indexName)") else {
            print("Invalid URL")
            return
        }
        
        guard let apiKey = ApiConfiguration.pineconeKey else {
            print("getindexInfo :: unable to get the  api key.")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(apiKey, forHTTPHeaderField: "Api-Key")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // Check for errors
            if let error = error {
                print("Error fetching index info: \(error.localizedDescription)")
                return
            }
            
            // Check the response code
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Failed to fetch index info. HTTP Status Code: \((response as? HTTPURLResponse)?.statusCode ?? -1)") //TODO: Hits here with status 401
                return
            }
            
            // Parse the response data
            guard let data = data, let responseData = String(data: data, encoding: .utf8) else {
                print("Failed to decode response data")
                return
            }
            DispatchQueue.main.async {
                self.indexInfo = responseData
            }
            print("Index info: \(responseData)")
        }
        task.resume()
    }
    

    func checkPineconeIndex(indexName: String = "memoryindex") {
        guard let url = URL(string: "https://memoryindex-g24xjwl.svc.apw5-4e34-81fa.pinecone.io") else {
            print("Invalid  URL")
            return
        }
        
        guard let apiKey = ApiConfiguration.pineconeKey else {
            print("checkPineconeIndex :: unable to get the  api key.")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(apiKey, forHTTPHeaderField: "Api-Key")
        request.addValue("application/json", forHTTPHeaderField: "accept")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Error: No response from server")
                return
            }
            
            if httpResponse.statusCode == 200 {
                print("Index \(indexName) exists.")
                if let data = data, let responseData = String(data: data, encoding: .utf8) {
                    DispatchQueue.main.async {
                        self.indexDetails = responseData
                    }
                } else { print("some error getting the responseData") }
            } else if httpResponse.statusCode == 404 {
                print("Index \(indexName) does not exist.")
            } else {
                print("Received unexpected status code: \(httpResponse.statusCode)")
            }
        }
        task.resume()
    }
    
    //MARK: upsertData
    // https://{index_host}/vectors/upsert
    func upsertDataToPinecone(id: String, vector: [Float], metadata: [String: Any]) async throws {
        print("Upserting to Pinecone...")
        await MainActor.run {
            progressText = "Upserting to Database..."
        }
        ProgressTracker.shared.setProgress(to: 0.7)
        guard let url = URL(string: "https://memoryindex-g24xjwl.svc.apw5-4e34-81fa.pinecone.io/vectors/upsert") else {
            throw AppNetworkError.unknownError("upsertDataToPinecone() :: Invalid URL to upsert!")
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
        
        var payload: [String: Any] = [
            "vectors": [
                [
                    "id": id,
                    "values": vector,
                    "metadata": metadata
                ]
            ],
            "namespace": namespace
        ]
        await MainActor.run {
            progressText = "Attached vectors to payload."
            ProgressTracker.shared.setProgress(to: 0.8)
        }
        guard let namespace = CKviewModel.fetchedNamespaceDict.first?.value.namespace else { throw AppCKError.UnableToGetNameSpace }

        payload["namespace"] = namespace
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
            request.httpBody = jsonData
            ProgressTracker.shared.setProgress(to: 0.85)
        } catch {
            throw AppNetworkError.serializationError("Upsert :: jsonData")
        }
        
        do {
            let _ = try await performHTTPRequest(request: request)
            await MainActor.run {
                self.upsertSuccesful = true
//                let stringDictionary: [String: String] = metadata.compactMapValues { value in
//                    // Try to convert each value to a String
//                    if let stringValue = value as? String {
//                        return stringValue // Return the string value if successful
//                    } else {
//                        // If the value is not a String, you could convert it to a string
//                        // or return nil to exclude it from the resulting dictionary
//                        return "\(value)" // Convert non-string values to String
//                        // return nil // Exclude non-string values
//                    }
//                }
                
                //save id and metadata to SwiftData, id is used to delete from Pinecone
                
                ProgressTracker.shared.setProgress(to: 0.99)
                progressText = "Info saved!"
                ProgressTracker.shared.setProgress(to: 1.0)
                print("Upsert successful !")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                    self?.progressText = ""
                }
            }
        } catch {
            throw AppNetworkError.unknownError(error.localizedDescription)
        }
    }

    private func performHTTPRequest(request: URLRequest) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    let errorDescription = "Invalid response: \(response.debugDescription)"
                    continuation.resume(throwing: NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: errorDescription]))
                    return
                }
                
                if let data = data {
                    continuation.resume(returning: data)
                } else {
                    let noDataError = NSError(domain: "", code: 1, userInfo: [NSLocalizedDescriptionKey: "No data received"])
                    continuation.resume(throwing: noDataError)
                }
            }.resume()
        }
    }

    //MARK: queryPinecone
    func queryPinecone(vector: [Float], metadata: [String: String], topK: Int = 1, includeValues: Bool = false) async throws {

        ProgressTracker.shared.setProgress(to: 0.4)
        await MainActor.run {
            progressText = "Querying Database..."
        }
        await withTaskGroup(of: Void.self) { taskGroup in
            taskGroup.addTask(priority: .background) { [weak self] in
                guard let self = self else { return }
                do {
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


                    guard let namespace = CKviewModel.fetchedNamespaceDict.first?.value.namespace else { throw AppCKError.UnableToGetNameSpace
                    } //TODO: lack of 'await' was returning Error, WHY is not func!?
                    ProgressTracker.shared.setProgress(to: 0.45)
                    print("Namespace: \(namespace)")
                    let requestBody: [String: Any] = [
                        "vector": vector,
                        "topK": topK,
                        // "metadata": metadata,
                        "includeValues": includeValues,
                        "includeMetadata": true,
                        "namespace": namespace
                    ]
                    
                    let jsonData = try JSONSerialization.data(withJSONObject: requestBody, options: [])
                    request.httpBody = jsonData

                    let (data, response) = try await URLSession.shared.data(for: request)

//                    if let responseBody = String(data: data, encoding: .utf8) {
//                                print("Response Body: \(responseBody)")
//                            }
                    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                       print("queryPinecone Response Status Code != 200")
                        return
                    }
                   

                    let decoder = JSONDecoder()
                    let pineconeResponse = try decoder.decode(PineconeQueryResponse.self, from: data)

                    await MainActor.run {
                        ProgressTracker.shared.setProgress(to: 0.55)
                        self.progressText = "Database Response: \(httpResponse.statusCode)"
                        self.pineconeQueryResponse = pineconeResponse
                    }

                    for match in pineconeResponse.matches {
                        print("Match ID: \(match.id), Score: \(match.score)")
                        print("Query Response: \(match.metadata.debugDescription)")
                    }
                    ProgressTracker.shared.setProgress(to: 0.6)
                } catch {
                    print("Error querying Pinecone: \(error)")
                }
            }
        }
        
        await MainActor.run {
            self.progressText = ""
        }
    }

}
