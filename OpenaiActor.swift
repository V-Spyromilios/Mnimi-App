//
//  OpenaiActor.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 31.10.24.
//

import Foundation


enum OpenAIError: Error, Identifiable {
    var id: String { localizedDescription }
    
    case embeddingsFailed(Error)
    case gptResponseFailed(Error)
    case transriptionFailed(Error)
    case reminderError(Error)
    case unknown(Error)
    
    var localizedDescription: String {
        switch self {
        case .embeddingsFailed(let error):
            return "Embeddings Request Error: \(error.localizedDescription)"
        case .gptResponseFailed(let error):
            return "GPT Response Failed: \(error.localizedDescription)"
        case .transriptionFailed(let error):
            return "Audio Transcription Error: \(error.localizedDescription)"
        case .reminderError(let error):
            return "Reminder Error: \(error.localizedDescription)"
        case .unknown(let error):
            return "An unknown error occurred: \(error.localizedDescription)"
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
    func transcribeAudio(fileURL: URL, selectedLanguage: String) async throws -> WhisperResponse {
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
                
                let formData = try createMultipartFormData(fileURL: fileURL, boundary: boundary, selectedLanguage: selectedLanguage)
                
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
    private func createMultipartFormData(fileURL: URL, boundary: String, selectedLanguage: String) throws -> Data {
        var body = Data()
        
        let boundaryPrefix = "--\(boundary)\r\n"
        body.append(boundaryPrefix.data(using: .utf8)!)
        
        let fileData = try Data(contentsOf: fileURL)
        let filename = fileURL.lastPathComponent
        let mimeType = "audio/m4a" // Change if needed
        
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add model part
        body.append(boundaryPrefix.data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("gpt-4o-transcribe\r\n".data(using: .utf8)!)
        
        body.append(boundaryPrefix.data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(selectedLanguage)\r\n".data(using: .utf8)!)
        
        // End boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
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
        print("Fetching Embeddings last Error: \(String(describing: msg))")
#endif
        
        throw lastError ?? AppNetworkError.unknownError("An unknown error occurred during embeddings fetch.")
    }
    
    /// Get GPT Response after question
    func getGptResponse(vectorResponses: [Match], question: String, selectedLanguage: LanguageCode) async throws -> String {
        let maxAttempts = 2
        var attempts = 0
        var lastError: Error?
        
        while attempts < maxAttempts {
            do {
                guard let url = URL(string: "https://api.openai.com/v1/chat/completions"),
                      let apiKey = self.apiKey else {
                    throw AppNetworkError.invalidOpenAiURL
                }
                
                let prompt = getGptPrompt(matches: vectorResponses, question: question, selectedLanguage: selectedLanguage)
                
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
    
    private func getGptPrompt(matches: [Match], question: String, selectedLanguage: LanguageCode) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.timeZone = TimeZone.current
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let isoDateString = isoFormatter.string(from: Date())
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMMM d, yyyy"
        let readableDateString = dateFormatter.string(from: Date())
        
        // Format matches for the prompt
        let formattedMatches = matches.map { match in
            """
            - Score: \(match.score) (higher values indicate greater relevance)
            - Description: \(match.metadata?["description"] ?? "N/A")
            - Timestamp: \(match.metadata?["timestamp"] ?? "N/A")
            """
        }
        
        let formattedMatchesString = formattedMatches.joined(separator: "\n\n")
        switch selectedLanguage {
        case .english:
            return """
    You are an AI assistant tasked with answering the user's question based on information retrieved from a vector database. Below is the user's question and two pieces of information retrieved as the most relevant matches based on embedding similarity. Note that these matches may not necessarily be directly relevant to the user's question.
    
    - User's Question: \(question)
    
    - Relevant Information:
    \(formattedMatchesString)
    
    Your task:
    1. Evaluate the relevance of the provided information to the user's question.
       - If the information is relevant, integrate it into your response to create a helpful and accurate reply.
       - If the information is not relevant, rely on your general knowledge to answer the question effectively, and suggest that the user provide additional or more specific data to improve future responses.
    2. Always aim to provide a response that is clear, concise, and helpful to the user.
    
    Additional Context:
    - If relevant for your reply, today is \(readableDateString), and the current ISO8601 time is \(isoDateString).
    - The response should avoid unnecessary details and focus on addressing the user's query.
    """
        case .german:
            return """
    Sie sind ein KI-Assistent, der damit beauftragt ist, die Frage des Nutzers basierend auf Informationen aus einer Vektordatenbank zu beantworten. Unten finden Sie die Frage des Nutzers und zwei Informationen, die auf Grundlage der Ähnlichkeit der Embeddings als am relevantesten angesehen wurden. Beachten Sie, dass diese Informationen möglicherweise nicht direkt mit der Frage des Nutzers zusammenhängen.
    
    - Frage des Nutzers: \(question)
    
    - Relevante Informationen:
    \(formattedMatchesString)
    
    Ihre Aufgabe:
    1. Bewerten Sie die Relevanz der bereitgestellten Informationen in Bezug auf die Frage des Nutzers.
       - Wenn die Informationen relevant sind, integrieren Sie sie in Ihre Antwort, um eine hilfreiche und genaue Antwort zu erstellen.
       - Wenn die Informationen nicht relevant sind, nutzen Sie Ihr Allgemeinwissen, um die Frage effektiv zu beantworten, und schlagen Sie dem Nutzer vor, zusätzliche oder spezifischere Daten bereitzustellen, um zukünftige Antworten zu verbessern.
    2. Stellen Sie sicher, dass Ihre Antwort klar, prägnant und hilfreich für den Nutzer ist.
    
    Zusätzlicher Kontext:
    - Wenn es für Ihre Antwort relevant ist: Heute ist der \(readableDateString), und die aktuelle Zeit im ISO8601-Format lautet \(isoDateString).
    - Die Antwort sollte unnötige Details vermeiden und sich auf die Frage des Nutzers konzentrieren.
    """
        case .spanish:
            return """
    Eres un asistente de IA encargado de responder a la pregunta del usuario basándote en información recuperada de una base de datos vectorial. A continuación, se muestra la pregunta del usuario y dos piezas de información consideradas como las más relevantes según la similitud de los embeddings. Ten en cuenta que esta información puede no estar directamente relacionada con la pregunta del usuario.
    
    - Pregunta del usuario: \(question)
    
    - Información relevante:
    \(formattedMatchesString)
    
    Tu tarea:
    1. Evalúa la relevancia de la información proporcionada con respecto a la pregunta del usuario.
       - Si la información es relevante, intégrala en tu respuesta para crear una respuesta útil y precisa.
       - Si la información no es relevante, utiliza tus conocimientos generales para responder de manera efectiva y sugiere al usuario proporcionar datos adicionales o más específicos para mejorar las respuestas futuras.
    2. Siempre busca proporcionar una respuesta clara, concisa y útil para el usuario.
    
    Contexto adicional:
    - Si es relevante para tu respuesta, hoy es \(readableDateString) y la hora actual en formato ISO8601 es \(isoDateString).
    - La respuesta debe evitar detalles innecesarios y centrarse en abordar la pregunta del usuario.        
    """
        case .french:
            return """
    Vous êtes un assistant IA chargé de répondre à la question de l'utilisateur en vous basant sur les informations récupérées depuis une base de données vectorielle. Ci-dessous se trouvent la question de l'utilisateur et deux informations considérées comme les plus pertinentes sur la base de leur similarité d'embedding. Notez que ces informations peuvent ne pas être directement liées à la question de l'utilisateur.
    
    - Question de l'utilisateur : \(question)
    
    - Informations pertinentes :
    \(formattedMatchesString)
    
    Votre tâche :
    1. Évaluez la pertinence des informations fournies par rapport à la question de l'utilisateur.
       - Si les informations sont pertinentes, intégrez-les dans votre réponse pour créer une réponse utile et précise.
       - Si les informations ne sont pas pertinentes, basez-vous sur vos connaissances générales pour répondre efficacement à la question et suggérez à l'utilisateur de fournir des données supplémentaires ou plus spécifiques pour améliorer les réponses futures.
    2. Cherchez toujours à fournir une réponse claire, concise et utile à l'utilisateur.
    
    Contexte supplémentaire :
    - Si cela est pertinent pour votre réponse, aujourd'hui nous sommes le \(readableDateString), et l'heure actuelle au format ISO8601 est \(isoDateString).
    - La réponse doit éviter les détails inutiles et se concentrer sur la question de l'utilisateur.
    """
        case .greek:
            return """
    Είστε ένας βοηθός τεχνητής νοημοσύνης με αποστολή να απαντήσετε στην ερώτηση του χρήστη βασιζόμενος σε πληροφορίες που ανακτήθηκαν από μια βάση δεδομένων διανυσμάτων. Παρακάτω βρίσκονται η ερώτηση του χρήστη και δύο πληροφορίες που θεωρούνται οι πιο σχετικές βάσει της ομοιότητας ενσωμάτωσης. Σημειώστε ότι αυτές οι πληροφορίες ενδέχεται να μην είναι απαραίτητα άμεσα σχετικές με την ερώτηση του χρήστη.
    
    - Ερώτηση του χρήστη: \(question)
    
    - Σχετικές πληροφορίες:
    \(formattedMatchesString)
    
    Η αποστολή σας:
    1. Αξιολογήστε τη συνάφεια των παρεχόμενων πληροφοριών σε σχέση με την ερώτηση του χρήστη.
       - Εάν οι πληροφορίες είναι σχετικές, ενσωματώστε τις στην απάντησή σας για να δημιουργήσετε μια χρήσιμη και ακριβή απάντηση.
       - Εάν οι πληροφορίες δεν είναι σχετικές, βασιστείτε στις γενικές σας γνώσεις για να απαντήσετε αποτελεσματικά και προτείνετε στον χρήστη να παρέχει περισσότερα ή πιο συγκεκριμένα δεδομένα για τη βελτίωση των μελλοντικών απαντήσεων.
    2. Στοχεύστε πάντα στο να παρέχετε μια απάντηση που είναι σαφής, συνοπτική και χρήσιμη για τον χρήστη.
    
    Επιπλέον Πλαίσιο:
    - Εάν είναι σχετικό για την απάντησή σας, σήμερα είναι \(readableDateString), και η τρέχουσα ώρα σε μορφή ISO8601 είναι \(isoDateString).
    - Η απάντηση θα πρέπει να αποφεύγει περιττές λεπτομέρειες και να επικεντρώνεται στην ερώτηση του χρήστη.
    """
        case .hebrew:
            return """
    אתה עוזר בינה מלאכותית שתפקידו לענות על שאלת המשתמש בהתבסס על מידע שנאסף ממאגר וקטורים. להלן השאלה של המשתמש ושתי פיסות מידע שנבחרו כהכי רלוונטיות על בסיס דמיון של וקטורים. שים לב שהמידע הזה לא בהכרח רלוונטי באופן ישיר לשאלת המשתמש.
    
    - שאלת המשתמש: \(question)
    
    - מידע רלוונטי:
    \(formattedMatchesString)
    
    המשימה שלך:
    1. הערך את מידת הרלוונטיות של המידע שניתן ביחס לשאלת המשתמש.
       - אם המידע רלוונטי, שילב אותו בתשובתך כדי ליצור מענה מועיל ומדויק.
       - אם המידע לא רלוונטי, הסתמך על הידע הכללי שלך כדי לענות ביעילות והצע למשתמש לספק מידע נוסף או מדויק יותר כדי לשפר את התשובות העתידיות.
    2. שאף תמיד לספק תשובה ברורה, קצרה ומועילה למשתמש.
    
    הקשר נוסף:
    - אם רלוונטי לתשובתך, היום הוא \(readableDateString), והשעה הנוכחית בפורמט ISO8601 היא \(isoDateString).
    - התשובה צריכה להימנע מפרטים מיותרים ולהתמקד בשאלת המשתמש.
    """
        case .italian:
            return """
    Sei un assistente AI incaricato di rispondere alla domanda dell'utente basandoti su informazioni recuperate da un database vettoriale. Di seguito trovi la domanda dell'utente e due informazioni considerate le più rilevanti in base alla somiglianza degli embeddings. Nota che queste informazioni potrebbero non essere direttamente rilevanti alla domanda dell'utente.
    
    - Domanda dell'utente: \(question)
    
    - Informazioni rilevanti:
    \(formattedMatchesString)
    
    Il tuo compito:
    1. Valuta la rilevanza delle informazioni fornite rispetto alla domanda dell'utente.
       - Se le informazioni sono rilevanti, integrale nella tua risposta per fornire una risposta utile e precisa.
       - Se le informazioni non sono rilevanti, basati sulle tue conoscenze generali per rispondere in modo efficace e suggerisci all'utente di fornire dati aggiuntivi o più specifici per migliorare le risposte future.
    2. Cerca sempre di fornire una risposta chiara, concisa e utile per l'utente.
    
    Contesto aggiuntivo:
    - Se rilevante per la tua risposta, oggi è \(readableDateString), e l'orario attuale in formato ISO8601 è \(isoDateString).
    - La risposta dovrebbe evitare dettagli inutili e concentrarsi sulla domanda dell'utente.
    """
        case .japanese:
            return """
    あなたはAIアシスタントとして、ベクトルデータベースから取得した情報をもとにユーザーの質問に回答する役割を担っています。以下は、ユーザーの質問と、埋め込み類似性に基づいて最も関連性が高いとされる2つの情報です。ただし、これらの情報がユーザーの質問に直接関連しているとは限りません。
    
    - ユーザーの質問: \(question)
    
    - 関連情報:
    \(formattedMatchesString)
    
    あなたのタスク:
    1. 提供された情報がユーザーの質問にどれだけ関連しているかを評価します。
       - 情報が関連している場合、それを回答に統合し、有益で正確な返答を作成します。
       - 情報が関連していない場合、一般的な知識に基づいて効果的に回答し、ユーザーにより具体的なデータを提供するよう提案してください。
    2. 常に明確で簡潔かつ有益な回答を提供するよう心がけてください。
    
    追加情報:
    - 回答に関連する場合、本日は \(readableDateString) で、現在のISO8601形式の時間は \(isoDateString) です。
    - 回答は不要な詳細を避け、ユーザーの質問に焦点を当てる必要があります。
    """
        case .korean:
            return """
    당신은 벡터 데이터베이스에서 검색된 정보를 바탕으로 사용자의 질문에 답변하는 역할을 하는 AI 어시스턴트입니다. 아래는 사용자의 질문과 임베딩 유사성을 기준으로 가장 관련성이 높은 두 개의 정보입니다. 이 정보가 반드시 사용자의 질문과 직접 관련이 있는 것은 아닐 수 있습니다.
    
    - 사용자의 질문: \(question)
    
    - 관련 정보:
    \(formattedMatchesString)
    
    당신의 임무:
    1. 제공된 정보가 사용자의 질문과 얼마나 관련이 있는지 평가하십시오.
       - 정보가 관련이 있다면, 이를 답변에 통합하여 유용하고 정확한 답변을 작성하십시오.
       - 정보가 관련이 없다면, 일반적인 지식을 바탕으로 효과적으로 답변하고, 사용자가 더 많은 또는 더 구체적인 데이터를 제공하여 향후 응답을 개선할 수 있도록 제안하십시오.
    2. 항상 명확하고 간결하며 사용자에게 유용한 답변을 제공하도록 노력하십시오.
    
    추가 정보:
    - 답변에 유용하다면, 오늘은 \(readableDateString)이며 현재 ISO8601 형식의 시간은 \(isoDateString)입니다.
    - 답변은 불필요한 세부 정보를 피하고 사용자의 질문에 집중해야 합니다.
    """
        case .portuguese:
            return """
    Você é um assistente de IA encarregado de responder à pergunta do usuário com base em informações recuperadas de um banco de dados vetorial. Abaixo está a pergunta do usuário e duas informações consideradas como as mais relevantes com base na similaridade dos embeddings. Observe que essas informações podem não ser diretamente relevantes à pergunta do usuário.
    
    - Pergunta do usuário: \(question)
    
    - Informações relevantes:
    \(formattedMatchesString)
    
    Sua tarefa:
    1. Avalie a relevância das informações fornecidas em relação à pergunta do usuário.
       - Se as informações forem relevantes, integre-as à sua resposta para criar um retorno útil e preciso.
       - Se as informações não forem relevantes, baseie-se no seu conhecimento geral para responder de forma eficaz e sugira ao usuário fornecer dados adicionais ou mais específicos para melhorar respostas futuras.
    2. Sempre busque fornecer uma resposta clara, concisa e útil ao usuário.
    
    Contexto adicional:
    - Se relevante para sua resposta, hoje é \(readableDateString), e o horário atual no formato ISO8601 é \(isoDateString).
    - A resposta deve evitar detalhes desnecessários e focar em abordar a pergunta do usuário.
    """
        case .chineseSimplified:
            return """
您是一名人工智能助手，任务是根据从向量数据库中检索到的信息回答用户的问题。以下是用户的问题以及根据嵌入相似性检索到的两条最相关的信息。请注意，这些信息可能不一定与用户的问题直接相关。

- 用户的问题: \(question)

- 相关信息:
\(formattedMatchesString)

您的任务:
1. 评估提供的信息与用户问题的相关性。
   - 如果信息相关，请将其整合到您的回复中，以创建一个有帮助且准确的回答。
   - 如果信息无关，请依靠您的一般知识有效地回答问题，并建议用户提供更多或更具体的数据以改进未来的回复。
2. 始终旨在提供清晰、简洁且对用户有帮助的回复。

附加上下文:
- 如果对您的回答有帮助，今天是 \(readableDateString)，当前的 ISO8601 时间是 \(isoDateString)。
- 回复应避免不必要的细节，并专注于解决用户的问题。
"""
        }
    }
    
    
    
    
    /// Ask GPT to classify the provided transcript into: is_question, is_reminder, or is_calendar.
    /// - If it's a question, `getGptResponse()` should be used for the reply.
    /// - If it's calendar-related, EventKit should be used.
    /// - If it should be added to the calendar, `EKEvent` should be used.
    func analyzeTranscript(transcript: String, selectedLanguage: LanguageCode) async throws -> IntentClassificationResponse {
        let maxAttempts = 2
        var attempts = 0
        var lastError: Error?
        
        while attempts < maxAttempts {
            do {
                guard let url = URL(string: "https://api.openai.com/v1/chat/completions"),
                      let apiKey = self.apiKey else {
                    throw AppNetworkError.invalidOpenAiURL
                }
                
                let prompt = getGptPromptForTranscript(selectedLanguage: selectedLanguage)
                
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
                    print("📝 Raw JSON Response from OpenAI:\n\(jsonString)")
                } else {
                    print("❌ Failed to convert API response to string")
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
    private func getGptPromptForTranscript(selectedLanguage: LanguageCode) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.formatOptions = [.withInternetDateTime]
        let isoDateString = formatter.string(from: Date())
        
        switch selectedLanguage {
        case .english:
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
        case .german:
            return
"""
Sie sind ein KI-Assistent, der die Absicht des Benutzers basierend auf transkribierten Spracheingaben klassifiziert.
Analysieren Sie den Text und bestimmen Sie seinen Zweck. Die möglichen Typen sind:
- "is_question": Der Benutzer stellt eine allgemeine Frage.
- "is_reminder": Der Benutzer möchte eine Erinnerung erstellen.
- "is_calendar": Der Benutzer möchte ein Ereignis in seinen Kalender hinzufügen.

### Strukturierte Details für jeden Typ extrahieren:
- Wenn **"is_question"**, geben Sie zurück:
    - `"query"`: Die ursprüngliche Frage des Benutzers.

- Wenn **"is_reminder"**, geben Sie zurück:
    - `"task"`: Eine kurze Beschreibung der Erinnerung.
    - `"datetime"`: Das Fälligkeitsdatum/-uhrzeit im **ISO 8601-Format**, unter Verwendung der **Ortszeit** des Benutzers
      (z. B. `"2024-06-15T09:00:00+02:00"` für Mitteleuropäische Sommerzeit).
      **Nicht** in UTC konvertieren oder `"Z"` verwenden, es sei denn, der Benutzer gibt ausdrücklich „UTC“ oder „GMT“ an.
      Aktuelle Zeit im ISO 8601-Format ist: \(isoDateString)

- Wenn **"is_calendar"**, geben Sie zurück:
    - `"title"`: Der Name des Ereignisses.
    - `"datetime"`: Das Datum/die Uhrzeit des Ereignisses im **ISO 8601-Format**, unter Verwendung der **Ortszeit** des Benutzers.
      Die Zeit muss das widerspiegeln, was der Benutzer beabsichtigt hat (z. B. bedeutet "14:00" 14:00 Ortszeit).
      **Nicht** in UTC konvertieren oder `"Z"` verwenden, es sei denn, der Benutzer gibt ausdrücklich „UTC“ oder „GMT“ an.
      Aktuelle Zeit im ISO 8601-Format ist: \(isoDateString)
    - `"location"`: Der optionale Ort oder `null`, wenn nicht erwähnt.

Wenn der Benutzer vage Zeitangaben wie „später“, „heute Abend“ oder „morgen“ verwendet:
- Konvertieren Sie diese in ein spezifisches Datum/Uhrzeit im ISO 8601-Format, basierend auf gesundem Menschenverstand.
- Gehen Sie davon aus, dass der Benutzer seine aktuelle Zeitzone meint.
- Zum Beispiel:
    - "später" → 2 Stunden ab jetzt
    - "heute Abend" → heute um 20:00 Uhr
    - "morgen" → gleiche Zeit am nächsten Tag
    - "nächste Woche" → gleiche Zeit, 7 Tage später

### Wichtige Formatierungsregeln:
1. Geben Sie **nur reines JSON** zurück, ohne zusätzliche Erklärungen.
2. **Keine** Markdown-Formatierung verwenden (wie ```json).
3. Verwenden Sie diese genaue JSON-Struktur:

{
  "type": "is_question" | "is_reminder" | "is_calendar",
  "query": "string oder null",
  "task": "string oder null",
  "datetime": "ISO 8601 string oder null",
  "title": "string oder null",
  "location": "string oder null"
}
"""
        case .spanish:
            return
"""
Eres un asistente de IA que clasifica la intención del usuario basada en la entrada de voz transcrita.
Analiza el texto y determina su propósito. Los tipos posibles son:
- "is_question": El usuario está haciendo una pregunta general.
- "is_reminder": El usuario quiere crear un recordatorio.
- "is_calendar": El usuario quiere agregar un evento a su calendario.

### Extraer detalles estructurados para cada tipo:
- Si es **"is_question"**, devuelve:
    - `"query"`: La pregunta original del usuario.

- Si es **"is_reminder"**, devuelve:
    - `"task"`: Una breve descripción del recordatorio.
    - `"datetime"`: La fecha y hora de vencimiento en **formato ISO 8601**, utilizando la **hora local** del usuario
      (por ejemplo, `"2024-06-15T09:00:00+02:00"` para la hora de verano de Europa Central).
      **No** convertir a UTC ni usar `"Z"` a menos que el usuario lo indique explícitamente como "UTC" o "GMT".
      La hora actual en formato ISO 8601 es: \(isoDateString)

- Si es **"is_calendar"**, devuelve:
    - `"title"`: El nombre del evento.
    - `"datetime"`: La fecha y hora del evento en **formato ISO 8601**, utilizando la **hora local** del usuario.
      La hora debe reflejar lo que el usuario pretendía (por ejemplo, "14:00" significa 14:00 hora local).
      **No** convertir a UTC ni usar `"Z"` a menos que el usuario lo indique explícitamente como "UTC" o "GMT".
      La hora actual en formato ISO 8601 es: \(isoDateString)
    - `"location"`: La ubicación opcional, o `null` si no se menciona.

Si el usuario utiliza expresiones de tiempo vagas como "más tarde", "esta noche" o "mañana":
- Conviértalas a una fecha y hora específica en formato ISO 8601 usando el sentido común.
- Suponga que el usuario se refiere a su zona horaria actual.
- Por ejemplo:
    - "más tarde" → 2 horas a partir de ahora
    - "esta noche" → hoy a las 20:00
    - "mañana" → misma hora al día siguiente
    - "la próxima semana" → misma hora, 7 días después

### Reglas importantes de formato:
1. Devuelve **solo JSON puro**, sin explicaciones adicionales.
2. **No** incluyas formato Markdown (como ```json).
3. Usa esta estructura JSON exacta:

{
  "type": "is_question" | "is_reminder" | "is_calendar",
  "query": "cadena o null",
  "task": "cadena o null",
  "datetime": "cadena ISO 8601 o null",
  "title": "cadena o null",
  "location": "cadena o null"
}
"""
        case .french:
            return
"""
Vous êtes un assistant IA qui classe l’intention de l’utilisateur à partir d’une entrée vocale transcrite.  
Analysez le texte et déterminez son objectif. Les types possibles sont :  
- "is_question" : L’utilisateur pose une question générale.  
- "is_reminder" : L’utilisateur souhaite créer un rappel.  
- "is_calendar" : L’utilisateur souhaite ajouter un événement à son calendrier.

### Détails structurés à extraire pour chaque type :
- Si **"is_question"**, retournez :
    - `"query"` : La question originale de l’utilisateur.

- Si **"is_reminder"**, retournez :
    - `"task"` : Une brève description du rappel.
    - `"datetime"` : La date et l’heure d’échéance au **format ISO 8601**, en utilisant l’**heure locale** de l’utilisateur  
      (par exemple : `"2024-06-15T09:00:00+02:00"` pour l’heure d’été d’Europe centrale).  
      Ne convertissez **pas** en UTC et n’utilisez **pas** `"Z"`, sauf si l’utilisateur mentionne explicitement « UTC » ou « GMT ».  
      Heure actuelle au format ISO 8601 : \(isoDateString)

- Si **"is_calendar"**, retournez :
    - `"title"` : Le nom de l’événement.
    - `"datetime"` : La date et l’heure de l’événement au **format ISO 8601**, en utilisant l’**heure locale** de l’utilisateur.  
      L’heure doit correspondre à ce que l’utilisateur a exprimé (ex. : "14:00" signifie 14:00 heure locale).  
      Ne convertissez **pas** en UTC et n’utilisez **pas** `"Z"`, sauf si l’utilisateur mentionne explicitement « UTC » ou « GMT ».  
      Heure actuelle au format ISO 8601 : \(isoDateString)
    - `"location"` : Le lieu facultatif, ou `null` s’il n’est pas mentionné.

Si l’utilisateur utilise des expressions temporelles vagues comme « plus tard », « ce soir » ou « demain » :
- Convertissez-les en une date/heure précise au format ISO 8601 selon le bon sens.
- Supposons que l’utilisateur parle de son fuseau horaire actuel.
- Par exemple :
    - « plus tard » → dans 2 heures
    - « ce soir » → aujourd’hui à 20h00
    - « demain » → même heure le jour suivant
    - « la semaine prochaine » → même heure, 7 jours plus tard

### Règles importantes de formatage :
1. Retournez **uniquement du JSON brut**, sans aucune explication supplémentaire.  
2. N’utilisez **pas** de mise en forme Markdown (comme ```json).  
3. Utilisez exactement cette structure JSON :

{
  "type": "is_question" | "is_reminder" | "is_calendar",
  "query": "string ou null",
  "task": "string ou null",
  "datetime": "chaîne ISO 8601 ou null",
  "title": "string ou null",
  "location": "string ou null"
}
"""
        case .greek:
            return """
Είσαι ένας βοηθός Τεχνητής Νοημοσύνης που ταξινομεί την πρόθεση του χρήστη με βάση μεταγεγραμμένη φωνητική είσοδο.  
Ανάλυσε το κείμενο και καθόρισε τον σκοπό του. Οι δυνατοί τύποι είναι:  
- "is_question": Ο χρήστης κάνει μια γενική ερώτηση.  
- "is_reminder": Ο χρήστης θέλει να δημιουργήσει μια υπενθύμιση.  
- "is_calendar": Ο χρήστης θέλει να προσθέσει ένα γεγονός στο ημερολόγιό του.

### Εξήγαγε δομημένες λεπτομέρειες για κάθε τύπο:
- Αν είναι **"is_question"**, επιστρέψτε:
    - `"query"`: Η αρχική ερώτηση του χρήστη.

- Αν είναι **"is_reminder"**, επιστρέψτε:
    - `"task"`: Μια σύντομη περιγραφή της υπενθύμισης.
    - `"datetime"`: Η ημερομηνία και ώρα λήξης σε **μορφή ISO 8601**, χρησιμοποιώντας την **τοπική ώρα** του χρήστη  
      (π.χ. `"2024-06-15T09:00:00+03:00"` για θερινή ώρα Ανατολικής Ευρώπης).  
      **Μην** μετατρέπεις την ώρα σε UTC και **μην** χρησιμοποιείς `"Z"`, εκτός αν ο χρήστης δηλώσει ρητά "UTC" ή "GMT".  
      Η τρέχουσα ώρα σε μορφή ISO 8601 είναι: \(isoDateString)

- Αν είναι **"is_calendar"**, επιστρέψτε:
    - `"title"`: Το όνομα του γεγονότος.
    - `"datetime"`: Η ημερομηνία και ώρα του γεγονότος σε **μορφή ISO 8601**, χρησιμοποιώντας την **τοπική ώρα** του χρήστη.  
      Η ώρα πρέπει να αντιπροσωπεύει αυτό που εννοεί ο χρήστης (π.χ. "14:00" σημαίνει 14:00 τοπική ώρα).  
      **Μην** μετατρέπεις την ώρα σε UTC και **μην** χρησιμοποιείς `"Z"`, εκτός αν ο χρήστης δηλώσει ρητά "UTC" ή "GMT".  
      Η τρέχουσα ώρα σε μορφή ISO 8601 είναι: \(isoDateString)
    - `"location"`: Η προαιρετική τοποθεσία ή `null` αν δεν αναφέρεται.

Αν ο χρήστης χρησιμοποιεί ασαφείς χρονικές εκφράσεις όπως «αργότερα», «το βράδυ» ή «αύριο»:
- Μετατρέψτε τις σε συγκεκριμένη ημερομηνία/ώρα σε μορφή ISO 8601 με βάση τη λογική.
- Υποθέστε ότι ο χρήστης εννοεί τη δική του ζώνη ώρας.
- Για παράδειγμα:
    - «αργότερα» → σε 2 ώρες από τώρα
    - «το βράδυ» → σήμερα στις 20:00
    - «αύριο» → ίδια ώρα την επόμενη μέρα
    - «την επόμενη εβδομάδα» → ίδια ώρα, 7 μέρες αργότερα

### Σημαντικοί κανόνες μορφοποίησης:
1. Επιστρέψτε **μόνο καθαρό JSON**, χωρίς καμία πρόσθετη εξήγηση.  
2. **Μην** χρησιμοποιείτε μορφοποίηση Markdown (όπως ```json).  
3. Χρησιμοποιήστε ακριβώς αυτή τη δομή JSON:

{
  "type": "is_question" | "is_reminder" | "is_calendar",
  "query": "string ή null",
  "task": "string ή null",
  "datetime": "ISO 8601 string ή null",
  "title": "string ή null",
  "location": "string ή null"
}
"""
        case .hebrew:
            return """
אתה עוזר מבוסס בינה מלאכותית שתפקידו לסווג את כוונת המשתמש על בסיס קלט קולי שתומלל.  
נתח את הטקסט וזיהה את מטרתו. הסוגים האפשריים הם:  
- "is_question": המשתמש שואל שאלה כללית.  
- "is_reminder": המשתמש רוצה ליצור תזכורת.  
- "is_calendar": המשתמש רוצה להוסיף אירוע ליומן שלו.

### הפק פרטים מובנים עבור כל סוג:
- אם **"is_question"**, החזר:
    - `"query"`: השאלה המקורית של המשתמש.

- אם **"is_reminder"**, החזר:
    - `"task"`: תיאור קצר של התזכורת.
    - `"datetime"`: התאריך והשעה בפורמט **ISO 8601**, בהתאם ל**שעה המקומית** של המשתמש  
      (לדוגמה: `"2024-06-15T09:00:00+03:00"` עבור שעון קיץ בישראל).  
      **אין** להמיר לשעת UTC או להשתמש ב־`"Z"` אלא אם המשתמש מציין במפורש "UTC" או "GMT".  
      השעה הנוכחית בפורמט ISO 8601: \(isoDateString)

- אם **"is_calendar"**, החזר:
    - `"title"`: שם האירוע.
    - `"datetime"`: תאריך ושעת האירוע בפורמט **ISO 8601**, לפי השעה המקומית של המשתמש.  
      הזמן צריך לשקף את מה שהמשתמש התכוון אליו (לדוגמה, "14:00" פירושו 14:00 בשעון מקומי).  
      **אין** להמיר ל־UTC או להשתמש ב־`"Z"` אלא אם המשתמש מציין במפורש.  
      השעה הנוכחית בפורמט ISO 8601: \(isoDateString)
    - `"location"`: מיקום אופציונלי, או `null` אם לא צוין.

אם המשתמש משתמש בביטויי זמן כלליים כמו "מאוחר יותר", "הלילה" או "מחר":
- המירו אותם לזמן ותאריך מדויקים בפורמט ISO 8601 על בסיס היגיון בריא.
- הניחו שהמשתמש מתכוון לאזור הזמן המקומי שלו.
- לדוגמה:
    - "מאוחר יותר" → עוד שעתיים מהזמן הנוכחי
    - "הלילה" → היום ב־20:00
    - "מחר" → באותה שעה מחר
    - "שבוע הבא" → באותה שעה בעוד 7 ימים

### כללי עיצוב חשובים:
1. החזר **רק JSON גולמי**, ללא הסברים נוספים.  
2. **אין** להשתמש בסימון Markdown (כמו ```json).  
3. השתמש במבנה JSON הבא בדיוק:

{
  "type": "is_question" | "is_reminder" | "is_calendar",
  "query": "string או null",
  "task": "string או null",
  "datetime": "מחרוזת ISO 8601 או null",
  "title": "string או null",
  "location": "string או null"
}
"""
        case .italian:
            return """
Sei un assistente basato su intelligenza artificiale che classifica l’intento dell’utente in base all’input vocale trascritto.  
Analizza il testo e determina il suo scopo. I tipi possibili sono:  
- "is_question": L’utente sta facendo una domanda generale.  
- "is_reminder": L’utente desidera creare un promemoria.  
- "is_calendar": L’utente desidera aggiungere un evento al proprio calendario.

### Estrai i dettagli strutturati per ciascun tipo:
- Se **"is_question"**, restituisci:
    - `"query"`: La domanda originale dell’utente.

- Se **"is_reminder"**, restituisci:
    - `"task"`: Una breve descrizione del promemoria.
    - `"datetime"`: La data e l’ora di scadenza in **formato ISO 8601**, utilizzando l’**ora locale** dell’utente  
      (ad esempio: `"2024-06-15T09:00:00+02:00"` per l’ora legale dell’Europa centrale).  
      **Non** convertire in UTC e **non** utilizzare `"Z"`, a meno che l’utente non specifichi esplicitamente “UTC” o “GMT”.  
      Ora corrente in formato ISO 8601: \(isoDateString)

- Se **"is_calendar"**, restituisci:
    - `"title"`: Il nome dell’evento.
    - `"datetime"`: La data e l’ora dell’evento in **formato ISO 8601**, utilizzando l’**ora locale** dell’utente.  
      L’orario deve riflettere ciò che l’utente ha inteso (es. "14:00" significa 14:00 ora locale).  
      **Non** convertire in UTC e **non** usare `"Z"` a meno che non venga specificato esplicitamente.  
      Ora corrente in formato ISO 8601: \(isoDateString)
    - `"location"`: La posizione opzionale, o `null` se non menzionata.

Se l’utente usa espressioni temporali vaghe come “più tardi”, “stasera” o “domani”:
- Convertile in una data/ora specifica in formato ISO 8601, utilizzando il buon senso.
- Presumi che l’utente si riferisca al proprio fuso orario locale.
- Esempi:
    - "più tardi" → tra 2 ore
    - "stasera" → oggi alle 20:00
    - "domani" → stessa ora del giorno successivo
    - "la prossima settimana" → stessa ora tra 7 giorni

### Regole importanti di formattazione:
1. Restituisci **solo JSON puro**, senza spiegazioni aggiuntive.  
2. **Non** utilizzare formattazione Markdown (come ```json).  
3. Usa esattamente questa struttura JSON:

{
  "type": "is_question" | "is_reminder" | "is_calendar",
  "query": "stringa o null",
  "task": "stringa o null",
  "datetime": "stringa ISO 8601 o null",
  "title": "stringa o null",
  "location": "stringa o null"
}
"""
        case .japanese:
            return """
あなたは音声入力の文字起こしに基づいてユーザーの意図を分類するAIアシスタントです。  
テキストを分析して、その目的を判断してください。可能なタイプは以下の通りです：  
- "is_question"：ユーザーが一般的な質問をしています。  
- "is_reminder"：ユーザーがリマインダー（通知）を作成したいと考えています。  
- "is_calendar"：ユーザーがカレンダーにイベントを追加したいと考えています。

### 各タイプに対して、以下の構造化された情報を抽出してください：
- **"is_question"** の場合：
    - `"query"`：ユーザーの元の質問。

- **"is_reminder"** の場合：
    - `"task"`：リマインダーの簡潔な説明。
    - `"datetime"`：**ISO 8601形式**での期日・時間。ユーザーの**現地時間**を使用してください。  
      （例："2024-06-15T09:00:00+09:00" は日本標準時）。  
      明示的に「UTC」または「GMT」と言われない限り、**UTCへの変換や "Z" の使用はしないでください**。  
      現在の日時（ISO 8601形式）：\(isoDateString)

- **"is_calendar"** の場合：
    - `"title"`：イベントのタイトル。
    - `"datetime"`：**ISO 8601形式**でのイベントの日時。ユーザーの**現地時間**を使用してください。  
      ユーザーが「14時」と言った場合、それは現地時間の14時である必要があります。  
      明示的に「UTC」または「GMT」と言われない限り、**UTCへの変換や "Z" の使用はしないでください**。  
      現在の日時（ISO 8601形式）：\(isoDateString)
    - `"location"`：場所（任意）。指定されていない場合は `null`。

ユーザーが「あとで」「今夜」「明日」などの曖昧な時間表現を使った場合：
- それらを常識に基づいて明確な日時（ISO 8601形式）に変換してください。
- ユーザーの現在のタイムゾーンを基準にしてください。
- 例：
    - 「あとで」→ 今から2時間後
    - 「今夜」→ 今日の20:00
    - 「明日」→ 翌日の同じ時間
    - 「来週」→ 同じ時間で7日後

### 重要なフォーマットルール：
1. **説明なしで、JSONのみを返してください**。  
2. Markdown形式（例：```json）を**使用しないでください**。  
3. 次のJSON構造を**正確に**使用してください：

{
  "type": "is_question" | "is_reminder" | "is_calendar",
  "query": "string または null",
  "task": "string または null",
  "datetime": "ISO 8601 形式の string または null",
  "title": "string または null",
  "location": "string または null"
}
"""
        case .korean:
            return """
당신은 음성 입력을 텍스트로 변환한 내용을 기반으로 사용자의 의도를 분류하는 인공지능 비서입니다.  
텍스트를 분석하여 그 목적을 판단하세요. 가능한 유형은 다음과 같습니다:  
- "is_question": 사용자가 일반적인 질문을 합니다.  
- "is_reminder": 사용자가 알림(리마인더)을 생성하고자 합니다.  
- "is_calendar": 사용자가 캘린더에 일정을 추가하고자 합니다.

### 각 유형에 대해 다음과 같은 구조화된 정보를 추출하세요:
- **"is_question"**일 경우:
    - `"query"`: 사용자의 원래 질문.

- **"is_reminder"**일 경우:
    - `"task"`: 알림의 간단한 설명.
    - `"datetime"`: **ISO 8601 형식**의 날짜 및 시간이며, 사용자의 **로컬 시간대**를 사용해야 합니다.  
      예: `"2024-06-15T09:00:00+09:00"` (한국 시간).  
      사용자가 명시적으로 "UTC" 또는 "GMT"라고 말하지 않는 한, **UTC로 변환하거나 "Z"를 사용하지 마세요**.  
      현재 시각 (ISO 8601 형식): \(isoDateString)

- **"is_calendar"**일 경우:
    - `"title"`: 일정 제목.
    - `"datetime"`: **ISO 8601 형식**의 일정 날짜 및 시간이며, 사용자의 **로컬 시간**을 사용하세요.  
      예를 들어, 사용자가 "14시"라고 말하면 이는 로컬 시간 기준 14:00을 의미해야 합니다.  
      사용자가 명확히 "UTC" 또는 "GMT"라고 언급하지 않는 이상, **UTC로 변환하거나 "Z"를 사용하지 마세요**.  
      현재 시각 (ISO 8601 형식): \(isoDateString)
    - `"location"`: 선택적인 장소 정보, 언급되지 않았다면 `null`로 표시하세요.

사용자가 “나중에”, “오늘 밤”, “내일” 같은 모호한 시간 표현을 사용한 경우:
- 일반적인 상식에 따라 ISO 8601 형식의 명확한 날짜와 시간으로 변환하세요.
- 사용자의 현재 시간대를 기준으로 가정하세요.
- 예시:
    - "나중에" → 지금부터 2시간 후
    - "오늘 밤" → 오늘 오후 8시
    - "내일" → 다음 날 같은 시간
    - "다음 주" → 같은 시간, 7일 후

### 중요한 형식 규칙:
1. **설명 없이 JSON 데이터만** 반환하세요.  
2. **Markdown 형식** (예: ```json) **사용 금지**.  
3. 다음과 같은 정확한 JSON 구조를 사용하세요:

{
  "type": "is_question" | "is_reminder" | "is_calendar",
  "query": "문자열 또는 null",
  "task": "문자열 또는 null",
  "datetime": "ISO 8601 문자열 또는 null",
  "title": "문자열 또는 null",
  "location": "문자열 또는 null"
}
"""
        case .portuguese:
            return """
Você é um assistente de inteligência artificial que classifica a intenção do usuário com base em entrada de voz transcrita.  
Analise o texto e determine seu propósito. Os tipos possíveis são:  
- "is_question": O usuário está fazendo uma pergunta geral.  
- "is_reminder": O usuário deseja criar um lembrete.  
- "is_calendar": O usuário deseja adicionar um evento ao calendário.

### Extraia os detalhes estruturados para cada tipo:
- Se for **"is_question"**, retorne:
    - `"query"`: A pergunta original do usuário.

- Se for **"is_reminder"**, retorne:
    - `"task"`: Uma breve descrição do lembrete.
    - `"datetime"`: A data e hora no **formato ISO 8601**, usando o **horário local** do usuário  
      (por exemplo: `"2024-06-15T09:00:00-03:00"` para horário de Brasília).  
      **Não** converta para UTC nem use `"Z"`, a menos que o usuário diga explicitamente “UTC” ou “GMT”.  
      Data e hora atual em formato ISO 8601: \(isoDateString)

- Se for **"is_calendar"**, retorne:
    - `"title"`: O nome do evento.
    - `"datetime"`: A data e hora do evento em **formato ISO 8601**, usando o **horário local** do usuário.  
      O horário deve refletir exatamente o que o usuário quis dizer (por exemplo, "14:00" significa 14h no horário local).  
      **Não** converta para UTC nem use `"Z"`, a menos que o usuário diga explicitamente.  
      Data e hora atual em formato ISO 8601: \(isoDateString)
    - `"location"`: O local opcional, ou `null` caso não tenha sido mencionado.

Se o usuário utilizar expressões vagas como “mais tarde”, “hoje à noite” ou “amanhã”:
- Converta para uma data e hora específica em formato ISO 8601, com base no bom senso.
- Assuma que o usuário está se referindo ao próprio fuso horário.
- Exemplos:
    - "mais tarde" → daqui a 2 horas
    - "hoje à noite" → hoje às 20h
    - "amanhã" → mesma hora no dia seguinte
    - "semana que vem" → mesma hora, daqui a 7 dias

### Regras importantes de formatação:
1. Retorne **apenas JSON puro**, sem explicações adicionais.  
2. **Não** use formatação Markdown (como ```json).  
3. Use exatamente esta estrutura JSON:

{
  "type": "is_question" | "is_reminder" | "is_calendar",
  "query": "string ou null",
  "task": "string ou null",
  "datetime": "string no formato ISO 8601 ou null",
  "title": "string ou null",
  "location": "string ou null"
}
"""
        case .chineseSimplified:
            return """
你是一个基于语音转文本的 AI 助手，用于识别用户的意图。  
请分析文本并判断其目的。可能的类型包括：  
- "is_question"：用户在提出一个一般性问题。  
- "is_reminder"：用户希望创建一个提醒事项。  
- "is_calendar"：用户希望将事件添加到日历中。

### 请为每种类型提取结构化信息：
- 如果是 **"is_question"**，请返回：
    - `"query"`：用户的原始问题。

- 如果是 **"is_reminder"**，请返回：
    - `"task"`：提醒事项的简短描述。
    - `"datetime"`：以 **ISO 8601 格式**表示的截止日期和时间，使用用户的**本地时间**  
      例如：`"2024-06-15T09:00:00+08:00"`（中国标准时间）。  
      除非用户明确表示“UTC”或“GMT”，**否则请勿转换为 UTC 或使用 `"Z"`**。  
      当前时间的 ISO 8601 格式为：\(isoDateString)

- 如果是 **"is_calendar"**，请返回：
    - `"title"`：事件名称。
    - `"datetime"`：以 **ISO 8601 格式**表示的事件日期和时间，使用用户的**本地时间**。  
      时间应与用户的实际意图相符（例如，“14:00”表示本地时间下午两点）。  
      除非用户明确表示“UTC”或“GMT”，**否则请勿转换为 UTC 或使用 `"Z"`**。  
      当前时间的 ISO 8601 格式为：\(isoDateString)
    - `"location"`：可选的事件地点，如果未提及则为 `null`。

如果用户使用了模糊的时间表达，例如“稍后”、“今晚”或“明天”：
- 请根据常识将其转换为具体的 ISO 8601 格式的时间。
- 假设用户指的是其当前所在的时区。
- 示例：
    - “稍后” → 当前时间加 2 小时
    - “今晚” → 今天晚上 20:00
    - “明天” → 明天的同一时间
    - “下周” → 7 天后的同一时间

### 重要格式规则：
1. 请只返回**纯 JSON**，不包含任何解释。  
2. **不要**使用 Markdown 格式（如 ```json）。  
3. 请严格使用以下 JSON 结构：

{
  "type": "is_question" | "is_reminder" | "is_calendar",
  "query": "字符串或 null",
  "task": "字符串或 null",
  "datetime": "ISO 8601 格式的字符串或 null",
  "title": "字符串或 null",
  "location": "字符串或 null"
}
"""
        }
    }
}
