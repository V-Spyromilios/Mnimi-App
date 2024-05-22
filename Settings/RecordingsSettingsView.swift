//
//  RecordingsSettingsView.swift
//  Memory
//
//  Created by Evangelos Spyromilios on 01.03.24.
//

import SwiftUI
import Foundation

//MARK: DEPRICATED
struct RecordingsSettingsView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @ObservedObject var viewModel = RecordingsViewModel()
    
    var body: some View {
        VStack {
            if viewModel.audioFiles.isEmpty {
                // ContentUnavailableView shown when there are no audio files
                ContentUnavailableView(label: {
                    Label("No Recordings", systemImage: "play.slash")
                }, description: {
                    Text("Recordings will appear here.")
                })
                .offset(y: -contentUnaivalableOffset)
            } else {

                List {
                    ForEach(viewModel.audioFiles, id: \.self) { recording in
                        Text("h")
                    }
                    .onDelete(perform: viewModel.deleteAudioFile(at:))
                }
            }
        }
        .onAppear {
            viewModel.fetchAudioFiles()
            print("I see \(viewModel.audioFiles.count) Audio Files.")
        }
        .navigationTitle("Recordings")
        .navigationBarBackButtonHidden(true) //as we make below 'custom' Back Button
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: viewModel.deleteAllAudioFiles) {
                    Image(systemName: "trash")
                }
                .accessibilityLabel("Delete")
            }
            
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    self.presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Settings")
                    }
                    .accessibilityLabel("Back")
                }
            }
        }
    }
}

    
    //    private func deleteAll() {
    //        let fileManager = FileManager.default
    //        for url in recordingsUrls {
    //            do {
    //                try fileManager.removeItem(at: url)
    //            } catch {
    //                print("Could not delete recording: \(error.localizedDescription)")
    //            }
    //        }
    //        recordingsUrls.removeAll()
    //    }
    //
    //
    //    private func fetchAllRecordings() {
    //
    //        let fileManager = FileManager.default
    //
    //        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
    //            print("Documents directory not found.")
    //            return
    //        }
    //        do {
    //            print("fetch all : ")
    //            let files = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil, options: [])
    //            let recordings = files.filter { $0.pathExtension == "m4a" }
    //
    //            recordings.forEach { print($0.path) }
    //            self.recordingsUrls = recordings
    //            print(self.recordingsUrls.count)
    //            print("Seems the recordings are ok")
    //        } catch {
    //            print("Failed to fetch recordings: \(error.localizedDescription)")
    //            return
    //        }
    //    }
    //
    //    private func deleteRecording(at offsets: IndexSet) {
    //        let fileManager = FileManager.default
    //
    //        for index in offsets {
    //            let url = recordingsUrls[index]
    //            do {
    //                try fileManager.removeItem(at: url)
    //                print("RecordingsSettingsView :: Deleted recording: \(url.lastPathComponent)")
    //                recordingsUrls.remove(atOffsets: offsets)
    //            } catch {
    //                print("RecordingsSettingsView :: Could not delete recording: \(error.localizedDescription)")
    //            }
    //        }
    //    }
    //
    //}


#Preview {
    RecordingsSettingsView()
}
