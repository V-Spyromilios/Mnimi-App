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

    ///Reset the ViewModel to a clean state
    ///1. Clears all embedding data and string responses
    ///2. Resets transcription and any related errors
    ///3. Clears pending intent and reminder (but not calendar event)
    ///4. Used after processing or cancelling a user interaction
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
    

    ///Transcribe an audio file using Whisper and store result
       ///1. Saves text to `.transcription` or `.transcriptionFromWhisper` based on `fromQuestion`
       ///2. Handles errors with matching error fields for each case
       ///3. Triggers UI update via UUID when transcription fails (non-question only)
       ///4. Called after recording finishes or voice input is received
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

    ///Fetch embeddings from OpenAI for the given text
       ///1. Uses actor to request embedding vectors from OpenAI API
       ///2. Stores result in `embeddingsFromQuestion` or `embeddings` based on intent
       ///3. Triggers UI updates using `embeddingsTrigger` UUID
       ///4. Sets `.embeddingsCompleted = true` only when saving info (not for questions)
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


    ///Send question + matched vectors to OpenAI GPT
        ///1. Asks GPT to generate a response based on user's question and matched info
        ///2. Saves the response to `stringResponseOnQuestion` and `lastGptResponse`
        ///3. Clears current `userIntent` after getting response
        ///4. On failure, sets `gptResponseError` for error handling
    func getGptResponse(queryMatches: [Match], question: String) async {
        
        do {
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


    ///Analyze transcript to classify user intent
        ///1. Sends transcribed text to OpenAI to detect intent and structured fields
        ///2. If intent changed, updates `userIntent` and logs the result
        ///3. If unchanged, skips assignment but still logs for debug
        ///4. On failure, sets `openAIErrorFromQuestion` for UI to handle
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
    
    
    ///Check Calendar permission and prompt or alert as needed
        ///1. Checks current authorization status for calendar access
        ///2. If `.notDetermined` and on iOS 17+, requests write-only access
        ///3. If access is denied or restricted, shows permission alert in UI
        ///4. Hides alert if user has authorized access
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
    
    
    ///Dispatch user intent to the appropriate handler
       ///1. Called after GPT returns a classified `IntentClassificationResponse`
       ///2. Routes the intent to one of: Reminder, Calendar, Question, or Save Info
       ///3. Each type has its own handler (e.g. `handleReminderIntent`)
       ///4. Logs unknown types for debugging
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
    
    
    ///Prepare reminder for confirmation sheet
      ///1. Validate that `task` is present and non-empty
      ///2. Parse `datetime`, or fallback to `now + 1h` if missing
      ///3. If parsed datetime is in the past, fallback to `now + 24h`
      ///4. Pass normalized data to `prepareReminderForConfirmation(...)`
    private func handleReminderIntent(_ intent: IntentClassificationResponse) {
        guard let rawTask = intent.task?.trimmingCharacters(in: .whitespacesAndNewlines),
              !rawTask.isEmpty else {
            debugLog("❌ Reminder intent missing task description.")
            return
        }

        let now = Date()
        var dueDate: Date

        if let dateStr = intent.datetime,
           let parsed = parseISO8601(dateStr) {
            if parsed > now {
                debugLog("⏰ Parsed reminder datetime: '\(dateStr)' → \(parsed)")
                dueDate = parsed
            } else {
                debugLog("⚠️ Reminder datetime is in the past: '\(dateStr)' → \(parsed). Using now + 24h fallback.")
                dueDate = Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now.addingTimeInterval(86400)
            }
        } else {
            debugLog("⚠️ No datetime provided for reminder. Using now + 1h fallback.")
            dueDate = Calendar.current.date(byAdding: .hour, value: 1, to: now) ?? now.addingTimeInterval(3600)
        }

        prepareReminderForConfirmation(title: rawTask, date: dueDate)
    }
    
    
    ///Make the new Calendar Event for the .sheet confirmation
    ///1.    Ensure title is valid (non-empty, trimmed)
    ///2.   Fallback to now + 1 hour if datetime is missing or invalid
    ///3.    Ensure endDate = startDate + 1hr by default
    ///4. if the event was in the past also fallback to now plus 24hrs
    private func handleCalendarIntent(_ intent: IntentClassificationResponse) {
        guard let rawTitle = intent.title?.trimmingCharacters(in: .whitespacesAndNewlines),
              !rawTitle.isEmpty else {
            debugLog("❌ Calendar intent missing title.")
            return
        }

        let now = Date()
        var startDate: Date

        if let dateStr = intent.datetime,
           let parsed = parseISO8601(dateStr) {
            if parsed > now {
                debugLog("📅 Parsed future calendar datetime: '\(dateStr)' → \(parsed)")
                startDate = parsed
            } else {
                debugLog("⚠️ Parsed datetime is in the past: '\(dateStr)' → \(parsed). Using now + 24h fallback.")
                startDate = Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now.addingTimeInterval(86400)
            }
        } else {
            debugLog("⚠️ No valid datetime found. Using now + 1h fallback.")
            startDate = Calendar.current.date(byAdding: .hour, value: 1, to: now) ?? now.addingTimeInterval(3600)
        }

        let endDate = Calendar.current.date(byAdding: .hour, value: 1, to: startDate) ?? startDate.addingTimeInterval(3600)

        self.pendingCalendarEvent = EventWrapper(
            title: rawTitle,
            startDate: startDate,
            endDate: endDate,
            location: intent.location
        )
    }
    
    
    ///Process a user question by generating embeddings
       ///1. Ensure `query` field exists in the intent
       ///2. Launch async task to request OpenAI embeddings for the question
       ///3. Capture and store any embedding errors for display
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

    
    ///Process a user intent to save information (not a question)
       ///1. Ensure `memory` field exists in the intent
       ///2. Launch async task to generate embeddings for the info
       ///3. Save result for later storage and handle possible errors
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
    
    ///Parses a date string in ISO 8601 format into a `Date` object
       ///1. Tries standard `.withInternetDateTime` format first (no fractional seconds)
       ///2. If that fails, retries with `.withFractionalSeconds` included
       ///3. Returns a valid `Date` or `nil` if both attempts fail
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
    
    
    ///Create a new Reminder and store it in `pendingReminder` for confirmation
        ///1. Initializes `EKReminder` with title and default calendar
        ///2. Attaches a single alarm for the specified due date
        ///3. Wraps into `ReminderWrapper` for use in the UI
        ///4. Intended for pre-confirmation use before saving to EventKit
    func prepareReminderForConfirmation(title: String, date: Date) {
        debugLog("prepareReminderForConfirmation CALLED")
        let reminder = EKReminder(eventStore: self.eventStore)
        reminder.title = title
        reminder.calendar = self.eventStore.defaultCalendarForNewReminders()
        reminder.addAlarm(EKAlarm(absoluteDate: date))
        
        self.pendingReminder = ReminderWrapper(title: title, dueDate: date, notes: nil)
    }
    

    ///Save a prepared Reminder to the user’s reminders using EventKit
        ///1. Requests reminder permissions safely using a local `EKEventStore`
        ///2. Builds a new `EKReminder` from `pendingReminder` wrapper values
        ///3. Ensures calendar is writable before attempting to save
        ///4. On success, clears `pendingReminder`; otherwise sets `reminderError`
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

    
    ///Save a prepared Calendar event using EventKit
       ///1. Requests calendar permission using a local `EKEventStore` to avoid data races
       ///2. Creates a new `EKEvent` from the `pendingCalendarEvent` wrapper
       ///3. Ensures a valid, writable calendar is assigned
       ///4. On success, saves the event and clears `pendingCalendarEvent`; logs error otherwise
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
