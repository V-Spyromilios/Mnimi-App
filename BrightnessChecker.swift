//
//  BrightnessChecker.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 19.04.25.
//

import Foundation

import UIKit

func averageBrightness(of image: UIImage) -> CGFloat {
    guard let cgImage = image.cgImage else { return 1.0 }
    
    let context = CIContext()
    let ciImage = CIImage(cgImage: cgImage)
    let extent = ciImage.extent
    let inputExtent = CIVector(x: extent.origin.x, y: extent.origin.y, z: extent.size.width, w: extent.size.height)

    let filter = CIFilter(name: "CIAreaAverage", parameters: [
        kCIInputImageKey: ciImage,
        kCIInputExtentKey: inputExtent
    ])!

    guard let outputImage = filter.outputImage else { return 1.0 }

    var bitmap = [UInt8](repeating: 0, count: 4)
    context.render(outputImage,
                   toBitmap: &bitmap,
                   rowBytes: 4,
                   bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                   format: .RGBA8,
                   colorSpace: CGColorSpaceCreateDeviceRGB())

    // Return brightness (normalized)
    let brightness = (0.299 * CGFloat(bitmap[0]) +
                      0.587 * CGFloat(bitmap[1]) +
                      0.114 * CGFloat(bitmap[2])) / 255.0
    return brightness
}
