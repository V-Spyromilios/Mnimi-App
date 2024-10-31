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
        ProgressTracker.shared.reset()
    }

    func requestEmbeddings(for text: String, isQuestion: Bool) {
        Task {
            // Start progress
            ProgressTracker.shared.setProgress(to: 0.0)

            do {
                // Update progress
                ProgressTracker.shared.setProgress(to: 0.12)

                let response = try await openAIActor.fetchEmbeddings(for: text)

                // Update progress
                ProgressTracker.shared.setProgress(to: isQuestion ? 0.25 : 0.6)

                let embeddingsData = response.data.flatMap { $0.embedding }
                if isQuestion {
                    self.embeddingsFromQuestion = embeddingsData
                    self.questionEmbeddingsCompleted = true
                } else {
                    self.embeddings = embeddingsData
                    self.embeddingsCompleted = true
                }

                // Finish progress
                ProgressTracker.shared.setProgress(to: isQuestion ? 0.25 : 0.6)
            } catch {
                self.openAIError = .embeddingsFailed(error)
                // Reset progress on error
                ProgressTracker.shared.reset()
            }
        }
    }

    func getGptResponse(queryMatches: [String], question: String) {
        Task {
            // Start progress
            ProgressTracker.shared.setProgress(to: 0.7)

            do {
                // Update progress
                ProgressTracker.shared.setProgress(to: 0.75)

                let selectedLanguage = languageSettings.selectedLanguage
                let response = try await openAIActor.getGptResponse(
                    vectorResponses: queryMatches,
                    question: question,
                    selectedLanguage: selectedLanguage
                )

                // Update progress
                ProgressTracker.shared.setProgress(to: 0.88)
                ProgressTracker.shared.setProgress(to: 0.99)

                self.stringResponseOnQuestion = response

                // Finish progress
                ProgressTracker.shared.setProgress(to: 1.0)
            } catch {
                self.openAIError = .gptResponseFailed(error)
                // Reset progress on error
                ProgressTracker.shared.reset()
            }
        }
    }
}
