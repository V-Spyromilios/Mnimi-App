//
//  OpenAIViewModel.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 31.10.24.
//

import Foundation
import SwiftUI
import UIKit
import Combine
import EventKit
import EventKitUI // for user to confirm

@MainActor
class OpenAIViewModel: ObservableObject {

    @Published var embeddings: [Float] = []
    @Published var embeddingsFromQuestion: [Float] = []
    @Published var embeddingsCompleted: Bool = false
    @Published var questionEmbeddingsCompleted: Bool = false
    @Published var stringResponseOnQuestion: String = ""
    @Published var openAIError: OpenAIError?
    @Published var transcription: String = ""
    @Published var transriptionError: OpenAIError?
    @Published var intentResponse: IntentClassificationResponse?
    @Published var calendarEvent: EKEvent?

    private let openAIActor: OpenAIActor
    private var languageSettings = LanguageSettings.shared
    private var cancellables = Set<AnyCancellable>()
    let eventStore = EKEventStore()

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
    

        func processAudio(fileURL: URL) async {
            let selectedLanguage = self.languageSettings.selectedLanguage.rawValue
            do {
                let response = try await openAIActor.transcribeAudio(fileURL: fileURL, selectedLanguage: selectedLanguage)
                self.transcription = response.text
                debugLog("📝 Transcription received: \(response.text)")
            } catch {
                self.transriptionError = .transriptionFailed(error)
                debugLog("❌ processAudio() :: Error transcribing audio: \(error)")
            }
        }
    
    func requestEmbeddings(for text: String, isQuestion: Bool) async throws {
//        throw AppNetworkError.unknownError("DEBUG")
        do {

            debugLog("requestEmbeddings do {")
            let embeddingsResponse: EmbeddingsResponse = try await openAIActor.fetchEmbeddings(for: text)

            debugLog("embeddingsResponse: \(embeddingsResponse.data.first.debugDescription)")

            let embeddingsData = embeddingsResponse.data.flatMap { $0.embedding }
           
            // Update properties
            if isQuestion {
                self.embeddingsFromQuestion = embeddingsData
                self.questionEmbeddingsCompleted = true
            } else {
                self.embeddings = embeddingsData
                self.embeddingsCompleted = true

                debugLog("requestEmbeddings after updating properties {")

            }
            debugLog("requestEmbeddings before catch {")

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
    
    func getTranscriptAnalysis(transcrpit: String) async {

        do {
            // Access `languageSettings` on the main actor
            let selectedLanguage = self.languageSettings.selectedLanguage

            // Perform network call off the main actor
            let response: IntentClassificationResponse = try await openAIActor.analyzeTranscript(transcrpt: transcrpit, selectedLanguage: selectedLanguage)
            
            self.intentResponse = response
        } catch {
            self.openAIError = .gptResponseFailed(error)
        }
    }
    
    /// Processes the classified intent and takes appropriate action
        func handleClassifiedIntent(_ intent: IntentClassificationResponse) {
            switch intent.type {
           
                
            case "is_reminder":
                if let task = intent.task, let dateStr = intent.datetime,
                   let date = ISO8601DateFormatter().date(from: dateStr) {
                    createReminder(title: task, date: date) // ✅ Call EventKit
                }

            case "is_calendar":
                if let title = intent.title, let dateStr = intent.datetime,
                              let date = ISO8601DateFormatter().date(from: dateStr) {

                               let newEvent = EKEvent(eventStore: eventStore)
                               newEvent.title = title
                               newEvent.startDate = date
                               newEvent.endDate = date.addingTimeInterval(3600) // Default 1-hour event
                               newEvent.location = intent.location
                               newEvent.calendar = eventStore.defaultCalendarForNewEvents
                               
                               DispatchQueue.main.async {
                                   self.calendarEvent = newEvent // Triggers .onChange in the View
                               }
                           }

            default:
                debugLog("⚠️ Unknown response type: \(intent.type)")
            }
        }
        
        /// Creates a Reminder using EventKit
        private func createReminder(title: String, date: Date) {

            let eventStore = EKEventStore()

            eventStore.requestFullAccessToEvents { granted, error in
                guard granted, error == nil else {
                    debugLog("❌ Reminder access denied: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                let reminder = EKReminder(eventStore: eventStore)
                reminder.title = title
                reminder.calendar = eventStore.defaultCalendarForNewReminders()
                
                let alarm = EKAlarm(absoluteDate: date)
                reminder.addAlarm(alarm)
                
                do {
                    try eventStore.save(reminder, commit: true)
                    debugLog("✅ Reminder added successfully: \(title) at \(date)")
                } catch {
                    debugLog("❌ Failed to save reminder: \(error.localizedDescription)")
                }
            }
        }

    /// Adds event to the calendar
    private func addEvent(to eventStore: EKEventStore, title: String, date: Date, location: String?) {
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = date
        event.endDate = date.addingTimeInterval(3600) // Default 1-hour duration
        event.location = location
        event.calendar = eventStore.defaultCalendarForNewEvents

        do {
            try eventStore.save(event, span: .thisEvent)
            debugLog("✅ Calendar event added: \(title) on \(date)")
        } catch {
            debugLog("❌ Failed to save event: \(error.localizedDescription)")
        }
    }
    
    /// Presents Apple's built-in event editor for user confirmation
    func presentEventEditView(eventStore: EKEventStore, event: EKEvent, presenter: UIViewController) {
        let eventEditVC = EKEventEditViewController()
        eventEditVC.eventStore = eventStore
        eventEditVC.event = event
        eventEditVC.editViewDelegate = presenter as? EKEventEditViewDelegate // ✅ Delegate required
        
        presenter.present(eventEditVC, animated: true)
    }
}
