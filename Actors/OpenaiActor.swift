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
    case permissionsMissing(Error)

    var id: String { message }

    var title: String {
        switch self {
        case .embeddingsFailed: return "Embeddings Error"
        case .gptResponseFailed: return "GPT Error"
        case .transriptionFailed: return "Transcription Error"
        case .reminderError: return "Reminder Error"
        case .unknown: return "Unexpected Error"
        case .permissionsMissing: return "Check Permissions in Settings"
        }
    }

    var message: String {
        switch self {
        case .embeddingsFailed(let e),
                .gptResponseFailed(let e),
                .transriptionFailed(let e),
                .reminderError(let e),
                .unknown(let e),
                .permissionsMissing(let e):
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

extension OpenAIError {
    static var missingCalendarPermissions: OpenAIError {
        .permissionsMissing(
            NSError(
                domain: "CalendarPermissions",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Access to Calendar was not granted."]
            )
        )
    }
    
    static var missingReminderPermissions: OpenAIError {
        .permissionsMissing(
            NSError(
                domain: "ReminderPermissions",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Access to Reminders was not granted."]
            )
        )
    }
}


/// `OpenAIActor` is responsible for making network requests to OpenAI APIs
/// including Whisper for transcription, and GPT-based endpoints for embeddings and chat responses.
/// It encapsulates all OpenAI-related logic in a thread-safe, async environment.
actor OpenAIActor {

    private let apiKey: String?
    private let requestTimeoutSeconds: Double = 6
    
    // MARK: - Initializer
    init() {
        self.apiKey = ApiConfiguration.openAIKey
    }
    
    // MARK: - Methods

    /// Transcribes audio from a local file using the OpenAI Whisper API.
        ///
        /// - Parameter fileURL: The URL of the audio file to transcribe (e.g., .m4a or .wav).
        /// - Returns: A `WhisperResponse` containing the transcribed text.
        /// - Throws:
        ///   - `AppNetworkError.apiKeyNotFound` if the API key is missing.
        ///   - `AppNetworkError.invalidOpenAiURL` if the Whisper endpoint URL is malformed.
        ///   - `AppNetworkError.invalidResponse` if the server returns a non-200 status.
        ///   - Any decoding or upload error from `URLSession`.
        ///
        /// Includes a retry mechanism (3 attempts with delay) to handle transient failures.
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

                let boundary = UUID().uuidString
                request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
                
                let formData = try createMultipartFormData(fileURL: fileURL, boundary: boundary)
                
                // Swift 6: Improved structured concurrency (async let for request) and timeout check
                let (receivedData, receivedResponse): (Data, URLResponse) = try await withTimeout(seconds: requestTimeoutSeconds) {
                    try await URLSession.shared.upload(for: request, from: formData)
                }

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
    
   
    /// Constructs multipart/form-data body for an audio transcription request to OpenAI Whisper API.
       ///
       /// - Parameters:
       ///   - fileURL: The local file URL of the audio to be uploaded (e.g., .m4a, .wav).
       ///   - boundary: A unique boundary string used to separate parts in the multipart form.
       /// - Returns: A `Data` object representing the full multipart request body.
       /// - Throws: An error if the file data cannot be read from disk.
       ///
       /// Includes:
       /// - The audio file under the `"file"` field.
       /// - The model name (`"gpt-4o-transcribe"`) under the `"model"` field.
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
    
    
    /// Sends a text input to the OpenAI Embeddings API and returns the resulting vector representation.
        ///
        /// - Parameter inputText: The string to embed (e.g., a user query or memory).
        /// - Returns: A decoded `EmbeddingsResponse` containing one or more float vectors.
        /// - Throws: An error if the request fails, the response is invalid, or decoding fails.
        ///
        /// Retries up to 3 times on transient network or decoding errors.
        /// Uses the `text-embedding-3-large` model and application/json payload.
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
                
                let (data, response): (Data, URLResponse) = try await withTimeout(seconds: requestTimeoutSeconds) {
                    try await URLSession.shared.data(for: request)
                }
                
                let httpresponse = response as? HTTPURLResponse
                let code = httpresponse?.statusCode
                
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    
                    debugLog("http Response Code \(String(describing: code))!!")
                    
                    throw AppNetworkError.invalidResponse
                }

                let decoder = JSONDecoder()
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
    


    /// Sends a user's question along with Pinecone-matched context to OpenAI GPT for a conversational answer.
        ///
        /// - Parameters:
        ///   - vectorResponses: A list of `Match` objects retrieved from vector search (e.g., Pinecone).
        ///   - question: The user's original query in plain text.
        /// - Returns: A `String` containing the generated response from GPT.
        /// - Throws: An error if the API call fails or if decoding the response fails.
        ///
        /// Uses the `gpt-4o` model with a low temperature (0.2) and retry logic (2 attempts).
        /// Prepends a system prompt via `getGptPrompt()` to inject relevant memory before querying.
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
                
                let (data, response): (Data, URLResponse) = try await withTimeout(seconds: requestTimeoutSeconds) {
                    try await URLSession.shared.data(for: request)
                }
                
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



    /// Filters and sorts vector search matches by relevance score.
       ///
       /// - Parameters:
       ///   - matches: An array of `Match` results from the vector database.
       ///   - minScore: Minimum score threshold for inclusion (default is 0.3).
       ///   - maxCount: Maximum number of top matches to return (default is 2).
       /// - Returns: An array of the top `Match` objects sorted by descending score.
       ///
       /// Used to reduce noisy or low-confidence results before passing context to GPT.
    private func prepareTopMatches(matches: [Match], minScore: Double = 0.3, maxCount: Int = 2) -> [Match] {
        return matches
            .filter { $0.score >= minScore }
            .sorted { $0.score > $1.score }
            .prefix(maxCount)
            .map { $0 }
    }




    

    /// Constructs a GPT prompt combining user query and top-ranked vector search matches.
        ///
        /// - Parameters:
        ///   - matches: Raw matches from vector similarity search (e.g. Pinecone).
        ///   - question: The user’s natural language question.
        /// - Returns: A formatted prompt string to be used in a GPT chat completion.
        ///
        /// Includes ISO 8601 and human-readable date, embeds top matches if available,
        /// and sets detailed GPT instructions for language consistency and clarity.
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
            let score = String(format: "%.2f", match.score)
            return """
            - Saved info: \(match.metadata?["description"] ?? "N/A")
            - Timestamp: \(match.metadata?["timestamp"] ?? "N/A")
            - Score: \(score)
            """
        }

        let numberOfMatches = topMatches.count
        let hasMatches = !topMatches.isEmpty
        let formattedMatchesString = formattedMatches.joined(separator: "\n\n")

        debugLog("About to form prompt Using \(topMatches.count) match(es) for GPT prompt")
        debugLog("About to form prompt with these matches: \(formattedMatchesString)")
            return """
    You are an AI assistant. Use the information retrieved from a vector database to answer the user's question.

    Inputs:
    - User's Question: \(question)
    """ + (hasMatches ? """

    - Retrieved Information (\(numberOfMatches) match\(numberOfMatches == 1 ? "" : "es")):
    The following information was found:

    \(formattedMatchesString)
    """ : "") + """
    
    Instructions:
    - If the retrieved information is relevant, use it in your reply.
    - Only use retrieved information that clearly and directly relates to the user's question. Do not combine unrelated items.
    - Do not infer or guess details that are not present in the retrieved info. If uncertain, state that the answer is incomplete.
    - If the retrieved info lacks a date or full context, clearly state this in the reply rather than making assumptions.
    - If retrieved info includes relative time expressions (e.g. “in 3 days”, “next week”), interpret them based on the associated timestamp.
    - Use the provided timestamp to resolve when the note was written, and calculate the actual date if possible.
    - If the timestamp is missing or unclear, explain the uncertainty instead of guessing.
    - If the retrieved info is not relevant, answer from general knowledge. Optionally suggest that providing more specific information can improve future answers.
    - Do not add general knowledge unless the retrieved information is clearly insufficient or unrelated.

    - If the user’s question refers to time-based availability (e.g. "Can I go tomorrow morning?"), check if the saved info includes opening hours and compare it to the date/time in question.
    - Interpret "morning" as 06:00 to 12:00, "afternoon" as 12:00 to 18:00, and "evening" as 18:00 to 00:00.
    - Treat relative time phrases ("today", "tomorrow", "yesterday", or weekdays like "Saturday") based on the current date: \(readableDateString). ISO 8601 time is: \(isoDateString) (use only if helpful).
    - For example: If today is Saturday, then "tomorrow" is Sunday.

    - Avoid unnecessary details or mentioning the database.
    - Always respond using the same language detected in the user's question.
    - If multiple languages are detected, use the dominant one.
    - Never switch languages inside your reply.
    - Be clear, concise, and helpful.

    Output:
    A natural, complete, and helpful answer to the user's question.
    """
    }
    
    
    
    
    
    /// Sends transcribed voice input to GPT for intent classification.
    ///
    /// - Parameter transcript: The user’s voice input, already transcribed into plain text.
    /// - Returns: A strongly typed `IntentClassificationResponse` representing the detected intent and extracted metadata.
    ///
    /// Uses a custom prompt to instruct GPT on extracting structured fields.
    /// Retries up to 2 times and ensures extracted JSON is parsed safely.
    /// If classification fails or response is `unknown`, throws an error.
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
                
                let (data, response): (Data, URLResponse) = try await withTimeout(seconds: requestTimeoutSeconds) {
                    try await URLSession.shared.data(for: request)
                }
                
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
                guard let jsonData = rawJSON.data(using: .utf8) else {
                    throw AppNetworkError.unknownError("Failed to encode raw JSON for decoding")
                }
                
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




    /// Builds the prompt for GPT to classify user intent from  input.
    ///
    /// - Returns: A detailed system prompt that defines intent types and extraction rules for GPT.
    ///
    /// Includes instructions to return only raw JSON, in a fixed schema,
    /// with ISO 8601 date parsing for natural language time expressions.
    /// Also provides the current time for grounding vague expressions like "tomorrow".
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
