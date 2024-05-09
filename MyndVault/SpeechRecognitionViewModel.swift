//
//  SpeechRecognitionViewModel.swift
//  Memory
//
//  Created by Evangelos Spyromilios on 16.03.24.
//

import Foundation
import Speech
import AVFoundation
import SwiftUI

//class SpeechRecognitionViewModel: ObservableObject {
//    @Published var text: String = ""
//    @Published var isListening = false
//
//    private var speechRecognizer = SFSpeechRecognizer()
//    private var audioEngine = AVAudioEngine()
//    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
//    private var recognitionTask: SFSpeechRecognitionTask?
//    private var currentTextField: Binding<String>?
//
//    func startListening(for textFieldBinding: Binding<String>) {
//        if isListening { //so no concurrent sessions are running
//            stopListening()
//        }
//
//        currentTextField = textFieldBinding //bind to passed textField
//        text = ""
//        isListening = true
//
//        if recognitionTask != nil {
//            recognitionTask?.cancel()
//            recognitionTask = nil
//        }
//
//        //set up Audio Session for capturing the mic/ managing the audio hardware
//        let audioSession = AVAudioSession.sharedInstance()
//        do {
//            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
//            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
//        } catch {
//            print("Failed to set audio session category: \(error)")
//            return
//        }
//
//        recognitionRequest = SFSpeechAudioBufferRecognitionRequest() //provides Audio to speech recogniser
//
//        let inputNode = audioEngine.inputNode
//
//        guard let recognitionRequest = recognitionRequest else {
//            fatalError("Unable to create a SFSpeechAudioBufferRecognitionRequest object")
//        }
//
//        recognitionRequest.shouldReportPartialResults = true //not waiting for the whole audio
//
//        //start recognision task on recogniser. task is sending Audio to apple
//        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in //update the bound tField and stops when isFinal or Error occurs
//            var isFinal = false
//
//            if let result = result {
//                DispatchQueue.main.async {
//                    self?.currentTextField?.wrappedValue = result.bestTranscription.formattedString
//                    isFinal = result.isFinal
//                }
//            }
//
//            if error != nil || isFinal {
//                self?.stopListening()
//            }
//        }
//
//        //install tap on the node to capture audio. inputnode == microphone
//        let recordingFormat = inputNode.outputFormat(forBus: 0)
//        //bufferSize = chunks of audio captured and send to recogniser
//        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, _) in
//            recognitionRequest.append(buffer) //append audio to recogniser
//        }
//
//        audioEngine.prepare() //prepare to ..
//
//        do {
//            try audioEngine.start() //and start capturing audio from the mic, and provide it to the recognision
//        } catch {
//            print("audioEngine couldn't start because of an error: \(error)")
//        }
//    }
//
//    func stopListening() {
//
//        audioEngine.stop()
//        recognitionRequest?.endAudio()
//        audioEngine.inputNode.removeTap(onBus: 0)
//        recognitionTask = nil
//        recognitionRequest = nil
//        isListening = false
//    }
//}


/*
 Prepare the Audio Session: The audio session is configured to record audio. This involves setting the audio category to .record, which tells the system that your app intends to record audio. Modes and options are set accordingly to manage how your app's audio interacts with other audio sources on the device.

 Create a Speech Recognition Request: A SFSpeechAudioBufferRecognitionRequest is instantiated. This object is responsible for sending audio data to Apple's servers for speech recognition. It's configured to continuously report partial recognition results, allowing your app to receive and display transcriptions in real-time as they are detected.

 Prepare the Audio Engine and Input Node: The AVAudioEngine is prepared for audio input. The engine's input node captures audio from the device's microphone.

 Install a Tap on the Input Node: By calling installTap(onBus:bufferSize:format:block:) on the input node, you set up a "tap" to intercept the audio stream from the microphone. The closure provided to the installTap method is executed repeatedly, receiving chunks of audio data (buffer) as they are captured. This audio data is then appended to the recognitionRequest via recognitionRequest.append(buffer).

 Start the Audio Engine: The audio engine is started, which begins capturing audio through the microphone and feeding it into the tap installed on the input node.

 Initiate the Speech Recognition Task: recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) {...} creates a task that sends the audio data from the recognitionRequest to Apple's speech recognition servers for analysis. The closure provided as a parameter is called with results as they are returned from the server. This closure updates the UI with the transcribed text and handles task completion or errors.
 
 */
