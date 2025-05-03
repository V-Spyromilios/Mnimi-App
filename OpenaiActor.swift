//
//  OpenaiActor.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 31.10.24.
//

import Foundation


enum OpenAIError: DisplayableError {
    case embeddingsFailed(Error)
    case gptResponseFailed(Error)
    case transriptionFailed(Error)
    case reminderError(Error)
    case unknown(Error)

    var id: String { message }

    var title: String {
        switch self {
        case .embeddingsFailed: return "Embeddings Error"
        case .gptResponseFailed: return "GPT Error"
        case .transriptionFailed: return "Transcription Error"
        case .reminderError: return "Reminder Error"
        case .unknown: return "Unexpected Error"
        }
    }

    var message: String {
        switch self {
        case .embeddingsFailed(let e),
             .gptResponseFailed(let e),
             .transriptionFailed(let e),
             .reminderError(let e),
             .unknown(let e):
            return e.localizedDescription
        }
    }
}

// MARK: - Equatable
extension OpenAIError: Equatable {
    static func == (lhs: OpenAIError, rhs: OpenAIError) -> Bool {
        switch (lhs, rhs) {
        case (.embeddingsFailed(let lhsError), .embeddingsFailed(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
            
        case (.gptResponseFailed(let lhsError), .gptResponseFailed(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
            
            case (.transriptionFailed(let lhsError), .transriptionFailed(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
            
        case (.unknown(let lhsError), .unknown(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
            
        default:
            return false
        }
    }
}

// MARK: TIP: Equatable Needed for .onChange!!!
extension OpenAIError: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(localizedDescription)
    }
}


actor OpenAIActor {
    
    private let apiKey: String?
    
    // MARK: - Initializer
    init() {
        self.apiKey = ApiConfiguration.openAIKey
        debugLog("OpenAI Actor Initialized with apiKey: \(String(describing: apiKey))")
    }
    
    // MARK: - Methods
    
    /// Calls OpenAI Whisper API with retry mechanism
    func transcribeAudio(fileURL: URL) async throws -> WhisperResponse {
        let maxAttempts = 3
        var attempts = 0
        var lastError: Error?
        guard let apiKey = self.apiKey else {
            throw AppNetworkError.apiKeyNotFound
        }
        
        while attempts < maxAttempts {
            do {
                guard let url = URL(string: "https://api.openai.com/v1/audio/transcriptions") else {
                    throw AppNetworkError.invalidOpenAiURL
                }
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                
                // Swift 6 Improvement: Use `let boundary = UUID().uuidString` inline
                let boundary = UUID().uuidString
                request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
                
                let formData = try createMultipartFormData(fileURL: fileURL, boundary: boundary)
                
                // Swift 6: Improved structured concurrency (async let for request)
                async let (data, response) = URLSession.shared.upload(for: request, from: formData)
                
                let (receivedData, receivedResponse) = try await (data, response)
                
                //Swift 6: Improved error handling with `.failure`
                guard let httpResponse = receivedResponse as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    throw AppNetworkError.invalidResponse
                }
                
                return try JSONDecoder().decode(WhisperResponse.self, from: receivedData)
            } catch {
                lastError = error
                attempts += 1
                if attempts < maxAttempts {
                    try await Task.sleep(nanoseconds: 201_000_000) // 0.2s retry delay
                }
            }
        }
        
        throw lastError ?? AppNetworkError.unknownError("Failed to transcribe audio.")
    }
    
    /// Creates a multipart/form-data body for the Whisper API request
    private func createMultipartFormData(fileURL: URL, boundary: String) throws -> Data {

        var body = Data()
        let boundaryPrefix = "--\(boundary)\r\n"
        
        func append(_ string: String) {
            if let data = string.data(using: .utf8) {
                body.append(data)
            }
        }

        // Attach file
        let fileData = try Data(contentsOf: fileURL)
        let filename = fileURL.lastPathComponent
        let mimeType = "audio/m4a" // or detect dynamically if needed

        append(boundaryPrefix)
        append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n")
        append("Content-Type: \(mimeType)\r\n\r\n")
        body.append(fileData)
        append("\r\n")

        // Attach model
        append(boundaryPrefix)
        append("Content-Disposition: form-data; name=\"model\"\r\n\r\n")
        append("gpt-4o-transcribe\r\n")

        // End boundary
        append("--\(boundary)--\r\n")

        return body
    }
    
    // Fetch Embeddings
    func fetchEmbeddings(for inputText: String) async throws -> EmbeddingsResponse {
        
        let maxAttempts = 3
        var attempts = 0
        var lastError: Error?
        
        debugLog("Fetching Embeddings for: \(inputText)")
        
        while attempts < maxAttempts {
            do {
                guard let url = URL(string: "https://api.openai.com/v1/embeddings"),
                      let apiKey = self.apiKey else {
                    throw AppNetworkError.invalidOpenAiURL
                }
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                
                let requestBody: [String: Any] = [
                    "input": inputText,
                    "model": "text-embedding-3-large",
                ]
                
                let jsonData = try JSONSerialization.data(withJSONObject: requestBody, options: [])
                request.httpBody = jsonData
                
                debugLog("Fetching Embeddings jsonData")
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                debugLog("Fetching Embeddings URLSession")
                
                let httpresponse = response as? HTTPURLResponse
                let code = httpresponse?.statusCode
                
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    
                    debugLog("http Response Code \(String(describing: code))!!")
                    
                    throw AppNetworkError.invalidResponse
                }
                debugLog("Fetching Embeddings Before decoder")
                
                
                let decoder = JSONDecoder()
                
                debugLog("Fetching Embeddings Will decode")
                
                let embeddingsResponse = try decoder.decode(EmbeddingsResponse.self, from: data)

                return embeddingsResponse
            } catch {
                lastError = error
                attempts += 1
                if attempts < maxAttempts {
                    try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
                }
            }
        }
#if DEBUG
        let error = lastError as? AppNetworkError
        let msg = error?.errorDescription
        debugLog("Fetching Embeddings last Error: \(String(describing: msg))")
#endif
        
        throw lastError ?? AppNetworkError.unknownError("An unknown error occurred during embeddings fetch.")
    }
    
    /// Get GPT Response after question
    func getGptResponse(vectorResponses: [Match], question: String) async throws -> String {
        let maxAttempts = 2
        var attempts = 0
        var lastError: Error?
        
        while attempts < maxAttempts {
            do {
                guard let url = URL(string: "https://api.openai.com/v1/chat/completions"),
                      let apiKey = self.apiKey else {
                    throw AppNetworkError.invalidOpenAiURL
                }
                
                let prompt = getGptPrompt(matches: vectorResponses, question: question)
                
                let requestBody: [String: Any] = [
                    "model": "gpt-4o",
                    "temperature": 0.2,
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
                    throw AppNetworkError.noChoicesInResponse
                }
                
                // Update token usage
//                updateTokenUsage(api: APIs.openAI, tokensUsed: gptResponse.usage.totalTokens, read: false)
                
                return firstChoice.message.content
            } catch {
                lastError = error
                attempts += 1
                if attempts < maxAttempts {
                    try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
                }
            }
        }
        
        throw lastError ?? AppNetworkError.unknownError("An unknown error occurred during GPT response fetch.")
    }
    
    private func prepareTopMatches(matches: [Match], minScore: Double = 0.75, maxCount: Int = 2) -> [Match] {
        return matches
            .filter { $0.score >= minScore }
            .sorted { $0.score > $1.score }
            .prefix(maxCount)
            .map { $0 }
    }
    
    private func getGptPrompt(matches: [Match], question: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.timeZone = TimeZone.current
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let isoDateString = isoFormatter.string(from: Date())
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMMM d, yyyy"
        let readableDateString = dateFormatter.string(from: Date())
        
        let topMatches = prepareTopMatches(matches: matches)

            // Format matches for the prompt
            let formattedMatches = topMatches.map { match in
                """
                - Description: \(match.metadata?["description"] ?? "N/A")
                - Timestamp: \(match.metadata?["timestamp"] ?? "N/A")
                """
            }
            
        let numberOfMatches = topMatches.count
        let hasMatches = !topMatches.isEmpty
        let formattedMatchesString = formattedMatches.joined(separator: "\n\n")

            return """
    You are an AI assistant. Use the information retrieved from a vector database to answer the user's question.

    Inputs:
    - User's Question: \(question)
    \(hasMatches ? "- Retrieved Information (\(numberOfMatches) match\(numberOfMatches == 1 ? "" : "es")):\nThe following information was found:\n\n\(formattedMatchesString)" : "")

    Instructions:
    - If the retrieved information is relevant, use it in your reply.
    - If not relevant, answer from general knowledge. Optionally suggest that providing more specific information can improve future answers.
    - Be clear, concise, and helpful.
    - Avoid unnecessary details or mentioning the database.
    - Today is \(readableDateString). Current ISO 8601 time: \(isoDateString) (use only if helpful).
    - Respond using the same language detected in the user's question.
    - If multiple languages are detected, use the dominant one.
    - Never switch languages inside your reply.

    Output:
    A natural, complete, and helpful answer to the user's question.
    """
    }
    
    
    
    
    /// Ask GPT to classify the provided transcript into: is_question, is_reminder, or is_calendar.
    /// - If it's a question, `getGptResponse()` should be used for the reply.
    /// - If it's calendar-related, EventKit should be used.
    /// - If it should be added to the calendar, `EKEvent` should be used.
    func analyzeTranscript(transcript: String) async throws -> IntentClassificationResponse {
        let maxAttempts = 2
        var attempts = 0
        var lastError: Error?
        
        while attempts < maxAttempts {
            do {
                guard let url = URL(string: "https://api.openai.com/v1/chat/completions"),
                      let apiKey = self.apiKey else {
                    throw AppNetworkError.invalidOpenAiURL
                }
                
                let prompt = getGptPromptForTranscript()
                
                let requestBody: [String: Any] = [
                    "model": "gpt-4o",
                    "temperature": 0.1,
                    "messages": [
                        ["role": "system", "content": prompt],
                        ["role": "user", "content": transcript] // Include the transcript for classification
                    ]
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

                // Log full response in DEBUG mode
                #if DEBUG
                if let jsonString = String(data: data, encoding: .utf8) {
                    debugLog("📝 Raw JSON Response from OpenAI:\n\(jsonString)")
                } else {
                    debugLog("❌ Failed to convert API response to string")
                }
                #endif
                
                // Step 1: Decode OpenAIResponse to get "message.content"
                let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
                
                // Step 2: Extract JSON from OpenAI's message.content
                guard let rawJSON = openAIResponse.choices.first?.message.extractedJSON else {
                    throw AppNetworkError.unknownError("No valid JSON found in OpenAI response")
                }
                
                debugLog("📝 Extracted JSON from OpenAI:\n\(rawJSON)")
                
                // Step 3: Decode the extracted JSON into IntentClassificationResponse
                let jsonData = rawJSON.data(using: .utf8)!
                let gptResponse = try JSONDecoder().decode(IntentClassificationResponse.self, from: jsonData)
                
                // Ensure response contains a valid intent type
                guard gptResponse.type != .unknown else {
                    throw AppNetworkError.unknownError("GPT response is unknown.")
                }
                
                return gptResponse
            } catch {
                lastError = error
                attempts += 1
                if attempts < maxAttempts {
                    try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay before retrying
                }
            }
        }
        
        throw lastError ?? AppNetworkError.unknownError("An unknown error occurred during GPT transcript type fetch.")
    }
    
    
    ///Get the actual prompt for asking the gpt to check the type of question user asked.
    private func getGptPromptForTranscript() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.formatOptions = [.withInternetDateTime]
        let isoDateString = formatter.string(from: Date())

            return """
You are an AI assistant that classifies user intent based on transcribed voice input.
Analyze the text and determine its purpose. The possible types are:

- "is_question": The user is asking a general question.
- "is_reminder": The user wants to create a reminder.
- "is_calendar": The user wants to add an event to their calendar.
- "save_info": The user is stating a fact or detail they want to remember later.

---

### For each type, extract structured data:

#### If **"is_question"**, return:
- `"query"`: The user’s question, as plain text.

#### If **"is_reminder"**, return:
- `"task"`: A short description of what the reminder is about.
- `"datetime"`: A specific due date/time in **ISO 8601 format**, in the user's **local time**.  
  Do **not** use `"Z"` or convert to UTC unless the user explicitly says so.

#### If **"is_calendar"**, return:
- `"title"`: The event title.
- `"datetime"`: The event time in **ISO 8601 format**, using the user's **local time**.
- `"location"`: The location as plain text, or `null` if not mentioned.

#### If **"save_info"**, return:
- `"memory"`: The statement or fact the user wants to save (e.g. “My Wi-Fi password is potato123”).

---

### Handling vague or natural language times:

Convert phrases like “tonight”, “tomorrow”, or “in 10 minutes” into **specific ISO 8601 datetime** using common-sense assumptions and the user’s **current time zone**.

Examples:
- "later" → ~2 hours from now
- "tonight" → today at 20:00
- "tomorrow" → same time next day
- "next week" → same time, 7 days later

Current time (local timezone): `\(isoDateString)`

---

### Output Rules (very important):
1. Return only **raw JSON**, with no explanation or markdown.
2. Fields that do not apply must be set to **`null`**.
3. Use this exact structure:

```json
{
  "type": "is_question" | "is_reminder" | "is_calendar" | "save_info",
  "query": "string or null",
  "task": "string or null",
  "datetime": "ISO 8601 string or null",
  "title": "string or null",
  "location": "string or null",
  "memory": "string or null"
}
"""
    }
}
