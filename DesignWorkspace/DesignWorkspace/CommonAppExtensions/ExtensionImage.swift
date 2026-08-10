//
//  ExtensionUIImage.swift
//  MVS Marquee
//
//  Created by Dustin Nielson on 11/17/23.
//

import VideoToolbox
import Metal
import OSLog
import LoggingKit



#if !os(macOS)//os(iOS)
import UIKit

extension UIImage {

    func pixelBuffer() -> CVPixelBuffer? {
        let image = self
        let size = image.size

        // Validate image size
        guard size.width > 0 && size.height > 0 else {
            mlog.error("UIImage.pixelBuffer — invalid image size: \(size.width)x\(size.height)")
            return nil
        }

        let renderer = UIGraphicsImageRenderer(size: size)

        // Render the UIImage into a CGImage
        guard let cgImage = renderer.image(actions: { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }).cgImage else {
            mlog.error("UIImage.pixelBuffer — failed to create CGImage from UIImage")
            return nil
        }

        // Pixel buffer attributes
        let options: [CFString: Any] = [
            kCVPixelBufferMetalCompatibilityKey: true,
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ]

        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(size.width),
            Int(size.height),
            kCVPixelFormatType_32BGRA,
            options as CFDictionary,
            &pixelBuffer
        )

        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            mlog.error("UIImage.pixelBuffer — CVPixelBufferCreate failed with status: \(status)")
            return nil
        }

        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }

        let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        )

        guard let context = context else {
            mlog.error("UIImage.pixelBuffer — failed to create CGContext")
            return nil
        }

        context.draw(cgImage, in: CGRect(origin: .zero, size: size))

        return pixelBuffer
    }


}
#elseif os(macOS)
import Cocoa

extension NSImage {

    func pixelBuffer() -> CVPixelBuffer? {
            let width = self.size.width
            let height = self.size.height
            let attrs = [
                kCVPixelBufferMetalCompatibilityKey: kCFBooleanTrue,
                kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue
            ] as CFDictionary
            var pixelBuffer: CVPixelBuffer?
            let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                             Int(width),
                                             Int(height),
                                             kCVPixelFormatType_32BGRA,
                                             attrs,
                                             &pixelBuffer)

            guard let resultPixelBuffer = pixelBuffer, status == kCVReturnSuccess else {
                return nil
            }

            CVPixelBufferLockBaseAddress(resultPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
            let pixelData = CVPixelBufferGetBaseAddress(resultPixelBuffer)

            let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
            guard let context = CGContext(data: pixelData,
                                          width: Int(width),
                                          height: Int(height),
                                          bitsPerComponent: 8,
                                          bytesPerRow: CVPixelBufferGetBytesPerRow(resultPixelBuffer),
                                          space: rgbColorSpace,
                                          bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue) else {return nil}
        // This seems to flip the image upside down so just skip
        //            context.translateBy(x: 0, y: height)
        //            context.scaleBy(x: 1.0, y: -1.0)

            let graphicsContext = NSGraphicsContext(cgContext: context, flipped: false)
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = graphicsContext
            draw(in: CGRect(x: 0, y: 0, width: width, height: height))
            NSGraphicsContext.restoreGraphicsState()

            CVPixelBufferUnlockBaseAddress(resultPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))

            return resultPixelBuffer
        }

    var pngData: Data? {
        guard let tiffRepresentation = tiffRepresentation, let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) else { return nil }
        return bitmapImage.representation(using: .png, properties: [:])
    }
}

#endif
