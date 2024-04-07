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
    @Published var progressText: String = ""
    private var lastGptAudioResponse: URL?
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
    func clearManager() {
        
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
        //        print("clearManager() called.")
    }

    //MARK: performAIOperations (DEPRECATED)
    func performOpenAiOperations(filepath: URL, language: LanguageCode? = nil, userAskingQuestion: Bool) async {
        
        print("performOpenAiOperations Called")
        if userAskingQuestion {
            ProgressTracker.shared.setProgress(to: 0.22)
            await requestTranscript(for: filepath, userAskingQuestion: userAskingQuestion)
            ProgressTracker.shared.setProgress(to: 0.42)
            
            if let whisperResponse  = self.whisperResponse {
                await analyzeTranscript(whisperResponse: whisperResponse, userIsAsking: userAskingQuestion)
            }
        } else { // !! USer is not Asking! --> add new !!
            
            await requestTranscript(for: filepath, userAskingQuestion: userAskingQuestion)
            ProgressTracker.shared.setProgress(to: 0.42)
            
            if let whisperResponse  = self.whisperResponse {
                await analyzeTranscript(whisperResponse: whisperResponse, userIsAsking: userAskingQuestion)
            }
        }
        
    }
    

//MARK: requestTranscript
    func requestTranscript(for filepath: URL, language: LanguageCode? = nil, userAskingQuestion: Bool) async {
        
        print("requestTranscript called")
        do {
            let transcriptionResponse = try await getTranscript(for: filepath, language: self.selectedLanguage, userAskingQuestion: userAskingQuestion)
            await MainActor.run {
                self.whisperResponse = transcriptionResponse.response
            }
        } catch {
            print("Error on completion of transcriptResponse: \(error)")
        }
    }

    //MARK: private getTranscript
    private func getTranscript(for filepath: URL, language: LanguageCode, userAskingQuestion: Bool) async throws -> TranscriptionResponse {
        
        guard let url = URL(string: "https://api.openai.com/v1/audio/transcriptions") else {
            throw URLError(.badURL)
        }
        
        guard let apiKey = ApiConfiguration.openAIKey else {
            
            throw AppNetworkError.apiKeyNotFound //TODO: maake custom Error Across the app!
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Append parts to the body
        let parts = [
            ("language", language.rawValue),
            ("prompt", self.getWhisperPrompt(userAskingQuestion: userAskingQuestion)),
            ("model", "whisper-1")
        ]
        
        for (key, value) in parts {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        
        // Append audio file data
        if let fileData = try? Data(contentsOf: filepath) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"recording.m4a\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
            body.append(fileData)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        
        let (data, _) = try await URLSession.shared.data(for: request)
        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                print("DEBUG WHISPER RESPONSE:")
                print(json)
            }
        } catch {
            print("Error serializing JSON: \(error.localizedDescription)")
        }
        return try JSONDecoder().decode(TranscriptionResponse.self, from: data)
    }
    

    //MARK: analyzeTranscript
    func analyzeTranscript(whisperResponse: String, userIsAsking: Bool) async {
        
        print("analyzeTranscript Called")
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions"),
              let apiKey = ApiConfiguration.openAIKey else {
            print("analyzeTranscript :: Invalid URL or API Key not found")
            return
        }
        
        let prompt = self.getGptPrompt(userIsAsking: userIsAsking)
        let requestBody: [String: Any] = [
            "model": "gpt-4-0125-preview",
            "temperature": 0,
            "messages": [
                ["role": "system", "content": prompt],
                ["role": "user", "content": whisperResponse]
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        ProgressTracker.shared.setProgress(to: 0.75)
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody, options: [])
            ProgressTracker.shared.setProgress(to: 0.85)
            request.httpBody = jsonData
            
            let (data, _) = try await URLSession.shared.data(for: request)
            
            await self.processResponse(data: data, responseError: nil, userIsAsking: userIsAsking)
            
        } catch {
            print("analyzeTranscript :: Error: \(error.localizedDescription)")
        }
    }
    
    //MARK: private processResponse
    private func processResponse(data: Data?, responseError: Error?, userIsAsking: Bool) async {
        
        print("processResponse called")
        guard let data = data else {
            if let error = responseError {
                print("processResponse() :: Network request error: \(error.localizedDescription)")
            } else {
                print("processResponse() :: No data received and no error found.")
            }
            return
        }
        ProgressTracker.shared.setProgress(to: 0.99)
        do {
            let response = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
            if let firstChoice = response.choices.first {
                let content = firstChoice.message.content
                
                //                let delimiter = "\nMetadata:\n"
                let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
                let parts = trimmedContent.components(separatedBy: CharacterSet.newlines).map { $0.trimmingCharacters(in: .whitespaces) }
                if let metadataIndex = parts.firstIndex(where: { $0 == "Metadata:" }) {
                    let jsonString = parts[metadataIndex...].dropFirst().joined(separator: " ")
                    if let jsonData = jsonString.data(using: .utf8) {
                        do {
                            if let rawString = String(data: jsonData, encoding: .utf8) {
                                print("processResponse() :: Received raw data before attemp to decode: \(rawString)")
                            }
                            let metadata = try JSONDecoder().decode(MetadataResponse.self, from: jsonData)
                            
                            await MainActor.run {
                                if metadata.type.lowercased() == "question" {
                                    ProgressTracker.shared.setProgress(to: 1.0)
                                    self.gptMetadataResponseOnQuestion = metadata
                                    print("gptMetadataResponseOnQuestion SET NOW")
                                } else {
                                    self.gptMetadataResponse = metadata
                                }
                            }
                        } catch let DecodingError.dataCorrupted(context) {
                            print("processResponse() :: Data corrupted: \(context)")
                        } catch let DecodingError.keyNotFound(key, context) {
                            print("processResponse() :: Key '\(key)' not found: \(context.debugDescription), codingPath: \(context.codingPath)")
                        } catch let DecodingError.valueNotFound(value, context) {
                            print("processResponse() :: Value '\(value)' not found: \(context.debugDescription), codingPath: \(context.codingPath)")
                        } catch let DecodingError.typeMismatch(type, context) {
                            print("processResponse() :: Type '\(type)' mismatch: \(context.debugDescription), codingPath: \(context.codingPath)")
                        } catch {
                            print("processResponse() :: Unknown error: \(error)")
                        }
                    }
                } else {
                    print("processResponse() :: No JSON metadata found or format is unexpected.")
                }
            }
        } catch let decodingError {
            print("processResponse() :: JSON Parsing catched error: \(decodingError)")
        }
    }
    
    
    func updateMetadataResponse(type: String, description: String, relevantFor: String) async {
        DispatchQueue.main.async {
            self.gptMetadataResponseOnQuestion?.type = type
            self.gptMetadataResponseOnQuestion?.description = description
            self.gptMetadataResponseOnQuestion?.relevantFor = relevantFor
        }
    }
    
    //MARK: requestEmbeddings
    // call with MetadataResponse.description
    func requestEmbeddings(for text: String, isQuestion: Bool) async {
        print("request Embeddings called..")
        ProgressTracker.shared.setProgress(to: 0.1)
        await MainActor.run {
            progressText = "Requesting Embeddings..."
        }
        do {
            let response = try await fetchEmbeddings(for: text)
            print("Embeddings Fetch completed successfully.")
            
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                
                for embedding in response.data {
                    if isQuestion {
                        self.embeddingsFromQuestion.append(contentsOf: embedding.embedding)
                    } else {
                        self.embeddings.append(contentsOf: embedding.embedding)
                    }
                }
                
                if isQuestion {
                    self.questionEmbeddingsCompleted = true
                        progressText = "Embeddings Received..."
                    
                    print("$questionEmbeddingsCompleted = true and Embeddings: OK")
                } else {
                    self.embeddingsCompleted = true
                }
            }
        } catch {
            print("Error fetching embeddings: \(error)")
        }
        if isQuestion {
            ProgressTracker.shared.setProgress(to: 0.25)
        } else {
            ProgressTracker.shared.setProgress(to: 0.6)
        }
    }
    
    
    
    // https://api.openai.com/v1/embeddings POST
    //model: text-embedding-3-large
    // inputText: description of the gpt-4 response.
    //MARK: private fetchEmbeddings
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
            progressText = "Embeddings status: \(httpResponse.statusCode)"
        }
        let decoder = JSONDecoder()
        return try decoder.decode(EmbeddingsResponse.self, from: data)
    }
    
    
    
    func getGptResponseAndConvertTextToSpeech(queryMatches: [String], question: String) async throws {
        await MainActor.run {
            progressText = "Forming response..."
        }

        ProgressTracker.shared.setProgress(to: 0.7)
        guard let apiKey = ApiConfiguration.openAIKey else {
            throw AppNetworkError.apiKeyNotFound
        }
        
        let gptResponse = try await getGptResponse(apiKey: apiKey, vectorResponses: queryMatches, question: question)
        await MainActor.run {
            self.stringResponseOnQuestion = gptResponse
        }
        ProgressTracker.shared.setProgress(to: 0.75)
        
        try await convertTextToSpeech(text: gptResponse, apiKey: apiKey)
    }
    
    private func getGptResponse(apiKey: String, vectorResponses: [String], question: String) async throws -> String {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw AppNetworkError.invalidOpenAiURL
        }
        await MainActor.run {
            progressText = "Forming response for Audio..."
        }
        let prompt = getGptPromptForAudio(vectorResponses: vectorResponses, question: question)
        
        let requestBody: [String: Any] = [
            "model": "gpt-4-0125-preview",  //to turbo
            "temperature": 0,
            "messages": [["role": "system", "content": prompt]]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AppNetworkError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        let gptResponse = try decoder.decode(ChatCompletionResponse.self, from: data)
        guard let firstChoice = gptResponse.choices.first else {
            throw NSError(domain: "AppError", code: 3, userInfo: [NSLocalizedDescriptionKey: "No choices in GPT response"])
        }
        
        return firstChoice.message.content
    }
    
    private func convertTextToSpeech(text: String, apiKey: String) async throws {
        guard let url = URL(string: "https://api.openai.com/v1/audio/speech") else {
            throw AppNetworkError.invalidTTSURL
        }
        await MainActor.run {
            progressText = "Converting text to Speech"
        }
        ProgressTracker.shared.setProgress(to: 0.75)
        let requestBody: [String: Any] = [
            "model": "tts-1",
            "input": text,
            "voice": "alloy"
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        
        let (data, _) = try await URLSession.shared.data(for: request)
        ProgressTracker.shared.setProgress(to: 0.85)
        try await saveAndPlayAudio(data: data)
    }
    
    
    
    
    @MainActor
    private func saveAndPlayAudio(data: Data) async throws {
        let fileManager = FileManager.default
        guard let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw AppNetworkError.unknownError("saveAndPlayAudio() :: Could not find the document directory.")
        }
        
        let fileURL = documentDirectory.appendingPathComponent("GptReply\(Date()).mp3")
        
        do {
            if (self.gptMetadataResponseOnQuestion != nil) {
                self.gptMetadataResponseOnQuestion?.fileUrl = fileURL
            }
            try data.write(to: fileURL)
            lastGptAudioResponse = fileURL
            await MainActor.run {
                progressText = "Audio received."
            }
            print("Audio [Reply] saved: \(fileURL.path)")
            ProgressTracker.shared.setProgress(to: 0.99)
            AudioManager.shared.playAudioFrom(url: fileURL)
            
            
        } catch {
            throw AppNetworkError.unknownError("saveAndPlayAudio() :: Failed to save audio: \(error.localizedDescription)")
        }
        await MainActor.run {
            progressText = ""
        }
    }
    
    
    private func getGptPromptForAudio(vectorResponses: [String], question: String) -> String {
//        let now = Date()
        // For ISO8601 date-time string
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.timeZone = TimeZone.current
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let isoDateString = isoFormatter.string(from: Date()) // Use for precise timestamps
        
        // For human-readable date string with day of the week
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMMM d, yyyy" // Format: Day, Month Date, Year
        let readableDateString = dateFormatter.string(from: Date()) // "Sunday, March 3, 2024"
        
        
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
                    You are an AI assistant, and you have been asked to provide concise information on a specific topic. Below are user's question and one or two relevant information as retrieved by the vector database:
                
                    - User's Question: \(question)
                    - Relevant Information 1: \(firstVector)
                    - Relevant Information 2: \(secondVector)
                
                    Using the user's question and the information provided, generate a comprehensive and informative reply that addresses the user's inquiry, integrating insights from the relevant information found. if relevant for your reply, today is \(readableDateString), and the current time in ISO8601 format is \(isoDateString). Don't return full dates and time unless necessary. If the information from the vector database does not directly relate to the user's question or seems ambiguous, use your best judgment to provide a helpful response. Highlight any uncertainties and suggest user to provide additional information that might be required for a more accurate answer.
                
                    The response should be clear, engaging, concise, short and suitable for converting to audio to be read to the user.
                """
        case .spanish:
            return """
                Eres un asistente de IA y se te ha solicitado proporcionar información concisa sobre un tema específico. A continuación se encuentran la pregunta del usuario y una o dos informaciones relevantes según lo recuperado por la base de datos vectorial:
                
                               - Pregunta del Usuario: \(question)
                               - Información Relevante 1: \(firstVector)
                               - Información Relevante 2: \(secondVector)
                
                               Utilizando la pregunta del usuario y la información proporcionada, genera una respuesta comprensiva e informativa que aborde la consulta del usuario, integrando perspectivas de la información relevante encontrada. Si es relevante para tu respuesta, hoy es \(readableDateString), y la hora actual en formato ISO8601 es \(isoDateString). No devuelvas fechas y horas completas a menos que sea necesario. Si la información de la base de datos vectorial no se relaciona directamente con la pregunta del usuario o parece ambigua, usa tu mejor criterio para proporcionar una respuesta útil. Destaca cualquier incertidumbre y sugiere al usuario proporcionar información adicional que pueda ser requerida para una respuesta más precisa.
                
                               La respuesta debe ser clara, atractiva, concisa, corta y adecuada para convertir en audio para ser leída al usuario.
                
                
                """
        case .french:
            return """
                Vous êtes un assistant IA et on vous a demandé de fournir des informations concises sur un sujet spécifique. Voici la question de l'utilisateur et une ou deux informations pertinentes extraites de la base de données vectorielle :
                                
                                    - Question de l'Utilisateur : \(question)
                                    - Information Pertinente 1 : \(firstVector)
                                    - Information Pertinente 2 : \(secondVector)
                                
                                    En utilisant la question de l'utilisateur et les informations fournies, générez une réponse complète et informative qui traite la demande de l'utilisateur, intégrant les perspectives des informations pertinentes trouvées. Si pertinent pour votre réponse, aujourd'hui est le \(readableDateString), et l'heure actuelle au format ISO8601 est \(isoDateString). Ne retournez pas de dates et d'heures complètes à moins que cela soit nécessaire. Si l'information de la base de données vectorielle ne se rapporte pas directement à la question de l'utilisateur ou semble ambiguë, utilisez votre meilleur jugement pour fournir une réponse utile. Soulignez toute incertitude et suggérez à l'utilisateur de fournir des informations supplémentaires qui pourraient être requises pour une réponse plus précise.
                                
                                    La réponse doit être claire, engageante, concise, courte et adaptée pour être convertie en audio pour être lue à l'utilisateur.
                
                """
        case .german:
            return """
                    Sie sind ein KI-Assistent und wurden gebeten, präzise Informationen zu einem spezifischen Thema zu liefern. Im Folgenden finden Sie die Frage des Benutzers und ein oder zwei relevante Informationen, die durch die Vektordatenbank abgerufen wurden:
                
                                        - Frage des Benutzers: \(question)
                                        - Relevante Information 1: \(firstVector)
                                        - Relevante Information 2: \(secondVector)
                
                                        Unter Verwendung der Frage des Benutzers und der bereitgestellten Informationen, erstellen Sie eine umfassende und informative Antwort, die die Anfrage des Benutzers beantwortet, indem Sie Einblicke aus den gefundenen relevanten Informationen integrieren. Wenn es für Ihre Antwort relevant ist, heute ist der \(readableDateString), und die aktuelle Zeit im ISO8601-Format ist \(isoDateString). Geben Sie vollständige Daten und Zeiten nur dann zurück, wenn es notwendig ist. Wenn die Informationen aus der Vektordatenbank nicht direkt mit der Frage des Benutzers zusammenhängen oder mehrdeutig erscheinen, verwenden Sie Ihr bestes Urteilsvermögen, um eine hilfreiche Antwort zu geben. Heben Sie Unsicherheiten hervor und schlagen Sie dem Benutzer vor, zusätzliche Informationen bereitzustellen, die für eine genauere Antwort erforderlich sein könnten.
                
                                        Die Antwort sollte klar, ansprechend, präzise, kurz und geeignet sein, um in Audio umgewandelt und dem Benutzer vorgelesen zu werden.
                """
        }
    }
    
    private func getWhisperPrompt(userAskingQuestion: Bool) -> String {
        if userAskingQuestion {
            switch selectedLanguage {
            case .english:
                return "The user is asking a question. Please transcribe the question accurately, excluding any hesitations like 'ahhm' and background noises."
            case .french:
                return "L'utilisateur pose une question. Veuillez transcrire la question avec précision, en incluant les hésitations comme 'euh' et les bruits de fond."
            case .german:
                return "Der Benutzer stellt eine Frage. Bitte transkribieren Sie die Frage genau, einschließlich Zögern wie 'ähm' und Hintergrundgeräusche."
            case .spanish:
                return "El usuario está haciendo una pregunta. Transcriba la pregunta con precisión, incluyendo vacilaciones como 'ehm' y ruidos de fondo."
            }
        } else {
            switch selectedLanguage {
            case .english:
                return "This is an audio recording from the user and may include hesitations like 'ahhm' and background noises. Please return the transcript."
            case .french:
                return "Ceci est un enregistrement audio de l'utilisateur et peut inclure des hésitations comme 'euh' et des bruits de fond. Veuillez retourner la transcription."
            case .german:
                return "Dies ist eine Audioaufnahme vom Benutzer und kann Zögern wie 'ähm' und Hintergrundgeräusche enthalten. Bitte geben Sie das Transkript zurück."
            case .spanish:
                return "Esta es una grabación de audio del usuario y puede incluir vacilaciones como 'ehm' y ruidos de fondo. Por favor, devuelva la transcripción."
            }
        }
    }
    
    
    private func getGptPrompt(userIsAsking: Bool) -> String {
        
        let now = Date()
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let dateString = formatter.string(from: now)
        //        print("gpt prompted with \(dateString)")
        
        if userIsAsking {
            switch selectedLanguage {
            case .english:
                return """
                        Please analyze the following transcript of a user's question, recorded in a possibly noisy environment. The transcript generated by the Whisper model may include hesitations like 'ahhm', background noises, and uncertain transcriptions (e.g., '[inaudible]'). Your tasks are to:
                        1. Identify and correct any grammatical errors, ensuring the language is clear and professional.
                        2. Completely remove non-verbal cues (e.g., 'ahhm') and background noise indications, as these do not contribute to the database query. Do not annotate; simply omit these elements for clarity.
                        3. Clarify unclear sentences, possibly by rephrasing, while maintaining the original intent. Focus on preserving the essence of the question asked. Make educated guesses to fill in or omit uncertain transcriptions based on context, prioritizing the overall coherence and relevance of the question.
                        4. Extract and succinctly restate the question or inquiry posed by the user. This will be used to query a vector database and should be precise and to the point. Emphasize any actionable items or key terms that are critical for retrieving the most relevant information from the database. Assign this to the "description" key of the Metadata.
                        5. Include any relevant contextual information that could consistently apply to the queries being processed, enhancing the precision of the database search.
                        
                        Please format your response to include both the refined question as asked by the user and the corresponding metadata, as shown in the following example. 'type' should be 'Question'!
                        
                        Metadata:
                        {
                          "type": "Question",
                          "description": "What are the opening hours of the local library?",
                          "keywords": ["opening hours", "local library"],
                          "relevantFor": "local library information search"
                        }
                        """
            case .spanish:
                return """
                        Por favor, analiza el siguiente transcripto de una pregunta de un usuario, grabada en un ambiente posiblemente ruidoso. El transcripto generado por el modelo Whisper puede incluir vacilaciones como 'ahhm', ruidos de fondo e transcripciones inciertas (p.ej., '[inaudible]'). Tus tareas son:
                                                1. Identificar y corregir cualquier error gramatical, asegurando que el lenguaje sea claro y profesional.
                                                2. Eliminar completamente las señales no verbales (p.ej., 'ahhm') y las indicaciones de ruido de fondo, ya que estos no contribuyen a la consulta de la base de datos. No anotes; simplemente omite estos elementos para claridad.
                                                3. Aclarar oraciones poco claras, posiblemente reformulándolas, manteniendo la intención original. Concéntrate en preservar la esencia de la pregunta realizada. Haz conjeturas educadas para completar u omitir transcripciones inciertas basándote en el contexto, priorizando la coherencia general y la relevancia de la pregunta.
                                                4. Extraer y reiterar de manera sucinta la pregunta o consulta planteada por el usuario. Esto se utilizará para consultar una base de datos vectorial y debe ser preciso y al punto. Enfatiza cualquier ítem de acción o términos clave que sean críticos para recuperar la información más relevante de la base de datos. Asigna esto a la clave "description" de los Metadatos.
                                                5. Incluir cualquier información contextual relevante que podría aplicarse consistentemente a las consultas siendo procesadas, mejorando la precisión de la búsqueda en la base de datos.
                        
                                                Por favor, formatea tu respuesta para incluir tanto la pregunta refinada tal como la hizo el usuario como los metadatos correspondientes, como se muestra en el ejemplo:
                        
                                                Metadatos:
                                                {
                                                  "type": "Pregunta",
                                                  "description": "¿Cuáles son los horarios de apertura de la biblioteca local?",
                                                  "keywords": ["horarios de apertura", "biblioteca local"],
                                                  "relevantFor": "búsqueda de información sobre biblioteca local"
                                                }
                        
                        """
            case .french:
                return """
                        Veuillez analyser le transcript suivant d'une question d'utilisateur, enregistrée dans un environnement potentiellement bruyant. Le transcript généré par le modèle Whisper peut inclure des hésitations telles que 'ahhm', des bruits de fond et des transcriptions incertaines (par ex., '[inaudible]'). Vos tâches sont de :
                                                1. Identifier et corriger toute erreur grammaticale, en assurant que le langage est clair et professionnel.
                                                2. Supprimer complètement les indices non verbaux (par ex., 'ahhm') et les indications de bruit de fond, car ils ne contribuent pas à la requête de la base de données. Ne pas annoter ; simplement omettre ces éléments pour plus de clarté.
                                                3. Clarifier les phrases incertaines, éventuellement en les reformulant, tout en maintenant l'intention originale. Concentrez-vous sur la préservation de l'essence de la question posée. Faites des suppositions éclairées pour remplir ou omettre les transcriptions incertaines en fonction du contexte, en priorisant la cohérence globale et la pertinence de la question.
                                                4. Extraire et reformuler de manière succincte la question ou la demande posée par l'utilisateur. Cela sera utilisé pour interroger une base de données vectorielle et doit être précis et concis. Soulignez tous les éléments d'action ou termes clés qui sont critiques pour récupérer les informations les plus pertinentes de la base de données. Assignez ceci à la clé "description" des Métadonnées.
                                                5. Inclure toute information contextuelle pertinente qui pourrait s'appliquer de manière cohérente aux requêtes en cours de traitement, améliorant la précision de la recherche dans la base de données.
                        
                                                  Veuillez formater votre réponse pour inclure à la fois la question raffinée telle que posée par l'utilisateur et les métadonnées correspondantes, comme montré dans l'exemple :
                        
                                                Métadonnées :
                                                {
                                                  "type": "Question",
                                                  "description": "Quels sont les horaires d'ouverture de la bibliothèque locale ?",
                                                  "keywords": ["horaires d'ouverture", "bibliothèque locale"],
                                                  "relevantFor": "recherche d'information sur la bibliothèque locale"
                                                }
                        
                        """
            case .german:
                return """
                        Bitte analysiere das folgende Transkript einer Benutzerfrage, aufgenommen in einer möglicherweise lauten Umgebung. Das durch das Whisper-Modell generierte Transkript kann Zögern wie 'ahhm', Hintergrundgeräusche und unsichere Transkriptionen (z.B. '[unverständlich]') enthalten. Deine Aufgaben sind:
                                    1. Identifiziere und korrigiere jegliche grammatikalische Fehler, um sicherzustellen, dass die Sprache klar und professionell ist.
                                    2. Entferne vollständig nicht-verbale Hinweise (z.B. 'ahhm') und Angaben zu Hintergrundgeräuschen, da diese nicht zur Datenbankabfrage beitragen. Nicht annotieren; einfach diese Elemente zur Klarheit weglassen.
                                    3. Kläre unklare Sätze, möglicherweise durch Umformulierung, während du die ursprüngliche Absicht beibehältst. Konzentriere dich darauf, die Essenz der gestellten Frage zu bewahren. Mache gebildete Vermutungen, um unsichere Transkriptionen basierend auf dem Kontext zu ergänzen oder wegzulassen, wobei die Gesamtkohärenz und Relevanz der Frage Priorität haben.
                                    4. Extrahiere und formuliere die vom Benutzer gestellte Frage oder Anfrage prägnant neu. Dies wird verwendet, um eine Vektor-Datenbank abzufragen und sollte präzise und auf den Punkt sein. Betone alle handlungsrelevanten Punkte oder Schlüsselbegriffe, die für die Abrufung der relevantesten Informationen aus der Datenbank entscheidend sind. Weise dies dem Schlüssel "description" der Metadaten zu.
                                    5. Beziehe alle relevanten Kontextinformationen ein, die konsistent auf die verarbeiteten Anfragen angewendet werden könnten, um die Präzision der Datenbanksuche zu erhöhen.
                        
                                    Bitte formatiere deine Antwort so, dass sie sowohl die verfeinerte Frage, wie sie vom Benutzer gestellt wurde, als auch die entsprechenden Metadaten enthält, wie im Beispiel gezeigt:
                        
                                    Metadaten:
                                    {
                                      "type": "Frage",
                                      "description": "Was sind die Öffnungszeiten der örtlichen Bibliothek?",
                                      "keywords": ["Öffnungszeiten", "örtliche Bibliothek"],
                                      "relevantFor": "Suche nach Informationen zur örtlichen Bibliothek"
                                    }
                        
                        """
            }
        } else {
            
            switch selectedLanguage {
            case .english:
                return """
Please analyze the following transcript of a user's voice note recorded in a possibly noisy environment. The transcript generated by the whisper model may include hesitations like 'ahhm' and background noises. Your tasks are to:
    1. Identify and correct any grammatical errors.
    2. Remove or note any non-verbal cues (e.g., 'ahhm') and background noise indications.
    3. Clarify unclear sentences, possibly by rephrasing, while maintaining the original intent.
    4. Extract and highlight actionable items and general knowledge. In cases where the content applies to both categories, such as an appointment that is both a task and contains significant information, provide entries for both 'To-Do' and 'General Knowledge':
       a. General Knowledge: Information the user wants to remember, including the relevant person if mentioned. If relevant person is not mentioned should default to user.
       b. To-Do: Tasks or events the user wishes to set a notification for, including extracting the relevant date and time if mentioned, and the relevant person or context. Specifically, if the user does not specify a date and time, calculate it given that the current date and time is \(dateString) in ISO8601 format.

    5. For each entry, provide a structured output that includes the metadata in JSON format. The metadata should include the type (GeneralKnowledge and/or To-Do), the description,the relevant person, and if applicable, the date, time.

Please format your response to include both the structured description and the corresponding metadata as shown in the following examples. 'type' should be either 'ToDo' or 'GeneralKnowledge'.

General Knowledge: The name of my son Charlie's teacher is John Williams. Relevant for: Charlie.

Metadata:
{
  "type": "GeneralKnowledge",
  "description": "The name of my son Charlie's teacher is John Williams.",
  "relevantFor": "Charlie"
}

To-Do: Schedule a meeting with John Williams, Date: YYYY-MM-DD, Time: HH:MM. Relevant for: Charlie's school activities.

Metadata:
{
  "type": "ToDo",
  "description": "Schedule a meeting with John Williams.",
  "date": "YYYY-MM-DD",
  "time": "HH:MM",
  "relevantFor": "Charlie's school activities"
}

"""
                //TODO: other languages do not have the new, corrected english prompt. translate and paste below.
            case .french:
                return """
            Veuillez analyser la transcription suivante d'une note vocale d'un utilisateur enregistrée dans un environnement potentiellement bruyant. La transcription générée par le modèle Whisper peut inclure des hésitations telles que 'euh' et des bruits de fond. Vos tâches sont de :
            
            Identifier et corriger les erreurs grammaticales.
            Retirer ou noter les indices non verbaux (par ex., 'euh') et les indications de bruit de fond.
            Clarifier les phrases peu claires, éventuellement en les reformulant, tout en conservant l'intention originale.
            Extraire et mettre en évidence les éléments d'action et les connaissances générales. Catégorisez spécifiquement la sortie en :
            a. Connaissance Générale : Informations que l'utilisateur souhaite se rappeler, y compris la personne pertinente ou le contexte si mentionné.
            b. À Faire : Tâches ou événements pour lesquels l'utilisateur souhaite définir une notification, y compris l'extraction de la date et de l'heure pertinentes si mentionnées et de la personne ou du contexte pertinent.
            Pour chaque entrée, fournissez une sortie structurée qui inclut la description et, le cas échéant, la date et l'heure de l'événement ou de la tâche, ainsi que la personne ou le contexte pertinent.
            Veuillez formater votre réponse comme suit :
            Pour les entrées de Connaissance Générale : Commencez par "Connaissance Générale :" suivi des informations, y compris toute personne pertinente ou contexte.
            Pour les éléments À Faire : Commencez par "À Faire :" suivi de la tâche. Si une date et une heure sont mentionnées, incluez-les au format "Date : [date], Heure : [heure]." Incluez également toute personne ou contexte pertinent.
            Réponse exemple :
            Connaissance Générale : Le nom de l'enseignant de mon fils Lucas est M. Dubois. Pertinent pour : Guillaume.
            À Faire : Planifier une réunion avec M. Dubois, Date : [date], Heure : [heure]. Pertinent pour les activités scolaires de Guillaume.
            """
            case .german:
                return """
"Bitte analysieren Sie das folgende Transkript einer Sprachnotiz eines Benutzers, die in einer möglicherweise lauten Umgebung aufgenommen wurde. Das Transkript wurde vom Whisper-Modell generiert und kann Zögern wie 'ähm' und Hintergrundgeräusche enthalten. Ihre Aufgaben sind:
    Identifizieren und korrigieren Sie grammatische Fehler.
    Entfernen oder notieren Sie nonverbale Hinweise (z.B. 'ähm') und Anzeichen von Hintergrundgeräuschen.
    Klären Sie unklare Sätze, eventuell durch Umformulierung, unter Beibehaltung der ursprünglichen Absicht.
    Extrahieren und heben Sie handlungsrelevante Punkte und Allgemeinwissen hervor. Kategorisieren Sie spezifisch das Ergebnis in:
    a. Allgemeinwissen: Informationen, die der Benutzer sich merken möchte, einschließlich der relevanten Person oder des Kontextes, falls erwähnt.
    b. Zu erledigen: Aufgaben oder Ereignisse, für die der Benutzer eine Benachrichtigung einstellen möchte, einschließlich der Extrahierung des relevanten Datums und der Zeit, falls erwähnt, und der relevanten Person oder des Kontexts.
    Geben Sie für jeden Eintrag eine strukturierte Ausgabe an, die die Beschreibung und gegebenenfalls das Datum und die Zeit der Veranstaltung oder Aufgabe sowie die relevante Person oder den Kontext enthält.
    Bitte formatieren Sie Ihre Antwort wie folgt:
    Für Einträge zum Allgemeinwissen: Beginnen Sie mit "Allgemeinwissen:", gefolgt von den Informationen, einschließlich aller relevanten Personen oder Kontexte.
    Für Zu erledigen-Einträge: Beginnen Sie mit "Zu erledigen:", gefolgt von der Aufgabe. Wenn ein Datum und eine Zeit genannt werden, fügen Sie diese im Format "Datum: [Datum], Zeit: [Zeit]." ein. Schließen Sie auch alle relevanten Personen oder Kontexte ein.
    Beispielantwort:
    Allgemeinwissen: Der Name des Lehrers meines Sohnes Max ist Herr Schmidt. Relevant für: Max.
    Zu erledigen: Vereinbaren Sie ein Treffen mit Herrn Schmidt, Datum: [Datum], Zeit: [Zeit]. Relevant für: Max’ schulische Aktivitäten.
"""
            case .spanish:
                return """
Por favor, analice la siguiente transcripción de una nota de voz de un usuario grabada en un entorno posiblemente ruidoso. La transcripción generada por el modelo Whisper puede incluir hesitaciones como 'ehm' y ruidos de fondo. Sus tareas son:
Identificar y corregir errores gramaticales.
Eliminar o anotar cualquier indicio no verbal (p.ej., 'ehm') y señales de ruido de fondo.
Aclarar frases poco claras, posiblemente reformulándolas, manteniendo la intención original.
Extraer y resaltar elementos de acción e información general. Específicamente, categorice la salida en:
a. Conocimiento General: Información que el usuario desea recordar, incluyendo la persona relevante o el contexto si se menciona.
b. Tareas: Tareas o eventos para los cuales el usuario desea configurar una notificación, incluyendo la extracción de la fecha y hora relevantes si se mencionan y la persona o contexto relevante.
Para cada entrada, proporcione una salida estructurada que incluya la descripción y, si es aplicable, la fecha y hora del evento o tarea, y la persona o contexto relevante.
Por favor, formatee su respuesta de la siguiente manera:
Para entradas de Conocimiento General: Comience con "Conocimiento General:" seguido de la información, incluyendo cualquier persona relevante o contexto.
Para las tareas: Comience con "Tareas:" seguido de la tarea. Si se menciona una fecha y hora, inclúyalas en el formato "Fecha: [fecha], Hora: [hora]." Incluya también cualquier persona o contexto relevante.
Respuesta de ejemplo:
Conocimiento General: El nombre del maestro de mi hijo Carlos es Juan Martínez. Relevante para: Carlos.
Tareas: Programar una reunión con Juan Martínez, Fecha: [fecha], Hora: [hora]. Relevante para las actividades escolares de Carlos.
"""
            }
        }
    }
}
