//
//  ImagePickerViewModel.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 22.06.24.
//

import SwiftUI
import PhotosUI

final class ImagePickerViewModel: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var isPickerPresented = false

    func presentPicker() {
        isPickerPresented = true
    }

    func handlePickedImage(result: PHPickerResult) {
        result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] (object, error) in
            if let image = object as? UIImage {
                DispatchQueue.main.async {
                    self?.selectedImage = image
                }
            }
        }
    }
}


struct PHPickerViewControllerRepresentable: UIViewControllerRepresentable {
    @ObservedObject var viewModel: ImagePickerViewModel

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PHPickerViewControllerRepresentable

        init(_ parent: PHPickerViewControllerRepresentable) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true, completion: nil)
            guard let result = results.first else { return }
            parent.viewModel.handlePickedImage(result: result)
        }
    }
}
