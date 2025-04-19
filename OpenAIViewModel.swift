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
//    @Published var questionEmbeddingsCompleted: Bool = false
    @Published var transcriptionErrorTrigger = UUID()
    @Published var questionEmbeddingTrigger = UUID()
    @Published var stringResponseOnQuestion: String = ""
    @Published var gptResponseError: OpenAIError?
    @Published var openAIErrorFromQuestion: OpenAIError?
    @Published var transcription: String = ""
    @Published var transcriptionForQuestion: String = ""
    @Published var transriptionError: OpenAIError?
    @Published var transriptionErrorForQuestion: OpenAIError?
    @Published var reminderError: OpenAIError?
    @Published var intentResponse: IntentClassificationResponse?
    @Published var showCalendarPermissionAlert: Bool = false
    @Published var calendarEvent: EKEvent?
    @Published var reminderCreated: Bool = false

    private let openAIActor: OpenAIActor
    private var languageSettings = LanguageSettings.shared
    private var cancellables = Set<AnyCancellable>()
    let eventStore = EKEventStore()
    @Published var lastGptResponse: String? = nil

    init(openAIActor: OpenAIActor) {
        self.openAIActor = openAIActor
    }
    
    func clearManager() {
        embeddings = []
        embeddingsFromQuestion = []
        embeddingsCompleted = false
        
        stringResponseOnQuestion = ""
        
        gptResponseError = nil
        transriptionError = nil
        transriptionErrorForQuestion = nil
        transcription = "" //TODO: Check if this affects the addnew info . 
        transcriptionForQuestion = ""
        reminderError = nil
        if intentResponse != nil {
            intentResponse = nil
        }
        reminderError = nil
        intentResponse = nil
        calendarEvent = nil
    }
    

        func processAudio(fileURL: URL, fromQuestion: Bool) async {
            let selectedLanguage = self.languageSettings.selectedLanguage.rawValue

            if !fromQuestion {
               
                do {
                    let response = try await openAIActor.transcribeAudio(fileURL: fileURL, selectedLanguage: selectedLanguage)
                    self.transcription = response.text
                } catch {
                    self.transriptionError = .transriptionFailed(error)
                    transcriptionErrorTrigger = UUID()
                    debugLog("❌ processAudio() :: Error transcribing audio: \(error)")
                }
            } else {
                
                do {
                    let response = try await openAIActor.transcribeAudio(fileURL: fileURL, selectedLanguage: selectedLanguage)
                    self.transcriptionForQuestion = response.text
                } catch {
                    self.transriptionErrorForQuestion = .transriptionFailed(error)
                    debugLog("❌ processAudio() :: Error transcribing audio: \(error)")
                }
            }
          
        }
    
    func requestEmbeddings(for text: String, isQuestion: Bool) async throws {
//        throw AppNetworkError.unknownError("Debugare")
        do {

            let embeddingsResponse: EmbeddingsResponse = try await openAIActor.fetchEmbeddings(for: text)

            debugLog("embeddingsResponse: \(embeddingsResponse.data.first.debugDescription)")

            let embeddingsData = embeddingsResponse.data.flatMap { $0.embedding }
           
            // Update properties
            if isQuestion {
                self.embeddingsFromQuestion = embeddingsData
                questionEmbeddingTrigger = UUID()

            } else {
                self.embeddings = embeddingsData
                self.embeddingsCompleted = true
                questionEmbeddingTrigger = UUID()
            }
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
            self.lastGptResponse = response //TODO: Once you’ve saved it to Pinecone, you might want to clear it
            self.intentResponse = nil

        } catch {
            self.gptResponseError = .gptResponseFailed(error)
        }
    }
    
    func getTranscriptAnalysis(transcrpit: String) async {

        do {
            // Access `languageSettings` on the main actor
            let selectedLanguage = self.languageSettings.selectedLanguage

            // Perform network call off the main actor
            let response: IntentClassificationResponse = try await openAIActor.analyzeTranscript(transcript: transcrpit, selectedLanguage: selectedLanguage)
            
            self.intentResponse = response
        } catch(let error) {
            self.openAIErrorFromQuestion = .gptResponseFailed(error)
            debugLog("Error from getTranscriptAnalysis: \(error)")
        }
    }


    func checkCalendarPermission() {

        let status = EKEventStore.authorizationStatus(for: .event)

        switch status {
        case .notDetermined:
            if #available(iOS 17.0, *) {
                eventStore.requestWriteOnlyAccessToEvents { granted, error in
                    DispatchQueue.main.async {
                        if !granted {
                            debugLog("❌ User denied Calendar access when prompted.")
                            self.showCalendarPermissionAlert = true
                        }

                    }
                }
            }

        case .denied, .restricted:
            self.showCalendarPermissionAlert = true

        case .authorized, .fullAccess, .writeOnly:
            self.showCalendarPermissionAlert = false

        @unknown default:
            self.showCalendarPermissionAlert = true
        }
    }
    
    /// Processes the classified intent and takes appropriate action
        func handleClassifiedIntent(_ intent: IntentClassificationResponse) {
            debugLog("handleClassifiedIntent called with intent: \(intent)")
            switch intent.type {
                
            case .isReminder:
                if let task = intent.task, let dateStr = intent.datetime, let date = parseISO8601(dateStr) {
                    createReminder(title: task, date: date)
                } else {
                    debugLog("❌ Failed to parse reminder intent: Task=\(intent.task ?? "nil"), Date=\(intent.datetime ?? "nil")")
                }
                
                
            case .isCalendar:
                if let title = intent.title, let dateStr = intent.datetime, let utcDate = parseISO8601(dateStr) {
                    
                    let localDate = utcDate.toLocalTime() // As the UTC is for example -1 from Berlin time
                    
                    let newEvent = EKEvent(eventStore: self.eventStore)
                    newEvent.title = title
                    newEvent.startDate = localDate
                    newEvent.endDate = localDate.addingTimeInterval(3600) // Default 1-hour event
                    newEvent.location = intent.location
                    newEvent.calendar = self.eventStore.defaultCalendarForNewEvents
                    
                    self.calendarEvent = newEvent // Triggers .onChange in the View
                }

            case .isQuestion:
                if let userQuestion = intent.query {
                    Task {
                        do  {
                            try await requestEmbeddings(for: userQuestion, isQuestion: true)
                        } catch(let error) {
                            self.openAIErrorFromQuestion = .embeddingsFailed(error)
                        }
                    }
                }
            case .saveInfo:
                if let newInfo = intent.memory {
                    Task {
                        do  {
                            try await requestEmbeddings(for: newInfo, isQuestion: false)
                        } catch(let error) {
                            self.openAIErrorFromQuestion = .embeddingsFailed(error)
                        }
                    }
                }
            default:
                debugLog("⚠️ Unknown response type: \(intent.type)")
            }
        }
    
    private func parseISO8601(_ string: String) -> Date? {
        let formatter = ISO8601DateFormatter()

        // Try without fractional seconds first
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: string) {
            return date
        }

        // Fallback: try with fractional seconds
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: string)
    }
        
        /// Creates a Reminder using EventKit
    private func createReminder(title: String, date: Date) {
        
        Task {
            let reminder = EKReminder(eventStore: self.eventStore)
            reminder.title = title
            reminder.calendar = self.eventStore.defaultCalendarForNewReminders()

            let alarm = EKAlarm(absoluteDate: date)
            reminder.addAlarm(alarm)

            do {
                try self.eventStore.save(reminder, commit: true)
                debugLog("Reminder saved successfully! setting up the reminderCreated flag")
                self.reminderCreated = true
            } catch {
                self.reminderError = .reminderError(error)
                debugLog("❌ Failed to save reminder: \(error.localizedDescription)")
            }
        }
    }

}
