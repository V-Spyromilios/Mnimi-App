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
    
    @Published var transcriptionErrorTrigger = UUID()
    @Published var embeddingsTrigger = UUID()
    @Published var stringResponseOnQuestion: String = ""
    @Published var gptResponseError: OpenAIError?
    @Published var openAIErrorFromQuestion: OpenAIError?
    @Published var transcription: String = ""
    @Published var transcriptionFromWhisper: String = ""
    @Published var transriptionError: OpenAIError?
    @Published var transriptionErrorForQuestion: OpenAIError?
    
    @Published var userIntent: IntentClassificationResponse? = nil
    @Published var showCalendarPermissionAlert: Bool = false
    @Published var pendingReminder: ReminderWrapper?
    @Published var pendingCalendarEvent: EventWrapper?
    @Published var calendarError: OpenAIError?
    @Published var reminderError: OpenAIError?
    private let openAIActor: OpenAIActor
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
        transcriptionFromWhisper = ""
        
        if userIntent != nil {
            userIntent = nil
        }
        pendingReminder = nil
    }
    
    
    func processAudio(fileURL: URL, fromQuestion: Bool) async {
        
        if !fromQuestion {
            
            do {
                let response = try await openAIActor.transcribeAudio(fileURL: fileURL)
                self.transcription = response.text
            } catch {
                self.transriptionError = .transriptionFailed(error)
                transcriptionErrorTrigger = UUID()
                debugLog("❌ processAudio() :: Error transcribing audio: \(error)")
            }
        } else {
            
            do {
                let response = try await openAIActor.transcribeAudio(fileURL: fileURL)
                self.transcriptionFromWhisper = response.text
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
                embeddingsTrigger = UUID()
                
            } else {
                self.embeddings = embeddingsData
                self.embeddingsCompleted = true
                embeddingsTrigger = UUID()
            }
        } catch {
            throw error
        }
    }
    
    func getGptResponse(queryMatches: [Match], question: String) async {
        
        do {
            // Access `languageSettings` on the main actor
            
            // Perform network call off the main actor
            let response = try await openAIActor.getGptResponse(
                vectorResponses: queryMatches,
                question: question
            )
            self.stringResponseOnQuestion = response
            self.lastGptResponse = response //TODO: Once you’ve saved it to Pinecone, you might want to clear it
            self.userIntent = nil
            
        } catch {
            self.gptResponseError = .gptResponseFailed(error)
        }
    }
    
    func getTranscriptAnalysis(transcrpit: String) async {
        
        do {
            // Perform network call off the main actor
            let response: IntentClassificationResponse = try await openAIActor.analyzeTranscript(transcript: transcrpit)
            
            if self.userIntent != response {
                debugLog("✅ userIntent is different — assigning [ViewModel]")
                self.userIntent = response
                
                debugLog("📍 After assignment — new intent: \(response)")
                
            } else {
                debugLog("⚠️ userIntent unchanged — not assigning")
            }
            
            debugLog("getTranscriptAnalysis, assigned to userIntent: \(response)")
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
            handleReminderIntent(intent)
        case .isCalendar:
            handleCalendarIntent(intent)
        case .isQuestion:
            handleQuestionIntent(intent)
        case .saveInfo:
            handleSaveInfoIntent(intent)
        case .unknown:
            debugLog("⚠️ Unknown response type: \(intent.type)")
        }
    }
    
    
    
    
    private func handleReminderIntent(_ intent: IntentClassificationResponse) {
        
        //TODO: they both fail without datetime!! Provide default more centrally
        
        if let task = intent.task, let dateStr = intent.datetime, let date = parseISO8601(dateStr) {
            prepareReminderForConfirmation(title: task, date: date)
        } else {
            debugLog("❌ Failed to parse reminder intent: Task=\(intent.task ?? "nil"), Date=\(intent.datetime ?? "nil")")
        }
    }
    
    
    private func handleCalendarIntent(_ intent: IntentClassificationResponse) {
        
        if let title = intent.title,
           let dateStr = intent.datetime,
           let date = parseISO8601(dateStr) { // already in local time if it has +02:00
            
            
            print("parsed: \(dateStr) → \(date)")
            print("device time zone: \(TimeZone.current)")
//            let newEvent = EKEvent(eventStore: self.eventStore)
//            newEvent.title = title
//            newEvent.startDate = date
//            newEvent.endDate = date.addingTimeInterval(3600)
//            newEvent.location = intent.location
//            newEvent.calendar = self.eventStore.defaultCalendarForNewEvents
            self.pendingCalendarEvent = EventWrapper(title: title, startDate: date, endDate: date.addingTimeInterval(3600), location: intent.location)
        }
    }
    
    private func handleQuestionIntent(_ intent: IntentClassificationResponse) {
        
        if let userQuestion = intent.query {
            Task {
                do  {
                    try await requestEmbeddings(for: userQuestion, isQuestion: true)
                } catch(let error) {
                    self.openAIErrorFromQuestion = .embeddingsFailed(error)
                }
            }
        }
    }
    
    private func handleSaveInfoIntent(_ intent: IntentClassificationResponse) {
        
        if let newInfo = intent.memory {
            Task {
                do  {
                    try await requestEmbeddings(for: newInfo, isQuestion: false)
                } catch(let error) {
                    self.openAIErrorFromQuestion = .embeddingsFailed(error)
                }
            }
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
    func prepareReminderForConfirmation(title: String, date: Date) {
        debugLog("prepareReminderForConfirmation CALLED")
        let reminder = EKReminder(eventStore: self.eventStore)
        reminder.title = title
        reminder.calendar = self.eventStore.defaultCalendarForNewReminders()
        reminder.addAlarm(EKAlarm(absoluteDate: date))
        
        self.pendingReminder = ReminderWrapper(title: title, dueDate: date, notes: nil)
    }
    

    @MainActor
    func savePendingReminder() async -> Bool {
        debugLog("savePendingReminder CALLED")

        let store = EKEventStore()  // ✅ avoid data races

        do {
            let granted = try await store.requestFullAccessToReminders()

            guard granted else {
                debugLog("❌ Reminder access not granted")
                reminderError = .missingReminderPermissions
                return false
            }
        } catch {
            debugLog("❌ Failed to request reminder access: \(error.localizedDescription)")
            return false
        }

        guard let wrapper = pendingReminder else {
            debugLog("❌ pendingReminder is nil.")
            return false
        }

        let reminder = EKReminder(eventStore: store)
        reminder.title = wrapper.title
        reminder.dueDateComponents = wrapper.dueDate.map { Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: $0) }
        reminder.notes = wrapper.notes

        reminder.calendar = store.defaultCalendarForNewReminders()
            ?? store.calendars(for: .reminder).first(where: { $0.allowsContentModifications })

        guard reminder.calendar != nil else {
            debugLog("❌ No writable reminder calendar available")
            return false
        }

        do {
            try store.save(reminder, commit: true)
            debugLog("✅ Reminder saved successfully.")
            self.pendingReminder = nil
            return true
        } catch {
            debugLog("❌ Failed to save reminder: \(error.localizedDescription)")
            reminderError = .reminderError(error)
            return false
        }
    }
    
    @MainActor
    func saveCalendarEvent() async -> Bool {
        debugLog("saveCalendarEvent CALLED")

        let store = EKEventStore()

        do {
            let granted = try await store.requestFullAccessToEvents()

            guard granted else {
                debugLog("❌ Calendar access not granted")
                calendarError = .missingCalendarPermissions
                return false
            }
        } catch {
            debugLog("❌ Failed to request calendar access: \(error.localizedDescription)")
            return false
        }

        guard let wrapper = pendingCalendarEvent else {
            debugLog("❌ calendarEvent is nil.")
            return false
        }

        let e = EKEvent(eventStore: store)
        e.title = wrapper.title
        e.startDate = wrapper.startDate
        e.endDate = wrapper.endDate
        e.location = wrapper.location
        e.calendar = store.defaultCalendarForNewEvents
            ?? store.calendars(for: .event).first(where: { $0.allowsContentModifications })

        guard e.calendar != nil else {
            debugLog("❌ No writable calendar found")
            return false
        }

        do {
            try store.save(e, span: .thisEvent, commit: true)
            debugLog("✅ Calendar event saved successfully.")
            self.pendingCalendarEvent = nil
            return true
        } catch {
            debugLog("❌ Failed to save calendar event: \(error.localizedDescription)")
            return false
        }
    }
}
