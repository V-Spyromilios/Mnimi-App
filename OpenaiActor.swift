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
    case unknown(Error)
    
    var localizedDescription: String {
        switch self {
        case .embeddingsFailed(let error):
            return "Embeddings Request Failed: \(error.localizedDescription)"
        case .gptResponseFailed(let error):
            return "GPT Response Failed: \(error.localizedDescription)"
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
#if DEBUG
        print("OpenAI Actor Initialized with apiKey: \(String(describing: apiKey))")
#endif
    }
    
    // MARK: - Methods
    
    // Fetch Embeddings
    func fetchEmbeddings(for inputText: String) async throws -> EmbeddingsResponse {

            let maxAttempts = 3
            var attempts = 0
            var lastError: Error?
#if DEBUG
            print("Fetching Embeddings for: \(inputText)")
#endif
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
#if DEBUG
                    print("Fetching Embeddings jsonData")
#endif
                    
                    let (data, response) = try await URLSession.shared.data(for: request)
                    
#if DEBUG
                    print("Fetching Embeddings URLSession")
#endif
                    
                    let httpresponse = response as? HTTPURLResponse
                    let code = httpresponse?.statusCode
                    
                    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
#if DEBUG
                        print("http Response Code \(String(describing: code))!!")
#endif
                        throw AppNetworkError.invalidResponse
                    }
#if DEBUG
                    print("Fetching Embeddings Before decoder")
#endif
                    
                    let decoder = JSONDecoder()
#if DEBUG
                    print("Fetching Embeddings Will decode")
#endif
                    let embeddingsResponse = try decoder.decode(EmbeddingsResponse.self, from: data)
                    
                    // Update token usage
                    updateTokenUsage(api: APIs.openAI, tokensUsed: embeddingsResponse.usage.totalTokens, read: false)
                    
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
    
    // Get GPT Response
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
                updateTokenUsage(api: APIs.openAI, tokensUsed: gptResponse.usage.totalTokens, read: false)
                
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
    Είστε ένας βοηθός τεχνητής νοημοσύνης με αποστολή να απαντήσετε στην ερώτηση του χρήστη βασιζόμενοι σε πληροφορίες που ανακτήθηκαν από μια βάση δεδομένων διανυσμάτων. Παρακάτω βρίσκονται η ερώτηση του χρήστη και δύο πληροφορίες που θεωρούνται οι πιο σχετικές βάσει της ομοιότητας ενσωμάτωσης. Σημειώστε ότι αυτές οι πληροφορίες ενδέχεται να μην είναι απαραίτητα άμεσα σχετικές με την ερώτηση του χρήστη.
    
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
    
}
