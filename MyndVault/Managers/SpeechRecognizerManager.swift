//
//  SpeechRecognizerManager.swift
//  Memory
//
//  Created by Evangelos Spyromilios on 14.03.24.
//

import Foundation
import Speech

class SpeechRecognizerManager: ObservableObject {
    @Published var isAuthorized: Bool = false
    @Published var authorizationMessage: String = ""

    func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    self.isAuthorized = true
                    self.authorizationMessage = "User granted access to speech recognition."
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
    }

    func checkSpeechAuthorizationStatus() {
        let authStatus = SFSpeechRecognizer.authorizationStatus()
        
        DispatchQueue.main.async {
            switch authStatus {
            case .authorized:
                self.isAuthorized = true
                self.authorizationMessage = "Authorized for speech recognition."
            case .denied, .restricted, .notDetermined:
                self.isAuthorized = false
                self.authorizationMessage = "Not authorized for speech recognition."
            @unknown default:
                self.isAuthorized = false
                self.authorizationMessage = "Unknown authorization status."
            }
        }
    }
}
