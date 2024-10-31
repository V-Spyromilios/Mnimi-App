////
////  OpenAIManager.swift
////  Memory
////
////  Created by Evangelos Spyromilios on 14.02.24.
////
//
//import Foundation
//import Combine
//import SwiftUI
//
//final class OpenAIManager: ObservableObject {
//    
//    @MainActor @Published var gptResponse: ChatCompletionResponse? = nil
//    @MainActor @Published var gptMetadataResponse: MetadataResponse? = nil // Contains Type and description to be sent for upserting
//    
//    @MainActor @Published var gptResponseOnQuestion: ChatCompletionResponse? = nil
//    @MainActor @Published var gptMetadataResponseOnQuestion: MetadataResponse? = nil
//    
//    @MainActor @Published var stringResponseOnQuestion: String = ""
//    @MainActor private var languageSettings = LanguageSettings.shared
//    
//    @MainActor @Published var embeddings: [Float] = []
//    @MainActor @Published var embeddingsFromQuestion: [Float] = []
//    
//    @MainActor @Published var questionEmbeddingsCompleted: Bool = false
//    @MainActor @Published var embeddingsCompleted: Bool = false
//    @MainActor @Published var gptResponseForAudioGeneration: String? = nil
//    
//    private lazy var tokensRequired:Int = 0
//    var cancellables = Set<AnyCancellable>()
//    
//    @MainActor
//    init() {
//        
//    }
//    
//    
//    //MARK: clearManager
//    @MainActor
//    func clearManager() async {
//        
//        gptResponse = nil
//        gptMetadataResponse = nil
//        
//        gptResponseOnQuestion = nil
//        gptMetadataResponseOnQuestion = nil
//        
//        embeddings = []
//        embeddingsFromQuestion = []
//        
//        questionEmbeddingsCompleted = false
//        embeddingsCompleted = false
//        gptResponseForAudioGeneration = nil
//        stringResponseOnQuestion = ""
//    }
//    
//    
//    //MARK: requestEmbeddings USED in QuestionView
//    // call with MetadataResponse.description
//    
//    @MainActor
//    func requestEmbeddings(for text: String, isQuestion: Bool) async throws {
//        ProgressTracker.shared.setProgress(to: 0.12)
//        
//        let maxAttempts = 3
//        var attempts = 0
//        var success = false
//        var localResponse: EmbeddingsResponse?
//        var localError: Error?
//        var localTokensRequired: Int = 0
//        
//        // All self accesses are now inside MainActor.run
//        while attempts < maxAttempts && !success {
//            do {
//                localResponse = try await fetchEmbeddings(for: text)
//                success = true
//            } catch {
//                localError = error
//                attempts += 1
//                if attempts < maxAttempts {
//                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
//                }
//            }
//        }
//        
//        if success, let response = localResponse {
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
//                } else {
//                    self.embeddingsCompleted = true
//                }
//                
//                self.tokensRequired = response.usage.totalTokens
//                localTokensRequired = self.tokensRequired // Capture for later use
//            }
//        } else if let localError = localError {
//            throw localError
//        }
//        
//        if isQuestion {
//            await ProgressTracker.shared.setProgress(to: 0.25)
//        } else {
//            await ProgressTracker.shared.setProgress(to: 0.6)
//        }
//        
//        // Using the locally stored tokensRequired outside of MainActor.run
//        updateTokenUsage(api: APIs.openAI, tokensUsed: localTokensRequired, read: false)
//    }
//    
//    
//    // https://api.openai.com/v1/embeddings POST
//    //model: text-embedding-3-large
//    // inputText: description of the gpt-4 response.
//    //MARK: private fetchEmbeddings USED in QuestionView and AddNew
//    private func fetchEmbeddings(for inputText: String) async throws -> EmbeddingsResponse {
//        await ProgressTracker.shared.setProgress(to: 0.15)
//        guard let url = URL(string: "https://api.openai.com/v1/embeddings"),
//              let apiKey = ApiConfiguration.openAIKey else {
//            throw AppNetworkError.invalidOpenAiURL
//        }
//        
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//        
//        let requestBody = [
//            "input": inputText,
//            "model": "text-embedding-3-large",
//            "encoding_format": "float"
//        ]
//        
//        do {
//            let jsonData = try JSONSerialization.data(withJSONObject: requestBody, options: [])
//            request.httpBody = jsonData
//        } catch {
//            throw AppNetworkError.serializationError(error.localizedDescription)
//        }
//        
//        let (data, response) = try await URLSession.shared.data(for: request)
//        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
//            throw AppNetworkError.invalidResponse
//        }
//        await ProgressTracker.shared.setProgress(to: 0.2)
//        
//        let decoder = JSONDecoder()
//        return try decoder.decode(EmbeddingsResponse.self, from: data)
//    }
//    
//    
//    
//    //MARK: USED in QuestionView
//    func getGptResponse(queryMatches: [String], question: String) async throws {
//        
//        await ProgressTracker.shared.setProgress(to: 0.7)
//        guard let apiKey = ApiConfiguration.openAIKey else {
//            throw AppNetworkError.apiKeyNotFound
//        }
//        await ProgressTracker.shared.setProgress(to: 0.75)
//        let gptResponse = try await getGptResponse(apiKey: apiKey, vectorResponses: queryMatches, question: question)
//        await MainActor.run { [weak self] in
//            ProgressTracker.shared.setProgress(to: 0.88)
//            ProgressTracker.shared.setProgress(to: 0.99)
//            self?.stringResponseOnQuestion = gptResponse
//        }
//        
//    }
//    
//    //MARK: USED in QuestionView
//    private func getGptResponse(apiKey: String, vectorResponses: [String], question: String) async throws -> String {
//        await ProgressTracker.shared.setProgress(to: 0.8)
//        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
//            throw AppNetworkError.invalidOpenAiURL
//        }
//        let prompt = await getGptPrompt(vectorResponses: vectorResponses, question: question)
//        
//        let requestBody: [String: Any] = [
//            "model": "gpt-4o", //gpt-4o
//            //            "model": "gpt-4-0125-preview", // gtp-4
//            "temperature": 0,
//            "messages": [["role": "system", "content": prompt]]
//        ]
//        
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//        
//        let maxAttempts = 2
//        var attempts = 0
//        var localError: Error?
//        
//        while attempts < maxAttempts {
//            do {
//                request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
//                await ProgressTracker.shared.setProgress(to: 0.85)
//                let (data, response) = try await URLSession.shared.data(for: request)
//                
//                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
//                    throw AppNetworkError.invalidResponse
//                }
//                
//                let decoder = JSONDecoder()
//                let gptResponse = try decoder.decode(ChatCompletionResponse.self, from: data)
//                guard let firstChoice = gptResponse.choices.first else {
//                    throw AppNetworkError.noChoicesInResponse
//                }
//                updateTokenUsage(api: APIs.openAI, tokensUsed: gptResponse.usage.totalTokens, read: false)
//                return firstChoice.message.content
//                
//            } catch {
//                localError = error
//                attempts += 1
//                if attempts < maxAttempts {
//                    try? await Task.sleep(nanoseconds: 100_000_000)
//                }
//            }
//        }
//        
//        throw localError ?? AppNetworkError.unknownError("An unknown error occurred during GPT response fetch.")
//    }
//    
//    
//    private func getGptPrompt(vectorResponses: [String], question: String)async -> String {
//        
//        let isoFormatter = ISO8601DateFormatter()
//        isoFormatter.timeZone = TimeZone.current
//        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
//        let isoDateString = isoFormatter.string(from: Date()) // Use for precise timestamps
//        
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "EEEE, MMMM d, yyyy"
//        let readableDateString = dateFormatter.string(from: Date())
//        
//        
//        var firstVector: String = ""
//        var secondVector: String = ""
//        
//        if vectorResponses.count == 1 {
//            if !vectorResponses[0].isEmpty {
//                firstVector = vectorResponses[0]
//            }
//        }
//        else if vectorResponses.count == 2 {
//            if !vectorResponses[0].isEmpty {
//                firstVector = vectorResponses[0]
//            }
//            
//            if !vectorResponses[1].isEmpty {
//                secondVector = vectorResponses[1]
//            }
//        }
//        let selectedLanguage = await MainActor.run { languageSettings.selectedLanguage }
//        
//        switch selectedLanguage {
//        case .english:
//            return """
//                   You are an AI assistant, and you have been asked to provide concise reply to user's question. Below is the user's question and one or two pieces of information retrieved by the user's vector database. Note that these pieces of information are the ones with the highest similarity score, but may be irrelevant for user's question:
//                                   
//                       - User's Question: \(question).
//                       - Relevant Information 1: \(firstVector).
//                       - Relevant Information 2: \(secondVector).
//                                   
//                   Using the user's question, and if relevant the information provided, generate a comprehensive, informative, and concise reply that addresses the user's inquiry. Evaluate the relevance of the retrieved information:
//                   - If the retrieved information is relevant, integrate it into your response to provide a helpful response.
//                   - If the retrieved information is not relevant at all, use your general knowledge to provide a helpful response, and suggest that the user provide additional information to the app for more accurate answers in the future.
//                - Always give priority to the relevant information provided by the user to craft an acurate reply.
//                
//                   If relevant for your reply, today is \(readableDateString), and the current time in ISO8601 format is \(isoDateString). Do not return full dates and times unless necessary.
//                
//                   The response should be clear, engaging and concise.
//                """
//        case .spanish:
//            return """
//                Eres un asistente de IA y se te ha pedido que proporciones información concisa sobre un tema específico. A continuación, se presenta la pregunta del usuario y una o dos piezas de información recuperadas por la base de datos vectorial. Ten en cuenta que estas piezas de información son las que tienen la puntuación de similitud más alta, pero pueden no ser relevantes para la pregunta del usuario:
//                
//                                       - Pregunta del usuario: \(question).
//                                       - Información relevante 1: \(firstVector).
//                                       - Información relevante 2: \(secondVector).
//                
//                Usando la pregunta del usuario y, si es relevante, la información proporcionada, genera una respuesta completa, informativa y concisa que responda a la consulta del usuario. Evalúa la relevancia de la información recuperada:
//                                   - Si la información recuperada es relevante, intégrala en tu respuesta para proporcionar una respuesta útil.
//                                   - Si la información recuperada no es relevante o parece ambigua, usa tu conocimiento general para proporcionar una respuesta útil, y resalta cualquier incertidumbre y sugiere que el usuario proporcione información adicional a la aplicación para obtener respuestas más precisas en el futuro.
//                
//                Si es relevante para tu respuesta, hoy es \(readableDateString), y la hora actual en formato ISO8601 es \(isoDateString). No devuelvas fechas y horas completas a menos que sea necesario.
//                
//                La respuesta debe ser clara, atractiva y concisa.
//                """
//        case .french:
//            return """
//                Vous êtes un assistant IA et on vous a demandé de fournir des informations concises sur un sujet spécifique. Voici la question de l'utilisateur et une ou deux pièces d'informations récupérées par la base de données vectorielle. Notez que ces informations sont celles avec le score de similarité le plus élevé, mais peuvent ne pas être pertinentes pour la question de l'utilisateur :
//                
//                                       - Question de l'utilisateur : \(question).
//                                       - Information pertinente 1 : \(firstVector).
//                                       - Information pertinente 2 : \(secondVector).
//                
//                En utilisant la question de l'utilisateur et, si elle est pertinente, les informations fournies, générez une réponse complète, informative et concise qui réponde à la demande de l'utilisateur. Évaluez la pertinence des informations récupérées :
//                                   - Si les informations récupérées sont pertinentes, intégrez-les à votre réponse pour fournir une réponse utile.
//                                   - Si les informations récupérées ne sont pas pertinentes ou semblent ambiguës, utilisez vos connaissances générales pour fournir une réponse utile, mettez en évidence toute incertitude et suggérez à l'utilisateur de fournir des informations supplémentaires à l'application pour obtenir des réponses plus précises à l'avenir.
//                
//                Si cela est pertinent pour votre réponse, aujourd'hui est le \(readableDateString), et l'heure actuelle au format ISO8601 est \(isoDateString). Ne renvoyez pas de dates et heures complètes sauf si nécessaire.
//                
//                La réponse doit être claire, engageante et concise.
//                """
//        case .german:
//            return """
//                Sie sind ein KI-Assistent und wurden gebeten, prägnante Informationen zu einem bestimmten Thema bereitzustellen. Unten finden Sie die Frage des Nutzers und ein oder zwei Informationen, die von der Vektordatenbank abgerufen wurden. Beachten Sie, dass diese Informationen die höchste Ähnlichkeitsbewertung haben, aber möglicherweise nicht relevant für die Frage des Nutzers sind:
//                
//                                       - Frage des Nutzers: \(question).
//                                       - Relevante Information 1: \(firstVector).
//                                       - Relevante Information 2: \(secondVector).
//                
//                Verwenden Sie die Frage des Nutzers und, falls relevant, die bereitgestellten Informationen, um eine umfassende, informative und prägnante Antwort zu generieren, die die Anfrage des Nutzers beantwortet. Bewerten Sie die Relevanz der abgerufenen Informationen:
//                                   - Wenn die abgerufenen Informationen relevant sind, integrieren Sie sie in Ihre Antwort, um eine hilfreiche Antwort zu geben.
//                                   - Wenn die abgerufenen Informationen nicht relevant oder unklar sind, verwenden Sie Ihr Allgemeinwissen, um eine hilfreiche Antwort zu geben, und heben Sie eventuelle Unklarheiten hervor und schlagen Sie vor, dass der Nutzer der App zusätzliche Informationen bereitstellt, um in Zukunft genauere Antworten zu erhalten.
//                
//                Wenn es für Ihre Antwort relevant ist, ist heute der \(readableDateString), und die aktuelle Zeit im ISO8601-Format ist \(isoDateString). Geben Sie vollständige Daten und Zeiten nur dann zurück, wenn dies erforderlich ist.
//                
//                Die Antwort sollte klar, ansprechend und prägnant sein.
//                """
//        case .greek:
//            return """
//              Είστε ένας βοηθός τεχνητής νοημοσύνης και σας ζητήθηκε να παρέχετε συνοπτικές πληροφορίες για ένα συγκεκριμένο θέμα. Παρακάτω είναι η ερώτηση του χρήστη και ένα ή δύο κομμάτια πληροφοριών που ανακτήθηκαν από τη βάση δεδομένων. Σημειώστε ότι αυτά τα κομμάτια πληροφοριών είναι αυτά με την υψηλότερη βαθμολογία ομοιότητας, αλλά μπορεί να είναι άσχετα με την ερώτηση του χρήστη:
//
//                                     - Ερώτηση του χρήστη: \(question).
//                                     - Σχετική Πληροφορία 1: \(firstVector).
//                                     - Σχετική Πληροφορία 2: \(secondVector).
//
//              Χρησιμοποιώντας την ερώτηση του χρήστη και, αν είναι σχετικό, τις παρεχόμενες πληροφορίες, δημιουργήστε μια ολοκληρωμένη, ενημερωτική και συνοπτική απάντηση που να απαντά στην ερώτηση του χρήστη. Αξιολογήστε τη σχετικότητα των ανακτηθέντων πληροφοριών:
//                                 - Αν οι ανακτηθείσες πληροφορίες είναι σχετικές, ενσωματώστε τις στην απάντησή σας για να δώσετε μια χρήσιμη απάντηση.
//                                 - Αν οι ανακτηθείσες πληροφορίες δεν είναι σχετικές ή φαίνονται ασαφείς, χρησιμοποιήστε τις γενικές σας γνώσεις για να δώσετε μια χρήσιμη απάντηση, τονίστε τυχόν αβεβαιότητες και προτείνετε στον χρήστη να παρέχει πρόσθετες πληροφορίες στην εφαρμογή για πιο ακριβείς απαντήσεις στο μέλλον.
//
//              Αν είναι σχετικό για την απάντησή σας, σήμερα είναι \(readableDateString), και η τρέχουσα ώρα σε μορφή ISO8601 είναι \(isoDateString). Μην επιστρέφετε πλήρεις ημερομηνίες και ώρες εκτός αν είναι απαραίτητο.
//              Η απάντηση θα πρέπει να είναι σαφής, ελκυστική και συνοπτική.
//"""
//        case .korean:
//            return """
//            당신은 AI 어시스턴트이며, 특정 주제에 대한 간결한 정보를 제공해달라는 요청을 받았습니다. 아래는 사용자의 질문과 벡터 데이터베이스에서 검색된 한두 가지 정보입니다. 이 정보들은 가장 높은 유사도 점수를 가진 정보이지만, 사용자의 질문과는 무관할 수도 있습니다:
//            
//                                   - 사용자의 질문: \(question).
//                                   - 관련 정보 1: \(firstVector).
//                                   - 관련 정보 2: \(secondVector).
//            
//            사용자의 질문과 제공된 정보가 관련이 있는 경우, 사용자의 문의를 해결할 수 있는 포괄적이고, 유익하며, 간결한 답변을 생성하세요. 검색된 정보의 관련성을 평가하세요:
//                               - 검색된 정보가 관련이 있다면, 이를 응답에 통합하여 유용한 답변을 제공하세요.
//                               - 검색된 정보가 관련이 없거나 모호하다면, 일반 지식을 사용하여 유용한 답변을 제공하고, 불확실성을 강조하고 사용자가 더 정확한 답변을 얻기 위해 앱에 추가 정보를 제공하도록 제안하세요.
//            
//            답변에 관련이 있다면, 오늘 날짜는 \(readableDateString), 현재 시간은 ISO8601 형식으로 \(isoDateString)입니다. 필요하지 않은 경우, 전체 날짜와 시간을 반환하지 마세요.
//            
//            답변은 명확하고, 흥미롭고, 간결해야 합니다.
//            """
//        case .japanese:
//            return """
//            あなたはAIアシスタントであり、特定のトピックに関する簡潔な情報を提供するように求められています。以下はユーザーの質問とベクトルデータベースから取得された1つまたは2つの情報です。これらの情報は最も高い類似度スコアを持っていますが、ユーザーの質問に関連しない場合があります:
//            
//                                   - ユーザーの質問: \(question).
//                                   - 関連情報1: \(firstVector).
//                                   - 関連情報2: \(secondVector).
//            
//            ユーザーの質問と提供された情報が関連している場合、それを使用してユーザーの問い合わせに対応する包括的で有益かつ簡潔な回答を生成してください。取得された情報の関連性を評価してください:
//                               - 取得された情報が関連している場合、それを回答に統合して有用な回答を提供してください。
//                               - 取得された情報が関連していない場合や曖昧な場合は、一般知識を使用して有用な回答を提供し、不確実な点を強調して、将来より正確な回答を得るためにユーザーがアプリに追加情報を提供するよう提案してください。
//            
//            回答に関連がある場合、今日は\(readableDateString)であり、現在のISO8601形式の時刻は\(isoDateString)です。必要でない限り、完全な日付や時刻を返さないでください。
//            
//            回答は明確で、魅力的で、簡潔である必要があります。
//            """
//        case .chineseSimplified:
//            return """
//您是一名AI助手，您被要求提供有关特定主题的简明信息。以下是用户的问题和从向量数据库中检索到的一两条信息。请注意，这些信息是相似度得分最高的，但可能与用户的问题无关：
//
//                       - 用户的问题: \(question)。
//                       - 相关信息1: \(firstVector)。
//                       - 相关信息2: \(secondVector)。
//
//根据用户的问题，以及提供的信息（如果相关），生成一个全面、信息丰富且简洁的回复，以回答用户的询问。评估检索到的信息的相关性：
//                   - 如果检索到的信息是相关的，请将其整合到您的回复中，以提供有帮助的回答。
//                   - 如果检索到的信息不相关或显得模糊，请使用您的一般知识提供有帮助的回答，并突出任何不确定性，建议用户提供更多信息，以便将来获得更准确的答案。
//
//如果对您的回复有帮助，今天是\(readableDateString)，当前时间是ISO8601格式的\(isoDateString)。除非必要，否则不要返回完整的日期和时间。
//
//回复应当清晰、吸引人且简洁。
//"""
//        case .portuguese:
//            return """
//            Você é um assistente de IA e foi solicitado a fornecer informações concisas sobre um tópico específico. Abaixo está a pergunta do usuário e uma ou duas peças de informação recuperadas pelo banco de dados vetorial. Note que essas informações são as que possuem a maior pontuação de similaridade, mas podem ser irrelevantes para a pergunta do usuário:
//            
//                                   - Pergunta do usuário: \(question).
//                                   - Informação relevante 1: \(firstVector).
//                                   - Informação relevante 2: \(secondVector).
//            
//            Usando a pergunta do usuário e, se relevante, as informações fornecidas, gere uma resposta abrangente, informativa e concisa que responda à consulta do usuário. Avalie a relevância das informações recuperadas:
//                               - Se as informações recuperadas forem relevantes, integre-as à sua resposta para fornecer uma resposta útil.
//                               - Se as informações recuperadas não forem relevantes ou parecerem ambíguas, use seu conhecimento geral para fornecer uma resposta útil, destaque quaisquer incertezas e sugira que o usuário forneça informações adicionais ao aplicativo para obter respostas mais precisas no futuro.
//            
//            Se for relevante para sua resposta, hoje é \(readableDateString), e a hora atual no formato ISO8601 é \(isoDateString). Não retorne datas e horários completos, a menos que seja necessário.
//            
//            A resposta deve ser clara, envolvente e concisa.
//            """
//        case .italian:
//            return """
//            Sei un assistente AI e ti è stato chiesto di fornire informazioni concise su un argomento specifico. Di seguito è riportata la domanda dell'utente e uno o due pezzi di informazioni recuperati dal database vettoriale. Nota che questi pezzi di informazioni sono quelli con il punteggio di somiglianza più alto, ma potrebbero essere irrilevanti per la domanda dell'utente:
//            
//            - Domanda dell'utente: \(question).
//            - Informazione rilevante 1: \(firstVector).
//            - Informazione rilevante 2: \(secondVector).
//            
//            Usando la domanda dell'utente, e se rilevanti le informazioni fornite, genera una risposta completa, informativa e concisa che affronti la domanda dell'utente. Valuta la rilevanza delle informazioni recuperate:
//            - Se le informazioni recuperate sono rilevanti, integrale nella tua risposta per fornire una risposta utile.
//            - Se le informazioni recuperate non sono rilevanti o sembrano ambigue, usa le tue conoscenze generali per fornire una risposta utile, evidenzia eventuali incertezze e suggerisci all'utente di fornire ulteriori informazioni all'app per risposte più accurate in futuro.
//            
//            Se rilevante per la tua risposta, oggi è \(readableDateString), e l'ora attuale nel formato ISO8601 è \(isoDateString). Non restituire date e orari completi a meno che non sia necessario.
//            
//            La risposta deve essere chiara, coinvolgente e concisa.
//            """
//        case .hebrew:
//            return "thsi"
//        }
//    }
//    
//}
