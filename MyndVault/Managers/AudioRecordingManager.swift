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
final class AudioRecorder: ObservableObject {

    @Published var isRecording = false
    private var avAudioRecorder: AVAudioRecorder?
    @Published var audioURL: URL?


    /// Ask for microphone permission
    func requestPermission() async -> Bool {
        await AVAudioApplication.requestRecordPermission()
    }

    /// Start recording audio
    func startRecording() async throws {
        guard !isRecording else {
            print("⚠️ Already recording, skipping start request.")
            return
        } // ✅ Prevent duplicate recordings
        
//        guard await requestPermission() else {
//            debugLog("❌ Microphone permission denied")
//            return
//        }
        
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
        
        avAudioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
        avAudioRecorder?.record()
        isRecording = true
        
        debugLog("🎤 Recording started at: \(fileURL)")
    }

    /// Stop recording and return the file URL
    func stopRecording() -> URL? {
        guard let recorder = avAudioRecorder, recorder.isRecording else {
            print("⚠️ stopRecording() called, but no active recording.")
            return nil
        }
        
        recorder.stop()
        isRecording = false
        try? AVAudioSession.sharedInstance().setActive(false)

        guard let audioURL = audioURL else {
            print("❌ No valid recording URL found")
            return nil
        }

        debugLog("🛑 Recording stopped at: \(audioURL)")
        return audioURL
    }
    
    func deleteAudioAndUrl() {
        guard let audioURL = audioURL else { return }
        
        do {
            try FileManager.default.removeItem(at: audioURL)
            self.audioURL = nil
            debugLog("🗑️ Successfully deleted recording at \(audioURL)")
        } catch {
            debugLog("⚠️ Error deleting recording: \(error.localizedDescription)")
        }
               
    }
}
