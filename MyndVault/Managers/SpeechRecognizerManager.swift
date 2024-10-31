//
//  SpeechRecognizerManager.swift
//  Memory
//
//  Created by Evangelos Spyromilios on 14.03.24.
//

import Foundation
import Speech

@MainActor
class SpeechRecognizerManager: ObservableObject {
    @Published var isAuthorized: Bool = false
    @Published var authorizationMessage: String = ""
    
    func requestSpeechAuthorization() async {
        let authStatus = await SFSpeechRecognizer.requestAuthorizationAsync()
        updateAuthorizationStatus(authStatus)
    }
    
    func checkSpeechAuthorizationStatus() {
        let authStatus = SFSpeechRecognizer.authorizationStatus()
        updateAuthorizationStatus(authStatus)
    }
    
    private func updateAuthorizationStatus(_ authStatus: SFSpeechRecognizerAuthorizationStatus) {
        switch authStatus {
        case .authorized:
            self.isAuthorized = true
            self.authorizationMessage = "Authorized for speech recognition."
        case .denied:
            self.isAuthorized = false
            self.authorizationMessage = "User denied access to speech recognition."
        case .restricted:
            self.isAuthorized = false
            self.authorizationMessage = "Speech recognition restricted on this device."
        case .notDetermined:
            self.isAuthorized = false
            self.authorizationMessage = "Speech recognition not yet authorized."
        @unknown default:
            self.isAuthorized = false
            self.authorizationMessage = "Unknown authorization status."
        }
    }
}

extension SFSpeechRecognizer {
    static func requestAuthorizationAsync() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }
}
