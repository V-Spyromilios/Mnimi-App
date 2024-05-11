//
//  RecordingsSettingsViewModel.swift
//  Memory
//
//  Created by Evangelos Spyromilios on 13.02.24.
//

import Foundation
import SwiftUI


//TODO: DEPRICATED
final class RecordingsViewModel: ObservableObject {
    @Published var audioFiles: [URL] = []
//    @EnvironmentObject var audioManager: AudioManager
    
    private var documentsDirectory: URL {
            FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        }
    
    func fetchAudioFiles() {
            do {
                let items = try FileManager.default.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
                audioFiles = items.filter { $0.pathExtension == "mp3"}
            } catch {
                print("Error fetching audio files: \(error)")
            }
        }
    
    func deleteAllAudioFiles() {
        for fileURL in audioFiles {
            do {
                try FileManager.default.removeItem(at: fileURL)
            } catch {
                print("Error deleting audio file: \(error)")
            }
        }
        // After deleting all files, clear the array and optionally refresh it to confirm deletion
        audioFiles.removeAll()
        fetchAudioFiles() // This will refresh the list, but it should be empty if all deletions were successful
    }

    
    func deleteAudioFile(at offsets: IndexSet) {
            for index in offsets {
                let fileURL = audioFiles[index]
                do {
                    try FileManager.default.removeItem(at: fileURL)
                    fetchAudioFiles() // Refresh the list after deletion
                } catch {
                    print("Error deleting audio file: \(error)")
                }
            }
        }
}
