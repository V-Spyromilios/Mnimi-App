//
//  OpenAIViewModel.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 31.10.24.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class OpenAIViewModel: ObservableObject {

    @Published var embeddings: [Float] = []
    @Published var embeddingsFromQuestion: [Float] = []
    @Published var embeddingsCompleted: Bool = false
    @Published var questionEmbeddingsCompleted: Bool = false
    @Published var stringResponseOnQuestion: String = ""
    @Published var openAIError: OpenAIError?

    private let openAIActor: OpenAIActor
    private var languageSettings = LanguageSettings.shared
    private var cancellables = Set<AnyCancellable>()

    init(openAIActor: OpenAIActor) {
        self.openAIActor = openAIActor
    }

    func clearManager() {
            embeddings = []
            embeddingsFromQuestion = []
            embeddingsCompleted = false
            questionEmbeddingsCompleted = false
            stringResponseOnQuestion = ""
       
            openAIError = nil
            
    }
    
//    @MainActor
//    func requestEmbeddings(for text: String, isQuestion: Bool) async {
//        // Start progress
//        ProgressTracker.shared.setProgress(to: 0.0)
//
//        // Run network call off the main actor
//        await withCheckedContinuation { continuation in
//            Task.detached {
//                do {
//                    // Perform network call
//                    let response = try await self.openAIActor.fetchEmbeddings(for: text)
//
//                    // Process data
//                    let embeddingsData = response.data.flatMap { $0.embedding }
//
//                    // Update UI on the main actor
//                    await MainActor.run {
//                        if isQuestion {
//                            self.embeddingsFromQuestion = embeddingsData
//                            self.questionEmbeddingsCompleted = true
//                        } else {
//                            self.embeddings = embeddingsData
//                            self.embeddingsCompleted = true
//                        }
//                        // Update progress
//                        ProgressTracker.shared.setProgress(to: isQuestion ? 0.25 : 0.6)
//                    }
//                    continuation.resume()
//                } catch {
//                    // Handle error on the main actor
//                    await MainActor.run {
//                        self.openAIError = .embeddingsFailed(error)
//                        ProgressTracker.shared.reset()
//                    }
//                    continuation.resume()
//                }
//            }
//        }
//    }

//    func requestEmbeddings(for text: String, isQuestion: Bool) async {
//        await MainActor.run {
//            ProgressTracker.shared.setProgress(to: 0.0)
//        }
//
//            do {
//             
//                await ProgressTracker.shared.setProgress(to: 0.12)
//
//                let response = try await openAIActor.fetchEmbeddings(for: text)
//
//               
//                await ProgressTracker.shared.setProgress(to: isQuestion ? 0.25 : 0.6)
//
//                let embeddingsData = response.data.flatMap { $0.embedding }
//                await MainActor.run {
//                    if isQuestion {
//                        self.embeddingsFromQuestion = embeddingsData
//                        self.questionEmbeddingsCompleted = true
//                    } else {
//                        self.embeddings = embeddingsData
//                        self.embeddingsCompleted = true
//                    }
//                }
//                await MainActor.run {
//                    ProgressTracker.shared.setProgress(to: isQuestion ? 0.25 : 0.6)
//                }
//            } catch {
//                await MainActor.run {
//                    self.openAIError = .embeddingsFailed(error)
//                    // Reset progress on error
//                    ProgressTracker.shared.reset()
//                }
//            }
//    }

//    func getGptResponse(queryMatches: [String], question: String) async {
//        await MainActor.run {
//            ProgressTracker.shared.setProgress(to: 0.75) }
//
//            // Start progress
//
//            do {
//                // Update progress
//
//                let selectedLanguage = await MainActor.run { languageSettings.selectedLanguage }
//                let response = try await openAIActor.getGptResponse(
//                    vectorResponses: queryMatches,
//                    question: question,
//                    selectedLanguage: selectedLanguage
//                )
//
//                await MainActor.run {
//                    ProgressTracker.shared.setProgress(to: 0.88)
//                    ProgressTracker.shared.setProgress(to: 0.99)
//                    
//                    self.stringResponseOnQuestion = response
//                    
//                    // Finish progress
//                    ProgressTracker.shared.setProgress(to: 1.0)
//                }
//            } catch {
//                await MainActor.run {
//                    self.openAIError = .gptResponseFailed(error)
//                    // Reset progress on error
//                    ProgressTracker.shared.reset()
//                }
//            }
//        
//    }
    
    
    func requestEmbeddings(for text: String, isQuestion: Bool) async throws {
//        throw AppNetworkError.unknownError("DEBUG")
        do {
#if DEBUG
            print("requestEmbeddings do {")
#endif
            let embeddingsResponse: EmbeddingsResponse = try await openAIActor.fetchEmbeddings(for: text)
#if DEBUG
            print("embeddingsResponse: \(embeddingsResponse.data.first.debugDescription)")
#endif
            let embeddingsData = embeddingsResponse.data.flatMap { $0.embedding }
           

            // Update properties
            if isQuestion {
                self.embeddingsFromQuestion = embeddingsData
                self.questionEmbeddingsCompleted = true
            } else {
                self.embeddings = embeddingsData
                self.embeddingsCompleted = true
#if DEBUG
            print("requestEmbeddings after updating properties {")
#endif
            }
#if DEBUG
            print("requestEmbeddings before catch {")
#endif
        } catch {
            throw error
        }
    }

    func getGptResponse(queryMatches: [Match], question: String) async {

        do {
            // Access `languageSettings` on the main actor
            let selectedLanguage = self.languageSettings.selectedLanguage

            // Perform network call off the main actor
            let response = try await openAIActor.getGptResponse(
                vectorResponses: queryMatches,
                question: question,
                selectedLanguage: selectedLanguage
            )
            self.stringResponseOnQuestion = response

        } catch {
            self.openAIError = .gptResponseFailed(error)
        }
    }
}
