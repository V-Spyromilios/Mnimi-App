//
//  AudioRecordingManager.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 26.02.25.
//

import Foundation
import SwiftUI
import AVFoundation

@MainActor
@Observable
class AudioRecorder {
    var isRecording = false
    private var audioRecorder: AVAudioRecorder?
    var audioURL: URL?
    
    /// Ask for microphone permission
       func requestPermission() async -> Bool {
           let granted = await withCheckedContinuation { continuation in
               if #available(iOS 17.0, *) {
                   AVAudioApplication.requestRecordPermission { granted in
                       continuation.resume(returning: granted)
                   }
               } else {
                   AVAudioSession.sharedInstance().requestRecordPermission { granted in
                       continuation.resume(returning: granted)
                   }
               }
           }
           return granted
       }

    /// Start recording audio
    func startRecording() async throws {
        guard !isRecording else {
            print("⚠️ Already recording, skipping start request.")
            return
        } // ✅ Prevent duplicate recordings
        
        guard await requestPermission() else {
            print("❌ Microphone permission denied")
            return
        }
        
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try session.setActive(true)
        
        let fileName = "recording-\(Date().timeIntervalSince1970).m4a"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        audioURL = fileURL
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16000.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
        audioRecorder?.record()
        isRecording = true
        
        print("🎤 Recording started at: \(fileURL)")
    }

    /// Stop recording and return the file URL
    func stopRecording() -> URL? {
        guard let recorder = audioRecorder, recorder.isRecording else {
            print("⚠️ stopRecording() called, but no active recording.")
            return nil
        }
        
        recorder.stop()
        isRecording = false

        guard let audioURL = audioURL else {
            print("❌ No valid recording URL found")
            return nil
        }

        print("🛑 Recording stopped at: \(audioURL)")
        return audioURL
    }
}
