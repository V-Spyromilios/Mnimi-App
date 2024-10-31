//
//  PineconeActor.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 26.10.24.
//

import Foundation
import Combine
import CloudKit
import SwiftUI

actor PineconeActor {
    // MARK: - Properties
    private let ckViewModel: CloudKitViewModel
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer
    init(cloudKitViewModel: CloudKitViewModel = .shared) {
        self.ckViewModel = cloudKitViewModel
    }

    // MARK: - Methods

    // Refresh Namespaces and IDs
    func refreshNamespacesIDs() async throws -> [Vector] {
        do {
            let pineconeIDs = try await fetchAllNamespaceIDs()
            let pineconeFetchedVectors = try await fetchDataForIds(pineconeIDs: pineconeIDs)
            return pineconeFetchedVectors
            // Since the actor does not hold a reference to the ViewModel, the results will be returned to the ViewModel
        } catch {
            throw error
        }
    }

    // Fetch All Namespace IDs
    private func fetchAllNamespaceIDs() async throws -> [String] {
        guard let namespace = await ckViewModel.fetchedNamespaceDict.first?.value.namespace else {
            throw AppCKError.UnableToGetNameSpace
        }

        guard let apiKey = ApiConfiguration.pineconeKey else {
            throw AppNetworkError.apiKeyNotFound
        }

        guard let url = URL(string: "https://memoryindex-g24xjwl.svc.example.pinecone.io/vectors/list?namespace=\(namespace)") else {
            throw AppNetworkError.unknownError("Invalid URL")
        }

        var request = URLRequest(url: url)
        request.addValue(apiKey, forHTTPHeaderField: "Api-Key")
        request.httpMethod = "GET"

        let (data, _) = try await URLSession.shared.data(for: request)
        let decodedResponse = try JSONDecoder().decode(PineconeIDResponse.self, from: data)

        let ids = decodedResponse.vectors.map { $0.id }

        // Update token usage or any other necessary operations
        updateTokenUsage(api: APIs.pinecone, tokensUsed: 1, read: true)

        return ids
    }

    // Fetch Data for IDs
    func fetchDataForIds(pineconeIDs: [String]) async throws -> [Vector] {
        guard let namespace = await ckViewModel.fetchedNamespaceDict.first?.value.namespace else {
            throw AppCKError.UnableToGetNameSpace
        }

        guard let apiKey = ApiConfiguration.pineconeKey else {
            throw AppNetworkError.apiKeyNotFound
        }

        let queryItems: [URLQueryItem] = pineconeIDs.map { URLQueryItem(name: "ids", value: $0) }

        var urlComponents = URLComponents(string: "https://memoryindex-g24xjwl.svc.example.pinecone.io/vectors/fetch")!
        urlComponents.queryItems = queryItems
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
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let sortedVectors = decodedResponse.vectors.values.sorted { lhs, rhs in
            guard let lhsTimestamp = lhs.metadata["timestamp"],
                  let rhsTimestamp = rhs.metadata["timestamp"],
                  let lhsDate = dateFormatter.date(from: lhsTimestamp),
                  let rhsDate = dateFormatter.date(from: rhsTimestamp) else {
                return false
            }
            return lhsDate > rhsDate
        }

        // Update token usage
        let readUnits = sortedVectors.count / 10 // A fetch request uses 1 RU for every 10 fetched records.
        updateTokenUsage(api: APIs.pinecone, tokensUsed: readUnits, read: true)

        return sortedVectors
    }

    // Upsert Data to Pinecone
    func upsertDataToPinecone(id: String, vector: [Float], metadata: [String: Any]) async throws {
        guard let url = URL(string: "https://memoryindex-g24xjwl.svc.example.pinecone.io/vectors/upsert") else {
            throw AppNetworkError.invalidDBURL
        }

        guard let apiKey = ApiConfiguration.pineconeKey else {
            throw AppNetworkError.apiKeyNotFound
        }

        guard let namespace = await ckViewModel.fetchedNamespaceDict.first?.value.namespace else {
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

        let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
        request.httpBody = jsonData

        let _ = try await performHTTPRequest(request: request)

        // Update token usage
        updateTokenUsage(api: APIs.pinecone, tokensUsed: 7, read: false)
    }

    // Delete Vector from Pinecone
    func deleteVectorFromPinecone(id: String) async throws {
        struct DeleteVectorsRequest: Codable {
            let ids: [String]
            let namespace: String
        }

        guard let namespace = await ckViewModel.fetchedNamespaceDict.first?.value.namespace else {
            throw AppCKError.UnableToGetNameSpace
        }

        guard let apiKey = ApiConfiguration.pineconeKey else {
            throw AppNetworkError.apiKeyNotFound
        }

        let url = URL(string: "https://memoryindex-g24xjwl.svc.example.pinecone.io/vectors/delete")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(apiKey, forHTTPHeaderField: "Api-Key")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let deleteRequest = DeleteVectorsRequest(ids: [id], namespace: namespace)
        let requestData = try JSONEncoder().encode(deleteRequest)
        request.httpBody = requestData

        let (_, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            throw AppNetworkError.unknownError("Unable to Delete Vector (bad Response).")
        }

        // Update token usage
        updateTokenUsage(api: APIs.pinecone, tokensUsed: 7, read: false)
    }

    // Delete All Vectors in Namespace
    func deleteAllVectorsInNamespace() async throws {
        struct DeleteAllVectorsRequest: Codable {
            let deleteAll: Bool
            let namespace: String
        }

        guard let namespace = await ckViewModel.fetchedNamespaceDict.first?.value.namespace else {
            throw AppCKError.UnableToGetNameSpace
        }

        guard let apiKey = ApiConfiguration.pineconeKey else {
            throw AppNetworkError.apiKeyNotFound
        }

        let url = URL(string: "https://memoryindex-g24xjwl.svc.example.pinecone.io/vectors/delete")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(apiKey, forHTTPHeaderField: "Api-Key")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("2024-07", forHTTPHeaderField: "X-Pinecone-API-Version")

        let deleteRequest = DeleteAllVectorsRequest(deleteAll: true, namespace: namespace)
        let requestData = try JSONEncoder().encode(deleteRequest)
        request.httpBody = requestData

        let (_, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            throw AppNetworkError.unknownError("Unable to delete Vectors (bad Response).")
        }

        // Update token usage
        updateTokenUsage(api: APIs.pinecone, tokensUsed: 10, read: false)
    }

    // Query Pinecone
    func queryPinecone(vector: [Float], topK: Int = 1, includeValues: Bool = false) async throws -> PineconeQueryResponse {
        guard let url = URL(string: "https://memoryindex-g24xjwl.svc.example.pinecone.io/query") else {
            throw AppNetworkError.invalidDBURL
        }

        guard let apiKey = ApiConfiguration.pineconeKey else {
            throw AppNetworkError.apiKeyNotFound
        }

        guard let namespace = await ckViewModel.fetchedNamespaceDict.first?.value.namespace else {
            throw AppCKError.UnableToGetNameSpace
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(apiKey, forHTTPHeaderField: "Api-Key")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

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

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AppNetworkError.invalidResponse
        }

        let decoder = JSONDecoder()
        let pineconeResponse = try decoder.decode(PineconeQueryResponse.self, from: data)

        // Update token usage
        updateTokenUsage(api: APIs.pinecone, tokensUsed: pineconeResponse.usage.readUnits, read: true)

        return pineconeResponse
    }

    // Perform HTTP Request
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

}
