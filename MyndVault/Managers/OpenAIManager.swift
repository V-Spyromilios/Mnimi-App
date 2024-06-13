//
//  OpenAIManager.swift
//  Memory
//
//  Created by Evangelos Spyromilios on 14.02.24.
//

import Foundation
import Combine
import SwiftUI

final class OpenAIManager: ObservableObject {
    
    @Published var whisperResponse: String?
    @Published var gptResponse: ChatCompletionResponse?
    @Published var gptMetadataResponse: MetadataResponse? // Contains Type and description to be sent for upserting
    
    @Published var gptResponseOnQuestion: ChatCompletionResponse?
    @Published var gptMetadataResponseOnQuestion: MetadataResponse?
    
    @Published var stringResponseOnQuestion: String = ""
    
    @Published var selectedLanguage: LanguageCode
    
    @Published var embeddings: [Float] = []
    @Published var embeddingsFromQuestion: [Float] = []
    
    @Published var questionEmbeddingsCompleted: Bool = false
    @Published var embeddingsCompleted: Bool = false
    @Published var gptResponseForAudioGeneration: String?
    @Published var thrownError: String = ""
    private var lastGptAudioResponse: URL?
    private var tokensRequired:Int = 0
    var cancellables = Set<AnyCancellable>()
    

    init() {
        
        if let savedLanguage = UserDefaults.standard.string(forKey: "selectedPromptLanguage"),
           let languageCode = LanguageCode(rawValue: savedLanguage) {
            self.selectedLanguage = languageCode
        } else {
            self.selectedLanguage = .english
        }
    }

    
    //MARK: clearManager
    func clearManager() async {
        await MainActor.run {
            whisperResponse = nil
            gptResponse = nil
            gptMetadataResponse = nil
            
            gptResponseOnQuestion = nil
            gptMetadataResponseOnQuestion = nil
            
            embeddings = []
            embeddingsFromQuestion = []
            
            questionEmbeddingsCompleted = false
            embeddingsCompleted = false
            gptResponseForAudioGeneration = nil
            stringResponseOnQuestion = ""
            thrownError = ""
        }
        //        print("clearManager() called.")
    }

    //MARK: performAIOperations (DEPRECATED)
//    func performOpenAiOperations(filepath: URL, language: LanguageCode? = nil, userAskingQuestion: Bool) async {
//        
//        print("performOpenAiOperations Called")
//        if userAskingQuestion {
//            ProgressTracker.shared.setProgress(to: 0.22)
//            await requestTranscript(for: filepath, userAskingQuestion: userAskingQuestion)
//            ProgressTracker.shared.setProgress(to: 0.42)
//            
//            if let whisperResponse  = self.whisperResponse {
//                await analyzeTranscript(whisperResponse: whisperResponse, userIsAsking: userAskingQuestion)
//            }
//        } else { // !! USer is not Asking! --> add new !!
//            
//            await requestTranscript(for: filepath, userAskingQuestion: userAskingQuestion)
//            ProgressTracker.shared.setProgress(to: 0.42)
//            
//            if let whisperResponse  = self.whisperResponse {
//                await analyzeTranscript(whisperResponse: whisperResponse, userIsAsking: userAskingQuestion)
//            }
//        }
//        
//    }
    

//MARK: requestTranscript DEPRICATED
//    func requestTranscript(for filepath: URL, language: LanguageCode? = nil, userAskingQuestion: Bool) async {
//        
//        print("requestTranscript called")
//        do {
//            let transcriptionResponse = try await getTranscript(for: filepath, language: self.selectedLanguage, userAskingQuestion: userAskingQuestion)
//            await MainActor.run {
//                self.whisperResponse = transcriptionResponse.response
//            }
//        } catch {
//            await MainActor.run {
//                self.thrownError = error.localizedDescription
//            }
//            print("Error on completion of transcriptResponse: \(error)")
//        }
//    }

    //MARK: private getTranscript DEPRICATED
//    private func getTranscript(for filepath: URL, language: LanguageCode, userAskingQuestion: Bool) async throws -> TranscriptionResponse {
//        
//        guard let url = URL(string: "https://api.openai.com/v1/audio/transcriptions") else {
//            throw URLError(.badURL)
//        }
//        
//        guard let apiKey = ApiConfiguration.openAIKey else {
//            
//            throw AppNetworkError.apiKeyNotFound //TODO: maake custom Error Across the app!
//        }
//        
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
//        
//        let boundary = "Boundary-\(UUID().uuidString)"
//        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
//        
//        var body = Data()
//        
//        // Append parts to the body
//        let parts = [
//            ("language", language.rawValue),
//            ("prompt", self.getWhisperPrompt(userAskingQuestion: userAskingQuestion)),
//            ("model", "whisper-1")
//        ]
//        
//        for (key, value) in parts {
//            body.append("--\(boundary)\r\n".data(using: .utf8)!)
//            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
//            body.append("\(value)\r\n".data(using: .utf8)!)
//        }
//        
//        // Append audio file data
//        if let fileData = try? Data(contentsOf: filepath) {
//            body.append("--\(boundary)\r\n".data(using: .utf8)!)
//            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"recording.m4a\"\r\n".data(using: .utf8)!)
//            body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
//            body.append(fileData)
//            body.append("\r\n".data(using: .utf8)!)
//        }
//        
//        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
//        request.httpBody = body
//        
//        
//        let (data, _) = try await URLSession.shared.data(for: request)
//        do {
//            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
//                print("DEBUG WHISPER RESPONSE:")
//                print(json)
//            }
//        } catch {
//            await MainActor.run {
//                self.thrownError = error.localizedDescription
//            }
//            print("Error serializing JSON: \(error.localizedDescription)")
//        }
//        return try JSONDecoder().decode(TranscriptionResponse.self, from: data)
//    }
    

    //MARK: analyzeTranscript DEPRICATED
//    func analyzeTranscript(whisperResponse: String, userIsAsking: Bool) async {
//        
//        print("analyzeTranscript Called")
//        guard let url = URL(string: "https://api.openai.com/v1/chat/completions"),
//              let apiKey = ApiConfiguration.openAIKey else {
//            print("analyzeTranscript :: Invalid URL or API Key not found")
//            return
//        }
//        
//        let prompt = self.getGptPrompt(userIsAsking: userIsAsking)
//        let requestBody: [String: Any] = [
//            "model": "gpt-4-0125-preview",
//            "temperature": 0,
//            "messages": [
//                ["role": "system", "content": prompt],
//                ["role": "user", "content": whisperResponse]
//            ]
//        ]
//        
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//        ProgressTracker.shared.setProgress(to: 0.75)
//        do {
//            let jsonData = try JSONSerialization.data(withJSONObject: requestBody, options: [])
//            ProgressTracker.shared.setProgress(to: 0.85)
//            request.httpBody = jsonData
//            
//            let (data, _) = try await URLSession.shared.data(for: request)
//            
//            await self.processResponse(data: data, responseError: nil, userIsAsking: userIsAsking)
//            
//        } catch {
//            await MainActor.run {
//                self.thrownError = error.localizedDescription
//            }
//            print("analyzeTranscript :: Error: \(error.localizedDescription)")
//        }
//    }
    
    //MARK: private processResponse DEPRICATED
//    private func processResponse(data: Data?, responseError: Error?, userIsAsking: Bool) async {
//        
//        print("processResponse called")
//        guard let data = data else {
//            if let error = responseError {
//                print("processResponse() :: Network request error: \(error.localizedDescription)")
//            } else {
//                print("processResponse() :: No data received and no error found.")
//            }
//            return
//        }
//        ProgressTracker.shared.setProgress(to: 0.99)
//        do {
//            let response = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
//            if let firstChoice = response.choices.first {
//                let content = firstChoice.message.content
//
//                let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
//                let parts = trimmedContent.components(separatedBy: CharacterSet.newlines).map { $0.trimmingCharacters(in: .whitespaces) }
//                if let metadataIndex = parts.firstIndex(where: { $0 == "Metadata:" }) {
//                    let jsonString = parts[metadataIndex...].dropFirst().joined(separator: " ")
//                    if let jsonData = jsonString.data(using: .utf8) {
//                        do {
//                            if let rawString = String(data: jsonData, encoding: .utf8) {
//                                print("processResponse() :: Received raw data before attemp to decode: \(rawString)")
//                            }
//                            let metadata = try JSONDecoder().decode(MetadataResponse.self, from: jsonData)
//                            
//                            await MainActor.run {
//                                if metadata.type.lowercased() == "question" {
//                                    ProgressTracker.shared.setProgress(to: 1.0)
//                                    self.gptMetadataResponseOnQuestion = metadata
//                                    print("gptMetadataResponseOnQuestion SET NOW")
//                                } else {
//                                    self.gptMetadataResponse = metadata
//                                }
//                            }
//
//                        } catch let DecodingError.dataCorrupted(context) {
//                            await MainActor.run {
//                                self.thrownError = "DecodingError 202.1"
//                            }
//                            print("processResponse() :: Data corrupted: \(context)")
//                        } catch let DecodingError.keyNotFound(key, context) {
//                            await MainActor.run {
//                                self.thrownError = "DecodingError 202.2"
//                            }
//                            print("processResponse() :: Key '\(key)' not found: \(context.debugDescription), codingPath: \(context.codingPath)")
//                        } catch let DecodingError.valueNotFound(value, context) {
//                            await MainActor.run {
//                                self.thrownError = "DecodingError 202.3"
//                            }
//                            print("processResponse() :: Value '\(value)' not found: \(context.debugDescription), codingPath: \(context.codingPath)")
//                        } catch let DecodingError.typeMismatch(type, context) {
//                            await MainActor.run {
//                                self.thrownError = "DecodingError 202.4"
//                            }
//                            print("processResponse() :: Type '\(type)' mismatch: \(context.debugDescription), codingPath: \(context.codingPath)")
//                        } catch {
//                            await MainActor.run {
//                                self.thrownError = "DecodingError 202.5"
//                            }
//                            print("processResponse() :: Unknown error: \(error)")
//                        }
//                    }
//                } else {
//                    print("processResponse() :: No JSON metadata found or format is unexpected.")
//                }
//            }
//        } catch let decodingError {
//            await MainActor.run {
//                self.thrownError = decodingError.localizedDescription
//            }
//            print("processResponse() :: JSON Parsing catched error: \(decodingError)")
//        }
//    }
    
    //MARK: DEPRICATED
//    func updateMetadataResponse(type: String, description: String, relevantFor: String) async {
//        DispatchQueue.main.async {
//            self.gptMetadataResponseOnQuestion?.type = type
//            self.gptMetadataResponseOnQuestion?.description = description
//            self.gptMetadataResponseOnQuestion?.relevantFor = relevantFor
//        }
//    }
    
    //MARK: requestEmbeddings USED in QuestionView
    // call with MetadataResponse.description
    
    func requestEmbeddings(for text: String, isQuestion: Bool) async {
        ProgressTracker.shared.setProgress(to: 0.12)
        
        let maxAttempts = 3
        var attempts = 0
        var success = false
        var localResponse: EmbeddingsResponse?
        var localError: Error?
        
        while attempts < maxAttempts && !success {
            do {
                localResponse = try await fetchEmbeddings(for: text)
                success = true
            } catch {
                localError = error
                attempts += 1
                if attempts < maxAttempts {
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
                }
            }
        }
        
        if success, let response = localResponse {
            await MainActor.run {
                for embedding in response.data {
                    if isQuestion {
                        self.embeddingsFromQuestion.append(contentsOf: embedding.embedding)
                    } else {
                        self.embeddings.append(contentsOf: embedding.embedding)
                    }
                }
                
                if isQuestion {
                    self.questionEmbeddingsCompleted = true
                } else {
                    self.embeddingsCompleted = true
                }
                self.tokensRequired = response.usage.totalTokens
            }
        } else if localError != nil {
            await MainActor.run {
                self.thrownError = AppNetworkError.unknownError("Error 2.12").errorDescription
            }
        }
        
        if isQuestion {
            ProgressTracker.shared.setProgress(to: 0.25)
        } else {
            ProgressTracker.shared.setProgress(to: 0.6)
        }
        updateTokenUsage(api: APIs.openAI, tokensUsed: tokensRequired, read: false)
    }


//    func requestEmbeddings(for text: String, isQuestion: Bool) async {
////        print("request Embeddings called..")
//        ProgressTracker.shared.setProgress(to: 0.12)
//        do {
//            let response = try await fetchEmbeddings(for: text)
////            print("Embeddings Fetch completed successfully.")
//            
//            await MainActor.run { [weak self] in
//                guard let self = self else { return }
//                
//                for embedding in response.data {
//                    if isQuestion {
//                        self.embeddingsFromQuestion.append(contentsOf: embedding.embedding)
//                    } else {
//                        self.embeddings.append(contentsOf: embedding.embedding)
//                    }
//                }
//                
//                if isQuestion {
//                    self.questionEmbeddingsCompleted = true
////                    print("$questionEmbeddingsCompleted = true and Embeddings: OK")
//                } else {
//                    self.embeddingsCompleted = true
//                }
//                self.tokensRequired = response.usage.totalTokens
//            }
//        } catch {
//            await MainActor.run {
//                self.thrownError = error.localizedDescription
//            }
////            print("Error fetching embeddings: \(error)")
//        }
//        if isQuestion {
//            ProgressTracker.shared.setProgress(to: 0.25)
//        } else {
//            ProgressTracker.shared.setProgress(to: 0.6)
//        }
//        updateTokenUsage(api: APIs.openAI, tokensUsed: tokensRequired, read: false)
//    }


    // https://api.openai.com/v1/embeddings POST
    //model: text-embedding-3-large
    // inputText: description of the gpt-4 response.
    //MARK: private fetchEmbeddings USED in QuestionView and AddNew
    private func fetchEmbeddings(for inputText: String) async throws -> EmbeddingsResponse {
        ProgressTracker.shared.setProgress(to: 0.15)
        guard let url = URL(string: "https://api.openai.com/v1/embeddings"),
              let apiKey = ApiConfiguration.openAIKey else {
            throw AppNetworkError.invalidOpenAiURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = [
            "input": inputText,
            "model": "text-embedding-3-large",
            "encoding_format": "float"
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody, options: [])
            request.httpBody = jsonData
        } catch {
            throw AppNetworkError.serializationError(error.localizedDescription)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AppNetworkError.invalidResponse
        }
        ProgressTracker.shared.setProgress(to: 0.2)
        await MainActor.run {
        }
        let decoder = JSONDecoder()
        return try decoder.decode(EmbeddingsResponse.self, from: data)
    }
    

    
    //MARK: USED in QuestionView
    func getGptResponse(queryMatches: [String], question: String) async throws {

        ProgressTracker.shared.setProgress(to: 0.7)
        guard let apiKey = ApiConfiguration.openAIKey else {
            throw AppNetworkError.apiKeyNotFound
        }
        ProgressTracker.shared.setProgress(to: 0.75)
        let gptResponse = try await getGptResponse(apiKey: apiKey, vectorResponses: queryMatches, question: question)
        await MainActor.run {
            ProgressTracker.shared.setProgress(to: 0.88)
            ProgressTracker.shared.setProgress(to: 0.99)
            self.stringResponseOnQuestion = gptResponse
//            print(gptResponse)
        }

//        try await convertTextToSpeech(text: gptResponse, apiKey: apiKey)
    }

    //MARK: USED in QuestionView
    private func getGptResponse(apiKey: String, vectorResponses: [String], question: String) async throws -> String {
        ProgressTracker.shared.setProgress(to: 0.8)
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw AppNetworkError.invalidOpenAiURL
        }
        let prompt = getGptPrompt(vectorResponses: vectorResponses, question: question)
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o", //gpt-4o
//            "model": "gpt-4-0125-preview", // gtp-4
            "temperature": 0,
            "messages": [["role": "system", "content": prompt]]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let maxAttempts = 2
        var attempts = 0
        var localError: Error?
        
        while attempts < maxAttempts {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
                ProgressTracker.shared.setProgress(to: 0.85)
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    throw AppNetworkError.invalidResponse
                }
                
                let decoder = JSONDecoder()
                let gptResponse = try decoder.decode(ChatCompletionResponse.self, from: data)
                guard let firstChoice = gptResponse.choices.first else {
                    throw AppNetworkError.noChoicesInResponse
                }
                updateTokenUsage(api: APIs.openAI, tokensUsed: gptResponse.usage.totalTokens, read: false)
                return firstChoice.message.content
                
            } catch {
                localError = error
                attempts += 1
                if attempts < maxAttempts {
                    try? await Task.sleep(nanoseconds: 100_000_000)
                }
            }
        }
        
        throw localError ?? AppNetworkError.unknownError("An unknown error occurred during GPT response fetch.")
    }

    
    
//    private func getGptResponse(apiKey: String, vectorResponses: [String], question: String) async throws -> String {
//
//        ProgressTracker.shared.setProgress(to: 0.8)
//        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
//            throw AppNetworkError.invalidOpenAiURL
//        }
//        let prompt = getGptPrompt(vectorResponses: vectorResponses, question: question)
//        
//        let requestBody: [String: Any] = [
//            "model": "gpt-4-0125-preview",  //to turbo to kalo
//            "temperature": 0,
//            "messages": [["role": "system", "content": prompt]]
//        ]
//        
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
//
//        ProgressTracker.shared.setProgress(to: 0.85)
//        let (data, response) = try await URLSession.shared.data(for: request)
//        
//        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
//            print(AppNetworkError.invalidResponse)
//            throw AppNetworkError.invalidResponse
//        }
//
//        let decoder = JSONDecoder()
//        do {
//            let gptResponse = try decoder.decode(ChatCompletionResponse.self, from: data)
//            guard let firstChoice = gptResponse.choices.first else {
//                throw AppNetworkError.noChoicesInResponse
//            }
//            updateTokenUsage(api: APIs.openAI, tokensUsed: gptResponse.usage.totalTokens, read: false)
//            return firstChoice.message.content
//        }
//        catch {
////            print("Error decoding GPT response: \(error)")
////                   print("Response data: \(String(data: data, encoding: .utf8) ?? "No response data")")
//                   throw error
//        }
//    }
    
    //MARK: covert Text to Speech DEPRICATED
//    private func convertTextToSpeech(text: String, apiKey: String) async throws {
//        
//        guard let url = URL(string: "https://api.openai.com/v1/audio/speech") else {
//            throw AppNetworkError.invalidTTSURL
//        }
//        ProgressTracker.shared.setProgress(to: 0.75)
//        let requestBody: [String: Any] = [
//            "model": "tts-1",
//            "input": text,
//            "voice": "alloy"
//        ]
//        
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
//        
//        let (data, _) = try await URLSession.shared.data(for: request)
//        ProgressTracker.shared.setProgress(to: 0.85)
//        try await saveAndPlayAudio(data: data)
//    }
//    
//
//    //MARK: DEPRICATED
//    @MainActor
//    private func saveAndPlayAudio(data: Data) async throws {
//        let fileManager = FileManager.default
//        guard let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
//            throw AppNetworkError.unknownError("saveAndPlayAudio() :: Could not find the document directory.")
//        }
//        
//        let fileURL = documentDirectory.appendingPathComponent("GptReply\(Date()).mp3")
//        
//        do {
//            if (self.gptMetadataResponseOnQuestion != nil) {
//                self.gptMetadataResponseOnQuestion?.fileUrl = fileURL
//            }
//            try data.write(to: fileURL)
//            lastGptAudioResponse = fileURL
//            
//            print("Audio [Reply] saved: \(fileURL.path)")
//            ProgressTracker.shared.setProgress(to: 0.99)
//            AudioManager.shared.playAudioFrom(url: fileURL)
//        } catch {
//            throw AppNetworkError.unknownError("saveAndPlayAudio() :: Failed to save audio: \(error.localizedDescription)")
//        }
//    }
    
    
    private func getGptPrompt(vectorResponses: [String], question: String) -> String {

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.timeZone = TimeZone.current
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let isoDateString = isoFormatter.string(from: Date()) // Use for precise timestamps

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMMM d, yyyy"
        let readableDateString = dateFormatter.string(from: Date())
        
        
        var firstVector: String = ""
        var secondVector: String = ""
        
        if vectorResponses.count == 1 {
            if !vectorResponses[0].isEmpty {
                firstVector = vectorResponses[0]
            }
        }
        else if vectorResponses.count == 2 {
            if !vectorResponses[0].isEmpty {
                firstVector = vectorResponses[0]
            }
            
            if !vectorResponses[1].isEmpty {
                secondVector = vectorResponses[1]
            }
        }
        
        switch selectedLanguage {
        case .english:
            return """
                   You are an AI assistant, and you have been asked to provide concise information on a specific topic. Below are the user's question and one or two pieces of information retrieved by the vector database. Note that these pieces of information may be irrelevant:
                                   
                       - User's Question: \(question).
                       - Relevant Information 1: \(firstVector).
                       - Relevant Information 2: \(secondVector).
                                   
                   Using the user's question and the information provided, generate a comprehensive, informative, and concise reply that addresses the user's inquiry. Evaluate the relevance of the retrieved information:
                   - If the retrieved information is relevant, integrate it into your response.
                   - If the retrieved information is not relevant or seems ambiguous, use your general knowledge to provide a helpful response.

                   If relevant for your reply, today is \(readableDateString), and the current time in ISO8601 format is \(isoDateString). Do not return full dates and times unless necessary. Highlight any uncertainties and suggest that the user provide additional information to the app for more accurate answers in the future.

                   The response should be clear, engaging, concise, and suitable for converting to audio to be read to the user.
                """
        case .spanish:
            return """
                Eres un asistente de IA y se te ha solicitado que proporciones información concisa sobre un tema específico. A continuación se presentan la pregunta del usuario y una o dos piezas de información recuperadas de la base de datos vectorial. Tenga en cuenta que estas piezas de información pueden ser irrelevantes:
                                
                    - Pregunta del Usuario: \(question).
                    - Información Relevante 1: \(firstVector).
                    - Información Relevante 2: \(secondVector).
                                
                Usando la pregunta del usuario y la información proporcionada, genera una respuesta completa, informativa y concisa que aborde la consulta del usuario. Evalúa la relevancia de la información recuperada:
                - Si la información recuperada es relevante, intégrala en tu respuesta.
                - Si la información recuperada no es relevante o parece ambigua, usa tu conocimiento general para proporcionar una respuesta útil.

                Si es relevante para tu respuesta, hoy es \(readableDateString) y la hora actual en formato ISO8601 es \(isoDateString). No devuelvas fechas y horas completas a menos que sea necesario. Destaca cualquier incertidumbre y sugiere al usuario que proporcione información adicional a la aplicación para obtener respuestas más precisas en el futuro.

                La respuesta debe ser clara, atractiva, concisa y adecuada para convertirla en audio para ser leída al usuario.
                """
        case .french:
            return """
                Vous êtes un assistant IA et on vous a demandé de fournir des informations concises sur un sujet spécifique. Ci-dessous se trouvent la question de l'utilisateur et une ou deux informations récupérées par la base de données vectorielle. Notez que ces informations peuvent être non pertinentes :
                                
                    - Question de l'utilisateur : \(question).
                    - Information pertinente 1 : \(firstVector).
                    - Information pertinente 2 : \(secondVector).
                                
                En utilisant la question de l'utilisateur et les informations fournies, générez une réponse complète, informative et concise qui répond à la demande de l'utilisateur. Évaluez la pertinence des informations récupérées :
                - Si les informations récupérées sont pertinentes, intégrez-les dans votre réponse.
                - Si les informations récupérées ne sont pas pertinentes ou semblent ambiguës, utilisez vos connaissances générales pour fournir une réponse utile.

                Si cela est pertinent pour votre réponse, aujourd'hui est \(readableDateString) et l'heure actuelle au format ISO8601 est \(isoDateString). Ne renvoyez des dates et des heures complètes que si nécessaire. Soulignez toutes les incertitudes et suggérez à l'utilisateur de fournir des informations supplémentaires à l'application pour obtenir des réponses plus précises à l'avenir.

                La réponse doit être claire, engageante, concise et adaptée à la conversion en audio pour être lue à l'utilisateur.
                """
        case .german:
            return """
                Du bist ein KI-Assistent und wurdest gebeten, präzise Informationen zu einem bestimmten Thema bereitzustellen. Nachfolgend sind die Frage des Benutzers und ein oder zwei Informationen aufgeführt, die von der Vektordatenbank abgerufen wurden. Beachte, dass diese Informationen möglicherweise irrelevant sind:
                                
                    - Frage des Benutzers: \(question).
                    - Relevante Information 1: \(firstVector).
                    - Relevante Information 2: \(secondVector).
                                
                Verwende die Frage des Benutzers und die bereitgestellten Informationen, um eine umfassende, informative und präzise Antwort zu erstellen, die die Anfrage des Benutzers beantwortet. Bewerte die Relevanz der abgerufenen Informationen:
                - Wenn die abgerufenen Informationen relevant sind, integriere sie in deine Antwort.
                - Wenn die abgerufenen Informationen nicht relevant oder unklar erscheinen, nutze dein allgemeines Wissen, um eine hilfreiche Antwort zu geben.

                Falls es für deine Antwort relevant ist, heute ist \(readableDateString), und die aktuelle Zeit im ISO8601-Format ist \(isoDateString). Gib vollständige Daten und Uhrzeiten nur dann zurück, wenn es notwendig ist. Hebe alle Unklarheiten hervor und schlage dem Benutzer vor, der App zusätzliche Informationen bereitzustellen, um in Zukunft genauere Antworten zu erhalten.

                Die Antwort sollte klar, ansprechend, prägnant und geeignet sein, um in Audio umgewandelt und dem Benutzer vorgelesen zu werden.
                """
        case .greek:
            return """
               Είστε ένας βοηθός τεχνητής νοημοσύνης και σας ζητήθηκε να παρέχετε συνοπτικές πληροφορίες για ένα συγκεκριμένο θέμα. Παρακάτω βρίσκονται η ερώτηση του χρήστη και μία ή δύο πληροφορίες που ανακτήθηκαν από τη βάση δεδομένων διανυσμάτων. Σημειώστε ότι αυτές οι πληροφορίες μπορεί να είναι άσχετες:
                               
                   - Ερώτηση του χρήστη: \(question).
                   - Σχετική Πληροφορία 1: \(firstVector).
                   - Σχετική Πληροφορία 2: \(secondVector).
                               
               Χρησιμοποιώντας την ερώτηση του χρήστη και τις παρεχόμενες πληροφορίες, δημιουργήστε μια ολοκληρωμένη, ενημερωτική και συνοπτική απάντηση που να απαντά στην ερώτηση του χρήστη. Αξιολογήστε τη συνάφεια των ανακτημένων πληροφοριών:
               - Αν οι ανακτημένες πληροφορίες είναι σχετικές, ενσωματώστε τις στην απάντησή σας.
               - Αν οι ανακτημένες πληροφορίες δεν είναι σχετικές ή φαίνονται ασαφείς, χρησιμοποιήστε τις γενικές σας γνώσεις για να δώσετε μια χρήσιμη απάντηση.

               Αν είναι σχετικό για την απάντησή σας, σήμερα είναι \(readableDateString) και η τρέχουσα ώρα σε μορφή ISO8601 είναι \(isoDateString). Μην επιστρέφετε πλήρεις ημερομηνίες και ώρες εκτός αν είναι απαραίτητο. Τονίστε τυχόν αβεβαιότητες και προτείνετε στον χρήστη να παρέχει επιπλέον πληροφορίες στην εφαρμογή για να λάβει πιο ακριβείς απαντήσεις στο μέλλον.

               Η απάντηση πρέπει να είναι σαφής, ελκυστική, συνοπτική και κατάλληλη για να μετατραπεί σε ήχο για να διαβαστεί στον χρήστη.
"""
        }
    }

    //MARK: DEPRICATED
//    private func getWhisperPrompt(userAskingQuestion: Bool) -> String {
//        if userAskingQuestion {
//            switch selectedLanguage {
//            case .english:
//                return "The user is asking a question. Please transcribe the question accurately, excluding any hesitations like 'ahhm' and background noises."
//            case .french:
//                return "L'utilisateur pose une question. Veuillez transcrire la question avec précision, en incluant les hésitations comme 'euh' et les bruits de fond."
//            case .german:
//                return "Der Benutzer stellt eine Frage. Bitte transkribieren Sie die Frage genau, einschließlich Zögern wie 'ähm' und Hintergrundgeräusche."
//            case .spanish:
//                return "El usuario está haciendo una pregunta. Transcriba la pregunta con precisión, incluyendo vacilaciones como 'ehm' y ruidos de fondo."
//            case .greek:
//                return "Ο χρήστης κάνει μια ερώτηση. Παρακαλώ καταγράψτε την ερώτηση με ακρίβεια, αποκλείοντας οποιαδήποτε δισταγμούς όπως 'ααα' και θορύβους φόντου."
//            }
//        } else {
//            switch selectedLanguage {
//            case .english:
//                return "This is an audio recording from the user and may include hesitations like 'ahhm' and background noises. Please return the transcript."
//            case .french:
//                return "Ceci est un enregistrement audio de l'utilisateur et peut inclure des hésitations comme 'euh' et des bruits de fond. Veuillez retourner la transcription."
//            case .german:
//                return "Dies ist eine Audioaufnahme vom Benutzer und kann Zögern wie 'ähm' und Hintergrundgeräusche enthalten. Bitte geben Sie das Transkript zurück."
//            case .spanish:
//                return "Esta es una grabación de audio del usuario y puede incluir vacilaciones como 'ehm' y ruidos de fondo. Por favor, devuelva la transcripción."
//            case .greek:
//                return "Αυτή είναι μια ηχογράφηση από τον χρήστη και μπορεί να περιλαμβάνει δισταγμούς όπως 'ααα' και θορύβους φόντου. Παρακαλώ επιστρέψτε την απομαγνητοφώνηση."
//            }
//        }
//    }
    
    //MARK: DEPRICATED
//    private func getGptPrompt(userIsAsking: Bool) -> String {
//        
//        let now = Date()
//        let formatter = ISO8601DateFormatter()
//        formatter.timeZone = TimeZone.current
//        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
//        let dateString = formatter.string(from: now)
//        //        print("gpt prompted with \(dateString)")
//        
//        if userIsAsking {
//            switch selectedLanguage {
//            case .english:
//                return """
//                        Please analyze the following transcript of a user's question, recorded in a possibly noisy environment. The transcript generated by the Whisper model may include hesitations like 'ahhm', background noises, and uncertain transcriptions (e.g., '[inaudible]'). Your tasks are to:
//                        1. Identify and correct any grammatical errors, ensuring the language is clear and professional.
//                        2. Completely remove non-verbal cues (e.g., 'ahhm') and background noise indications, as these do not contribute to the database query. Do not annotate; simply omit these elements for clarity.
//                        3. Clarify unclear sentences, possibly by rephrasing, while maintaining the original intent. Focus on preserving the essence of the question asked. Make educated guesses to fill in or omit uncertain transcriptions based on context, prioritizing the overall coherence and relevance of the question.
//                        4. Extract and succinctly restate the question or inquiry posed by the user. This will be used to query a vector database and should be precise and to the point. Emphasize any actionable items or key terms that are critical for retrieving the most relevant information from the database. Assign this to the "description" key of the Metadata.
//                        5. Include any relevant contextual information that could consistently apply to the queries being processed, enhancing the precision of the database search.
//                        
//                        Please format your response to include both the refined question as asked by the user and the corresponding metadata, as shown in the following example. 'type' should be 'Question'!
//                        
//                        Metadata:
//                        {
//                          "type": "Question",
//                          "description": "What are the opening hours of the local library?",
//                          "keywords": ["opening hours", "local library"],
//                          "relevantFor": "local library information search"
//                        }
//                        """
//            case .spanish:
//                return """
//                        Por favor, analiza el siguiente transcripto de una pregunta de un usuario, grabada en un ambiente posiblemente ruidoso. El transcripto generado por el modelo Whisper puede incluir vacilaciones como 'ahhm', ruidos de fondo e transcripciones inciertas (p.ej., '[inaudible]'). Tus tareas son:
//                                                1. Identificar y corregir cualquier error gramatical, asegurando que el lenguaje sea claro y profesional.
//                                                2. Eliminar completamente las señales no verbales (p.ej., 'ahhm') y las indicaciones de ruido de fondo, ya que estos no contribuyen a la consulta de la base de datos. No anotes; simplemente omite estos elementos para claridad.
//                                                3. Aclarar oraciones poco claras, posiblemente reformulándolas, manteniendo la intención original. Concéntrate en preservar la esencia de la pregunta realizada. Haz conjeturas educadas para completar u omitir transcripciones inciertas basándote en el contexto, priorizando la coherencia general y la relevancia de la pregunta.
//                                                4. Extraer y reiterar de manera sucinta la pregunta o consulta planteada por el usuario. Esto se utilizará para consultar una base de datos vectorial y debe ser preciso y al punto. Enfatiza cualquier ítem de acción o términos clave que sean críticos para recuperar la información más relevante de la base de datos. Asigna esto a la clave "description" de los Metadatos.
//                                                5. Incluir cualquier información contextual relevante que podría aplicarse consistentemente a las consultas siendo procesadas, mejorando la precisión de la búsqueda en la base de datos.
//                        
//                                                Por favor, formatea tu respuesta para incluir tanto la pregunta refinada tal como la hizo el usuario como los metadatos correspondientes, como se muestra en el ejemplo:
//                        
//                                                Metadatos:
//                                                {
//                                                  "type": "Pregunta",
//                                                  "description": "¿Cuáles son los horarios de apertura de la biblioteca local?",
//                                                  "keywords": ["horarios de apertura", "biblioteca local"],
//                                                  "relevantFor": "búsqueda de información sobre biblioteca local"
//                                                }
//                        
//                        """
//            case .french:
//                return """
//                        Veuillez analyser le transcript suivant d'une question d'utilisateur, enregistrée dans un environnement potentiellement bruyant. Le transcript généré par le modèle Whisper peut inclure des hésitations telles que 'ahhm', des bruits de fond et des transcriptions incertaines (par ex., '[inaudible]'). Vos tâches sont de :
//                                                1. Identifier et corriger toute erreur grammaticale, en assurant que le langage est clair et professionnel.
//                                                2. Supprimer complètement les indices non verbaux (par ex., 'ahhm') et les indications de bruit de fond, car ils ne contribuent pas à la requête de la base de données. Ne pas annoter ; simplement omettre ces éléments pour plus de clarté.
//                                                3. Clarifier les phrases incertaines, éventuellement en les reformulant, tout en maintenant l'intention originale. Concentrez-vous sur la préservation de l'essence de la question posée. Faites des suppositions éclairées pour remplir ou omettre les transcriptions incertaines en fonction du contexte, en priorisant la cohérence globale et la pertinence de la question.
//                                                4. Extraire et reformuler de manière succincte la question ou la demande posée par l'utilisateur. Cela sera utilisé pour interroger une base de données vectorielle et doit être précis et concis. Soulignez tous les éléments d'action ou termes clés qui sont critiques pour récupérer les informations les plus pertinentes de la base de données. Assignez ceci à la clé "description" des Métadonnées.
//                                                5. Inclure toute information contextuelle pertinente qui pourrait s'appliquer de manière cohérente aux requêtes en cours de traitement, améliorant la précision de la recherche dans la base de données.
//                        
//                                                  Veuillez formater votre réponse pour inclure à la fois la question raffinée telle que posée par l'utilisateur et les métadonnées correspondantes, comme montré dans l'exemple :
//                        
//                                                Métadonnées :
//                                                {
//                                                  "type": "Question",
//                                                  "description": "Quels sont les horaires d'ouverture de la bibliothèque locale ?",
//                                                  "keywords": ["horaires d'ouverture", "bibliothèque locale"],
//                                                  "relevantFor": "recherche d'information sur la bibliothèque locale"
//                                                }
//                        
//                        """
//            case .german:
//                return """
//                        Bitte analysiere das folgende Transkript einer Benutzerfrage, aufgenommen in einer möglicherweise lauten Umgebung. Das durch das Whisper-Modell generierte Transkript kann Zögern wie 'ahhm', Hintergrundgeräusche und unsichere Transkriptionen (z.B. '[unverständlich]') enthalten. Deine Aufgaben sind:
//                                    1. Identifiziere und korrigiere jegliche grammatikalische Fehler, um sicherzustellen, dass die Sprache klar und professionell ist.
//                                    2. Entferne vollständig nicht-verbale Hinweise (z.B. 'ahhm') und Angaben zu Hintergrundgeräuschen, da diese nicht zur Datenbankabfrage beitragen. Nicht annotieren; einfach diese Elemente zur Klarheit weglassen.
//                                    3. Kläre unklare Sätze, möglicherweise durch Umformulierung, während du die ursprüngliche Absicht beibehältst. Konzentriere dich darauf, die Essenz der gestellten Frage zu bewahren. Mache gebildete Vermutungen, um unsichere Transkriptionen basierend auf dem Kontext zu ergänzen oder wegzulassen, wobei die Gesamtkohärenz und Relevanz der Frage Priorität haben.
//                                    4. Extrahiere und formuliere die vom Benutzer gestellte Frage oder Anfrage prägnant neu. Dies wird verwendet, um eine Vektor-Datenbank abzufragen und sollte präzise und auf den Punkt sein. Betone alle handlungsrelevanten Punkte oder Schlüsselbegriffe, die für die Abrufung der relevantesten Informationen aus der Datenbank entscheidend sind. Weise dies dem Schlüssel "description" der Metadaten zu.
//                                    5. Beziehe alle relevanten Kontextinformationen ein, die konsistent auf die verarbeiteten Anfragen angewendet werden könnten, um die Präzision der Datenbanksuche zu erhöhen.
//                        
//                                    Bitte formatiere deine Antwort so, dass sie sowohl die verfeinerte Frage, wie sie vom Benutzer gestellt wurde, als auch die entsprechenden Metadaten enthält, wie im Beispiel gezeigt:
//                        
//                                    Metadaten:
//                                    {
//                                      "type": "Frage",
//                                      "description": "Was sind die Öffnungszeiten der örtlichen Bibliothek?",
//                                      "keywords": ["Öffnungszeiten", "örtliche Bibliothek"],
//                                      "relevantFor": "Suche nach Informationen zur örtlichen Bibliothek"
//                                    }
//                        
//                        """
//            case .greek:
//                return """
//                "Παρακαλώ αναλύστε την παρακάτω απομαγνητοφώνηση της ερώτησης του χρήστη, η οποία έγινε σε πιθανώς θορυβώδες περιβάλλον. Η απομαγνητοφώνηση που δημιουργήθηκε από το μοντέλο Whisper μπορεί να περιλαμβάνει δισταγμούς όπως 'ααα', θορύβους φόντου και αβέβαιες μεταγραφές (π.χ., '[ακατανόητο]'). Τα καθήκοντά σας είναι να:
//                1. Αναγνωρίστε και διορθώστε τυχόν γραμματικά λάθη, διασφαλίζοντας ότι η γλώσσα είναι καθαρή και επαγγελματική.
//                2. Αφαιρέστε πλήρως τις μη λεκτικές ενδείξεις (π.χ., 'ααα') και τις ενδείξεις θορύβου φόντου, καθώς αυτές δεν συμβάλλουν στο ερώτημα της βάσης δεδομένων. Μην κάνετε σημειώσεις· απλώς παραλείψτε αυτά τα στοιχεία για σαφήνεια.
//                3. Καθαρίστε ασαφείς προτάσεις, πιθανώς με αναδιατύπωση, διατηρώντας την αρχική πρόθεση. Επικεντρωθείτε στο να διατηρήσετε την ουσία της ερωτημένης ερώτησης. Κάντε εκπαιδευμένες εικασίες για το συμπλήρωμα ή την παράλειψη αβέβαιων μεταγραφών με βάση το περιεχόμενο, δίνοντας προτεραιότητα στη συνοχή και τη σχετικότητα της ερώτησης.
//                4. Εξάγετε και διατυπώστε συνοπτικά την ερώτηση ή το αίτημα που τέθηκε από τον χρήστη. Αυτό θα χρησιμοποιηθεί για ερώτημα σε μια βάση δεδομένων διανυσμάτων και πρέπει να είναι ακριβές και στο σημείο. Τονίστε τυχόν στοιχεία δράσης ή κρίσιμους όρους που είναι ουσιαστικοί για την ανάκτηση των πλέον σχετικών πληροφοριών από τη βάση δεδομένων. Αναθέστε αυτό στο κλειδί 'description' του Metadata.
//                5. Συμπεριλάβετε οποιαδήποτε σχετική πληροφορία πλαισίου που θα μπορούσε να ισχύει συνεπώς για τα ερωτήματα που επεξεργάζονται, ενισχύοντας την ακρίβεια της αναζήτησης στη βάση δεδομένων.
//
//                Παρακαλώ διαμορφώστε την απάντησή σας για να περιλαμβάνει και την διατυπωμένη ερώτηση όπως την έθεσε ο χρήστης και τα αντίστοιχα metadata, όπως φαίνεται στο παρακάτω παράδειγμα. Το 'type' πρέπει να είναι 'Question'!
//
//                Metadata:
//                {
//                  "type": "Question",
//                  "description": "Ποιες είναι οι ώρες λειτουργίας της τοπικής βιβλιοθήκης;",
//                  "keywords": ["ώρες λειτουργίας", "τοπική βιβλιοθήκη"],
//                  "relevantFor": "αναζήτηση πληροφοριών τοπικής βιβλιοθήκης"
//                }
//                """
//            }
//        } else {
//            
//            switch selectedLanguage {
//            case .english:
//                return """
//Please analyze the following transcript of a user's voice note recorded in a possibly noisy environment. The transcript generated by the whisper model may include hesitations like 'ahhm' and background noises. Your tasks are to:
//    1. Identify and correct any grammatical errors.
//    2. Remove or note any non-verbal cues (e.g., 'ahhm') and background noise indications.
//    3. Clarify unclear sentences, possibly by rephrasing, while maintaining the original intent.
//    4. Extract and highlight actionable items and general knowledge. In cases where the content applies to both categories, such as an appointment that is both a task and contains significant information, provide entries for both 'To-Do' and 'General Knowledge':
//       a. General Knowledge: Information the user wants to remember, including the relevant person if mentioned. If relevant person is not mentioned should default to user.
//       b. To-Do: Tasks or events the user wishes to set a notification for, including extracting the relevant date and time if mentioned, and the relevant person or context. Specifically, if the user does not specify a date and time, calculate it given that the current date and time is \(dateString) in ISO8601 format.
//
//    5. For each entry, provide a structured output that includes the metadata in JSON format. The metadata should include the type (GeneralKnowledge or To-Do), the description,the relevant person, and if applicable, the date, time.
//
//Please format your response to include both the structured description and the corresponding metadata as shown in the following examples. 'type' should be either 'ToDo' or 'GeneralKnowledge'.
//
//General Knowledge: The name of my son Charlie's teacher is John Williams. Relevant for: Charlie.
//
//Metadata:
//{
//  "type": "GeneralKnowledge",
//  "description": "The name of my son Charlie's teacher is John Williams.",
//  "relevantFor": "Charlie"
//}
//
//To-Do: Schedule a meeting with John Williams, Date: YYYY-MM-DD, Time: HH:MM. Relevant for: Charlie's school activities.
//
//Metadata:
//{
//  "type": "ToDo",
//  "description": "Schedule a meeting with John Williams.",
//  "date": "YYYY-MM-DD",
//  "time": "HH:MM",
//  "relevantFor": "Charlie's school activities"
//}
//
//"""
//            case .french:
//                return """
//            Veuillez analyser la transcription suivante d'une note vocale d'un utilisateur enregistrée dans un environnement possiblement bruyant. La transcription générée par le modèle Whisper peut inclure des hésitations telles que 'euh' et des bruits de fond. Vos tâches sont les suivantes :
//                1. Identifier et corriger toutes les erreurs grammaticales.
//                2. Supprimer ou noter tous les indices non verbaux (par exemple, 'euh') et les indications de bruit de fond.
//                3. Clarifier les phrases floues, éventuellement en les reformulant, tout en préservant l'intention originale.
//                4. Extraire et mettre en évidence les éléments d'action et les connaissances générales. Dans les cas où le contenu s'applique à ces deux catégories, comme un rendez-vous qui est à la fois une tâche et contient des informations importantes, fournir des entrées pour 'À faire' et 'Connaissances générales' :
//                   a. Connaissances générales : Informations que l'utilisateur souhaite se rappeler, y compris la personne concernée si elle est mentionnée. Si la personne concernée n'est pas mentionnée, elle doit par défaut être l'utilisateur.
//                   b. À faire : Tâches ou événements pour lesquels l'utilisateur souhaite définir une notification, y compris l'extraction de la date et de l'heure pertinentes si elles sont mentionnées, et la personne ou le contexte concerné. Spécifiquement, si l'utilisateur ne spécifie pas de date et d'heure, calculez-la étant donné que la date et l'heure actuelles sont \(dateString) au format ISO8601.
//
//                5. Pour chaque entrée, fournissez une sortie structurée incluant les métadonnées au format JSON. Les métadonnées doivent inclure le type (ConnaissancesGénérales ou ÀFaire), la description, la personne concernée, et si applicable, la date, l'heure.
//
//            Veuillez formater votre réponse pour inclure à la fois la description structurée et les métadonnées correspondantes comme montré dans les exemples suivants. Le 'type' devrait être soit 'ToDo' soit 'GeneralKnowledge'.
//
//            Connaissances Générales : Le nom du professeur de mon fils Charlie est John Williams. Pertinent pour : Charlie.
//
//            Metadata :
//            {
//              "type": "GeneralKnowledge",
//              "description": "Le nom du professeur de mon fils Charlie est John Williams.",
//              "relevantFor": "Charlie"
//            }
//
//            À Faire : Programmer une réunion avec John Williams, Date : YYYY-MM-DD, Heure : HH:MM. Pertinent pour : les activités scolaires de Charlie.
//
//            Metadata :
//            {
//              "type": "ToDo",
//              "description": "Programmer une réunion avec John Williams.",
//              "date": "YYYY-MM-DD",
//              "time": "HH:MM",
//              "relevantFor": "les activités scolaires de Charlie"
//            }
//
//            """
//            case .german:
//                return """
//Bitte analysieren Sie das folgende Transkript einer Sprachnotiz eines Benutzers, aufgenommen in einer möglicherweise lauten Umgebung. Das durch das Whisper-Modell erstellte Transkript kann Zögern wie 'ähm' und Hintergrundgeräusche enthalten. Ihre Aufgaben sind:
//    1. Identifizieren und korrigieren Sie jegliche Grammatikfehler.
//    2. Entfernen oder notieren Sie jegliche nonverbale Hinweise (z.B. 'ähm') und Anzeigen von Hintergrundgeräuschen.
//    3. Klären Sie unklare Sätze, eventuell durch Umformulierung, wobei die ursprüngliche Absicht beibehalten wird.
//    4. Extrahieren und heben Sie Handlungsanweisungen und Allgemeinwissen hervor. In Fällen, in denen der Inhalt auf beide Kategorien zutrifft, wie bei einem Termin, der sowohl eine Aufgabe ist als auch wichtige Informationen enthält, erstellen Sie Einträge für 'To-Do' und 'Allgemeinwissen':
//       a. Allgemeinwissen: Informationen, die der Benutzer sich merken möchte, einschließlich der betreffenden Person, falls erwähnt. Wenn keine relevante Person erwähnt wird, sollte standardmäßig der Benutzer gemeint sein.
//       b. To-Do: Aufgaben oder Ereignisse, für die der Benutzer eine Benachrichtigung einstellen möchte, einschließlich der Extraktion des relevanten Datums und der Uhrzeit, falls erwähnt, und der betreffenden Person oder des Kontexts. Speziell, wenn der Benutzer kein Datum und keine Uhrzeit angibt, berechnen Sie dies, da das aktuelle Datum und die Uhrzeit \(dateString) im ISO8601-Format sind.
//
//    5. Für jeden Eintrag liefern Sie eine strukturierte Ausgabe, die die Metadaten im JSON-Format enthält. Die Metadaten sollten den Typ (GeneralKnowledge oder To-Do), die Beschreibung, die relevante Person und gegebenenfalls das Datum, die Uhrzeit umfassen.
//
//Bitte formatieren Sie Ihre Antwort so, dass sie sowohl die strukturierte Beschreibung als auch die entsprechenden Metadaten wie in den folgenden Beispielen enthält. Der 'Type' sollte entweder 'To-Do' oder 'GeneralKnowledge' sein.
//
//Allgemeinwissen: Der Name des Lehrers meines Sohnes Charlie ist John Williams. Relevant für: Charlie.
//
//Metadata:
//{
//  "type": "GeneralKnowledge",
//  "description": "Der Name des Lehrers meines Sohnes Charlie ist John Williams.",
//  "relevantFor": "Charlie"
//}
//
//To-Do: Planen Sie ein Treffen mit John Williams, Datum: YYYY-MM-DD, Uhrzeit: HH:MM. Relevant für: Charlies schulische Aktivitäten.
//
//Metadata:
//{
//  "type": "To-Do",
//  "description": "Planen Sie ein Treffen mit John Williams.",
//  "date": "YYYY-MM-DD",
//  "time": "HH:MM",
//  "relevantFor": "Charlies schulische Aktivitäten"
//}
//
//"""
//            case .spanish:
//                return """
//Por favor, analice la siguiente transcripción de una nota de voz de un usuario grabada en un entorno posiblemente ruidoso. La transcripción generada por el modelo Whisper puede incluir hesitaciones como 'eh' y ruidos de fondo. Sus tareas son:
//    1. Identificar y corregir cualquier error gramatical.
//    2. Eliminar o anotar cualquier señal no verbal (por ejemplo, 'eh') y señales de ruido de fondo.
//    3. Aclarar oraciones poco claras, posiblemente reformulándolas, manteniendo la intención original.
//    4. Extraer y destacar elementos accionables y conocimientos generales. En casos donde el contenido se aplica a ambas categorías, como una cita que es tanto una tarea como contiene información significativa, proporcione entradas para 'Pendientes' y 'Conocimiento General':
//       a. Conocimiento General: Información que el usuario desea recordar, incluyendo la persona relevante si se menciona. Si no se menciona a la persona relevante, debería referirse por defecto al usuario.
//       b. Pendientes: Tareas o eventos para los cuales el usuario desea configurar una notificación, incluyendo la extracción de la fecha y hora relevantes si se mencionan, y la persona o contexto relevante. Específicamente, si el usuario no especifica una fecha y hora, calcúlela dado que la fecha y hora actuales son \(dateString) en formato ISO8601.
//
//    5. Para cada entrada, proporcione una salida estructurada que incluya los metadatos en formato JSON. Los metadatos deben incluir el tipo (GeneralKnowledge o To-Do), la descripción, la persona relevante y, si aplica, la fecha, la hora.
//
//Por favor, formatee su respuesta para incluir tanto la descripción estructurada como los metadatos correspondientes como se muestra en los siguientes ejemplos. El 'tipo' debe ser 'To-Do' o 'GeneralKnowledge'.
//
//Conocimiento General: El nombre del profesor de mi hijo Charlie es John Williams. Relevante para: Charlie.
//
//Metadata:
//{
//  "type": "GeneralKnowledge",
//  "description": "El nombre del profesor de mi hijo Charlie es John Williams.",
//  "relevantFor": "Charlie"
//}
//
//Pendientes: Programar una reunión con John Williams, Fecha: YYYY-MM-DD, Hora: HH:MM. Relevante para: actividades escolares de Charlie.
//
//Metadata:
//{
//  "type": "To-Do",
//  "description": "Programar una reunión con John Williams.",
//  "date": "YYYY-MM-DD",
//  "time": "HH:MM",
//  "relevantFor": "actividades escolares de Charlie"
//}
//
//"""
//            case .greek:
//                return """
//Παρακαλώ αναλύστε την παρακάτω απομαγνητοφώνηση μιας φωνητικής σημείωσης χρήστη που ηχογραφήθηκε σε πιθανώς θορυβώδες περιβάλλον. Η απομαγνητοφώνηση που δημιουργήθηκε από το μοντέλο Whisper μπορεί να περιλαμβάνει δισταγμούς όπως 'ααα' και θορύβους φόντου. Τα καθήκοντά σας είναι:
//    1. Να αναγνωρίσετε και να διορθώσετε οποιαδήποτε γραμματικά λάθη.
//    2. Να αφαιρέσετε ή να σημειώσετε τυχόν μη λεκτικές ενδείξεις (π.χ., 'ααα') και ενδείξεις θορύβου φόντου.
//    3. Να διευκρινίσετε ασαφείς προτάσεις, πιθανώς με αναδιατύπωση, διατηρώντας την αρχική πρόθεση.
//    4. Να εξάγετε και να τονίσετε πρακτικά στοιχεία και γενικές γνώσεις. Σε περιπτώσεις όπου το περιεχόμενο αφορά και τις δύο κατηγορίες, όπως ένα ραντεβού που είναι ταυτόχρονα καθήκον και περιέχει σημαντικές πληροφορίες, παρέχετε καταχωρήσεις και για τα 'Γενικές Γνώσεις' και για τα 'Υπενθύμιση':
//       α. Γενικές Γνώσεις: Πληροφορίες που ο χρήστης θέλει να θυμάται, συμπεριλαμβάνοντας το σχετικό πρόσωπο εάν αναφέρεται. Εάν δεν αναφέρεται σχετικό πρόσωπο πρέπει να θεωρείται ως προεπιλογή ο ίδιος ο χρήστης.
//       β. Υπενθύμιση: Καθήκοντα ή γεγονότα που ο χρήστης επιθυμεί να ορίσει υπενθύμιση, συμπεριλαμβάνοντας την εξαγωγή της σχετικής ημερομηνίας και ώρας αν αναφέρονται, και το σχετικό πρόσωπο ή πλαίσιο. Ειδικότερα, εάν ο χρήστης δεν καθορίζει ημερομηνία και ώρα, υπολογίστε ότι η τρέχουσα ημερομηνία και ώρα είναι \(dateString) σε μορφή ISO8601.
//
//    5. Για κάθε καταχώρηση, παρέχετε μια δομημένη απόκριση που περιλαμβάνει τα metadata σε μορφή JSON. Τα metadata πρέπει να περιλαμβάνουν τον τύπο (GeneralKnowledge ή ToDo), την περιγραφή, το σχετικό πρόσωπο, και εάν εφαρμόζεται, την ημερομηνία, την ώρα.
//
//Παρακαλώ διαμορφώστε την απάντησή σας για να περιλαμβάνει και τη δομημένη περιγραφή και τα αντίστοιχα metadata όπως φαίνεται στα παρακάτω παραδείγματα. Το 'type' πρέπει να είναι είτε 'ToDo' είτε 'GeneralKnowledge'.
//
//Γενικές Γνώσεις: Το όνομα του δασκάλου του γιου μου, του Τσάρλι, είναι Τζον Ουίλιαμς. Σχετικό για: Τσάρλι.
//
//Metadata:
//{
//  "type": "GeneralKnowledge",
//  "description": "Το όνομα του δασκάλου του γιου μου Τσάρλι, είναι Τζον Ουίλιαμς.",
//  "relevantFor": "Τσάρλι"
//}
//
//Υπενθύμιση: Προγραμματίστε συνάντηση με τον Τζον Ουίλιαμς, Ημερομηνία: YYYY-MM-DD, Ώρα: HH:MM. Σχετικό για: Σχολικές δραστηριότητες του Τσάρλι.
//
//Metadata:
//{
//  "type": "ToDo",
//  "description": "Προγραμματίστε συνάντηση με τον Τζον Ουίλιαμς.",
//  "date": "YYYY-MM-DD",
//  "time": "HH:MM",
//  "relevantFor": "Σχολικές δραστηριότητες του Τσάρλι"
//}
//"""
//            }
//        }
//    }
}
