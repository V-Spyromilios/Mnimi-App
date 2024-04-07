//
//  AudioManager.swift
//  Memory
//
//  Created by Evangelos Spyromilios on 05.02.24.
//

import Foundation
import AVFoundation
import Combine

// POST   https://api.openai.com/v1/audio/transcriptions


final class AudioManager: NSObject, ObservableObject, AVAudioPlayerDelegate {

    private var audioRecorder: AVAudioRecorder?
    private var currentFileName: String = ""
    @Published var questionFilePath: URL?
    @Published var addNewFilePath: URL?
    @Published var audioPlayer: AVAudioPlayer?
    @Published var audioPlayCompleted: Bool = false
    
    static var shared = AudioManager()
    
    
    func requestRecordPermission(completion: @escaping (Bool) -> Void) {
        AVAudioApplication.requestRecordPermission { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    func setupRecorder(fromAskView: Bool) throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .default)
        try audioSession.setActive(true)
        
        let recordingSettings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ] as [String: Any]
        if fromAskView {
            if questionFilePath == nil {
                let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let timeStamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .medium)
                    .replacingOccurrences(of: " ", with: "_")
                    .replacingOccurrences(of: ",", with: "")
                    .replacingOccurrences(of: ":", with: "_")
                    .replacingOccurrences(of: "/", with: "-")
                currentFileName = "recording_\(timeStamp).m4a"
                questionFilePath = documentPath.appendingPathComponent(currentFileName)
            }
            
            guard let audioFilePath = questionFilePath else {
                print("setupRecorder() :: Failed to make the 'audioFilePath'")
                return
            }
            
            do {
                audioRecorder = try AVAudioRecorder(url: audioFilePath, settings: recordingSettings)
                audioRecorder?.prepareToRecord()
                print("Audio File Path: \(audioFilePath)")
            } catch {
                print("setupRecorder() :: Failed to initialize AVAudioRecorder -> \(error.localizedDescription)")
            }
        } else  {
            if addNewFilePath == nil {
                let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let timeStamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .medium)
                    .replacingOccurrences(of: " ", with: "_")
                    .replacingOccurrences(of: ",", with: "")
                    .replacingOccurrences(of: ":", with: "_")
                    .replacingOccurrences(of: "/", with: "-")
                currentFileName = "recording_\(timeStamp).m4a"
                addNewFilePath = documentPath.appendingPathComponent(currentFileName)
            }
            
            guard let audioFilePath = addNewFilePath else {
                print("setupRecorder() :: Failed to make the 'addNewFilePath'")
                return
            }
            
            do {
                audioRecorder = try AVAudioRecorder(url: audioFilePath, settings: recordingSettings)
                audioRecorder?.prepareToRecord()
                print("Audio File Path for AddNewView: \(audioFilePath)")
            } catch {
                print("setupRecorder() :: Failed to initialize AVAudioRecorder -> \(error.localizedDescription)")
            }
        }
    }
    
    
    func startRecording() {
        audioRecorder?.record()
    }
    
    func stopRecording() {
        audioRecorder?.stop()
    }
    
    func getRecorderAudioURL() -> URL? {
        guard let recorder = audioRecorder else { return nil }
        return recorder.url
    }
    
    // Function to retrieve all recordings
    func getAllRecordings() -> [URL] {
        let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            let directoryContents = try FileManager.default.contentsOfDirectory(at: documentPath, includingPropertiesForKeys: nil)
            return directoryContents.filter { $0.pathExtension == "m4a" }
        } catch {
            print("getAllRecordings() :: \(error.localizedDescription)")
        }
        return []
    }
    
    func recordingExistsAndHasContent(at filePath: URL, completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .background).async {
            let fileManager = FileManager.default
            let path = filePath.path
            
            // Check if the file exists
            guard fileManager.fileExists(atPath: path) else {
                DispatchQueue.main.async { completion(false) }
                return
            }
            
            // Check if the file has content
            if let attributes = try? fileManager.attributesOfItem(atPath: path),
               let fileSize = attributes[.size] as? NSNumber,
               fileSize.intValue > 0 {
                DispatchQueue.main.async { completion(true) }
            } else {
                DispatchQueue.main.async { completion(false) }
            }
        }
    }

    func playRecording(fromAskView: Bool) {
        if fromAskView {
            guard let url = self.questionFilePath else { return }
            
            do {
                
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)
                
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.volume = 1.0 // user's system volume * 1.0
                audioPlayer?.play()
            } catch {
                print("Failed to play audio: \(error.localizedDescription)")
            }
        } else  {
            guard let url = self.addNewFilePath else { return }
            
            do {
                
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)
                
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.volume = 1.0 // user's system volume * 1.0
                audioPlayer?.play()
            } catch {
                print("Failed to play audio: \(error.localizedDescription)")
            }
        }
    }

    //MARK: playAudioFrom()
    func playAudioFrom(url: URL) {
        do {

            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.volume = 1.0 // max == 1
            audioPlayer?.play()
            ProgressTracker.shared.reset()

        } catch {
            print("Failed to play audio: \(error.localizedDescription)")
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            print("audioPlayerDidFinishPlaying : \(flag)")
            self.audioPlayCompleted = flag
            
        }
    }
    
    func deleteCurrentAudioFile(fromAskView: Bool) async -> Bool {
        if fromAskView {
            guard let path = questionFilePath else {
                print("No audio file path available.")
                return false
            }
            
            do {
                try FileManager.default.removeItem(at: path)
                print("Audio file deleted successfully.")
                await _ = MainActor.run {
                    self.questionFilePath = nil
                    print("audioFilePath nil")
                    return true
                }
                
            } catch {
                print("Failed to delete audio file: \(error)")
                
            }
        } else {
            guard let path = addNewFilePath else {
                print("No audio file path available.")
                return false
            }
            
            do {
                try FileManager.default.removeItem(at: path)
                print("Audio file deleted successfully.")
                await _ = MainActor.run {
                    self.addNewFilePath = nil
                    print("audioFilePath nil")
                    return true
                }
                
            } catch {
                print("Failed to delete audio file: \(error)")
                
            }
        }
            return false
        }
}


