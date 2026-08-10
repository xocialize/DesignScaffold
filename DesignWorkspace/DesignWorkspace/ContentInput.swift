//
//  ContentInput.swift
//  DesignWorkspace
//
//  Entry point for content the user provides via the preview drop zone.
//

import Foundation
import AppKit
import UniformTypeIdentifiers
import LoggingKit
import MetalToolBox

extension AppManager {

    // MARK: - Content Input

    /// Called when the user selects or drops a content file in the preview drop
    /// zone (drag-and-drop from Finder or the "Choose File…" picker).
    ///
    /// This is the seam between the UI layer and the render pipeline: the file
    /// will eventually be loaded and processed into an `MTLTexture` handed to the
    /// Metal display zone (see `metalView` / `layer0Texture`). For now it just logs.
    func didSelectContentFile(at url: URL) {
        elog.debug("Content file selected: \(url.lastPathComponent) — \(url.path)")
        
        guard isVideoURL(url) || isImageURL(url) else {
            elog.warning("Unsupported file type: \(url.pathExtension)")
            return
        }
        
        if let image = NSImage(contentsOf: url) {
            elog.debug("Loaded image size: \(image.size)")
            guard let imageBuffer = image.pixelBuffer() else {
                return
            }
            
            layer0Texture = textureConverter?.convert(imageBuffer)
            
        } else {
            
        }
        
        
        
        
        // TODO: load the file, process it, and display the result as a texture in
        // the Metal display zone.
    }
    
    func isVideoURL(_ url: URL) -> Bool {
        // Ensure the URL is a file or has a path extension
        guard !url.pathExtension.isEmpty else { return false }
        
        // Get the UTType for the file extension
        if let fileType = UTType(filenameExtension: url.pathExtension.lowercased()) {
            return fileType.conforms(to: .movie) // .movie covers most video formats
        }
        
        return false
    }
    
    func isImageURL(_ url: URL) -> Bool {
        // Ensure the URL is a file or has a path extension
        guard !url.pathExtension.isEmpty else { return false }
        
        // Get the UTType for the file extension
        if let fileType = UTType(filenameExtension: url.pathExtension.lowercased()) {
            return fileType.conforms(to: .image) // .movie covers most video formats
        }
        
        return false
    }
}
