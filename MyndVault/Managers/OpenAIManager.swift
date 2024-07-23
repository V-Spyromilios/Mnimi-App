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

    @Published var notificationsSummary = ""
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
        }
        //        print("clearManager() called.")
    }

    
    //MARK: requestEmbeddings USED in QuestionView
    // call with MetadataResponse.description
    
    func requestEmbeddings(for text: String, isQuestion: Bool) async throws {
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
            if let localError = localError {
                throw localError
            }
//            await MainActor.run {
//                self.thrownError = AppNetworkError.unknownError("Error 2.12").errorDescription
//            }
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
        }

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

    func getMonthlySummary(notifications: [CustomNotification]) async throws {

        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw AppNetworkError.invalidOpenAiURL
        }
        
        guard let apiKey = ApiConfiguration.openAIKey else {
            throw AppNetworkError.apiKeyNotFound
        }
       
        let currentDate = Date()
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.timeZone = TimeZone.current
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds, .withTimeZone]
        let isoDateString = isoFormatter.string(from: currentDate)
        
        // Filter notifications for the current month
        let calendar = Calendar.current
        let currentMonthNotifications = notifications.filter { notification in
            calendar.isDate(notification.date, equalTo: currentDate, toGranularity: .month)
        }

        let prompt = getGptPrompt(notifications: currentMonthNotifications, currentDate: isoDateString)

        let requestBody: [String: Any] = [
            "model": "gpt-4o",
            "temperature": 0,
            "messages": [["role": "system", "content": prompt]]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let summary = try await fetchSummaryResponse(request: request, requestBody: requestBody)
            await MainActor.run {
                notificationsSummary = summary
            }
        }
        catch(let error) {
            throw error
        }
        
    }
    
    
    private func fetchSummaryResponse(request: URLRequest, requestBody: [String: Any]) async throws -> String {
        var mutableRequest = request
        let maxAttempts = 2
        var attempts = 0
        var localError: Error?

        while attempts < maxAttempts {
            do {
                mutableRequest.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
                let (data, response) = try await URLSession.shared.data(for: mutableRequest)
                
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
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
                }
            }
        }
        throw localError ?? AppNetworkError.unknownError("An unknown error occurred during GPT summary response ops.")
    }
    
    
    func getGptPrompt(notifications: [CustomNotification], currentDate: String) -> String {
        //TODO: " avoid using time annotations like 'local time' " in other languages as well
        let notificationTexts = notifications.map { notification in
            "Title: \(notification.title), Body: \(notification.notificationBody), Date: \(notification.date)"
        }
        
        switch selectedLanguage {
        case .english:
            return """
You are a helpful personal assistant. The date and time now in ISO8601 format is \(currentDate).
Below is a list of scheduled notifications for the current month:

\(notificationTexts.joined(separator: "\n"))

Please provide a summary of these notifications, highlighting important events and any notable patterns. Ensure the summary is easy to understand, for example "Next Thursday you have to meet Jane for coffee at 6pm."

Focus on creating a concise overview that can help the user quickly understand their upcoming schedule. Avoid using special characters like '*', avoid using time annotations like 'local time'.
            
"""
        case .spanish:
            return """
Eres un asistente personal útil. La fecha y hora actual en formato ISO8601 es \(currentDate).
A continuación se muestra una lista de notificaciones programadas para el mes actual:

\(notificationTexts.joined(separator: "\n"))

Por favor, proporciona un resumen de estas notificaciones, destacando eventos importantes y cualquier patrón notable. Asegúrate de que el resumen sea fácil de entender, por ejemplo, "El próximo jueves tienes que reunirte con Jane para tomar un café a las 6pm."

Concéntrate en crear una visión general concisa que pueda ayudar al usuario a comprender rápidamente su horario próximo. Evita usar caracteres especiales como '*'.
            
"""
        case .french:
            return """
Vous êtes un assistant personnel utile. La date et l'heure actuelles au format ISO8601 sont \(currentDate).
Voici une liste des notifications prévues pour le mois en cours :

\(notificationTexts.joined(separator: "\n"))

Veuillez fournir un résumé de ces notifications, en mettant en évidence les événements importants et les motifs notables. Assurez-vous que le résumé soit facile à comprendre, par exemple "Jeudi prochain, vous devez rencontrer Jane pour un café à 18h."

Concentrez-vous sur la création d'un aperçu concis qui puisse aider l'utilisateur à comprendre rapidement son emploi du temps à venir. Évitez d'utiliser des caractères spéciaux comme '*'.
            
"""
        case .german:
            return """
Sie sind ein hilfreicher persönlicher Assistent. Das aktuelle Datum und die Uhrzeit im ISO8601-Format sind \(currentDate).
Im Folgenden finden Sie eine Liste der geplanten Benachrichtigungen für den aktuellen Monat:

\(notificationTexts.joined(separator: "\n"))

Bitte geben Sie eine Zusammenfassung dieser Benachrichtigungen, indem Sie wichtige Ereignisse und bemerkenswerte Muster hervorheben. Stellen Sie sicher, dass die Zusammenfassung leicht zu verstehen ist, zum Beispiel "Nächsten Donnerstag müssen Sie sich um 18 Uhr mit Jane auf einen Kaffee treffen."

Konzentrieren Sie sich darauf, einen kurzen Überblick zu erstellen, der dem Benutzer hilft, seinen bevorstehenden Zeitplan schnell zu verstehen. Vermeiden Sie die Verwendung von Sonderzeichen wie '*'.
            
"""
        case .greek:
            return """
            Είστε ένας χρήσιμος προσωπικός βοηθός. Η τρέχουσα ημερομηνία και ώρα σε μορφή ISO8601 είναι \(currentDate).
            Παρακάτω υπάρχει μια λίστα με τις προγραμματισμένες ειδοποιήσεις για τον τρέχοντα μήνα:

            \(notificationTexts.joined(separator: "\n"))

            Παρακαλώ, παρέχετε μια περίληψη αυτών των ειδοποιήσεων, επισημαίνοντας σημαντικά γεγονότα και αξιοσημείωτα μοτίβα. Βεβαιωθείτε ότι η περίληψη είναι εύκολα κατανοητή, για παράδειγμα "Την επόμενη Πέμπτη πρέπει να συναντήσετε την Jane για καφέ στις 6 μ.μ."

            Επικεντρωθείτε στη δημιουργία μιας συνοπτικής επισκόπησης που μπορεί να βοηθήσει τον χρήστη να κατανοήσει γρήγορα το προσεχές πρόγραμμά του. Αποφύγετε τη χρήση ειδικών χαρακτήρων όπως '*'.
"""
        }
    }
    
}
