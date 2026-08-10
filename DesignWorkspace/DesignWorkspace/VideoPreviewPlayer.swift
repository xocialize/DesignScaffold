//
//  VideoPreviewPlayer.swift
//  DesignWorkspace
//
//
//  OPTIMIZATIONS:
//  - Dedicated processing queue for asynchronous buffer operations
//  - Unique identifier for tracking multiple player instances
//  - Loop completion delegate callback for synchronized playback management
//  - Both synchronous and asynchronous buffer checking methods
//
//  METAL COMPATIBILITY:
//  AVPlayerItemVideoOutput MUST include kCVPixelBufferMetalCompatibilityKey: true
//  in its pixelBufferAttributes. Without this, CVPixelBuffers from video frames
//  cannot be converted to MTLTextures via CVMetalTextureCache on iOS. macOS
//  produces Metal-compatible buffers by default, so the omission only manifests
//  as a silent failure on iOS (video plays but frames never render).
//  ImageProcessingKit and CaptureKit already set this flag on their outputs.
//

#if os(iOS) || os(tvOS)
import UIKit
#elseif os(macOS)
import Cocoa
#endif
import AVFoundation
import OSLog
import LoggingKit


public protocol VideoPreviewPlayerDelegate: AnyObject {

    func VideoPlayerBuffer(pixelBuffer: CVPixelBuffer?)
    func videoPlayerDidCompleteLoop(identifier: String)
}

public class VideoPreviewPlayer: NSObject, @unchecked Sendable {

    public weak var delegate: VideoPreviewPlayerDelegate?

    /// Unique identifier for this video player instance
    public let identifier: String

    /// Dedicated queue for video buffer processing to avoid blocking the main render loop
    private let processingQueue: DispatchQueue

    var player:AVPlayer = AVPlayer()
    var playerLooper: AVPlayerLooper?
    var playerItem:AVPlayerItem?

    var videoOutput:AVPlayerItemVideoOutput?
    
    /// Cache the last pixel buffer to avoid returning nil between frames
    private var lastPixelBuffer: CVPixelBuffer?

    /// Stored observer token for AVPlayerItemDidPlayToEndTime notification.
    /// Must be removed in deinit/stopVideo to prevent observer accumulation.
    private var playbackEndObserver: (any NSObjectProtocol)?
    
    public var videoUrl: URL?  {
        didSet{
            guard videoUrl != nil else {
                stopVideo()
                lastPixelBuffer = nil
                return
            }
            loopVideo()
        }
    }
    
    public var playerIsPause:Bool = false {
        didSet {}
    }

    public convenience init(delegate: VideoPreviewPlayerDelegate, identifier: String) {
        self.init(identifier: identifier)
        self.delegate = delegate
        videoPlayerInit()
    }

    public init(identifier: String) {
        self.identifier = identifier
        self.processingQueue = DispatchQueue(
            label: "com.xocialize.videoplayer.\(identifier)",
            qos: .userInteractive,
            attributes: [],
            autoreleaseFrequency: .workItem
        )
        super.init()
    }
    
    deinit {
        if let observer = playbackEndObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    public func videoPlayerInit(){ //self.player.currentItem

        playbackEndObserver = NotificationCenter.default.addObserver(forName: AVPlayerItem.didPlayToEndTimeNotification, object: nil, queue: .main) { [weak self] vidObjItem in

            guard let self = self else { return }
            guard let vItem = vidObjItem.object as? AVPlayerItem else { return }
            if vItem == self.player.currentItem {
                // Notify delegate that playback loop completed
                self.delegate?.videoPlayerDidCompleteLoop(identifier: self.identifier)

                // Restart playback
                self.player.seek(to: CMTime.zero)
                self.player.play()
            }
        }
        
       videoOutput = {
            let attributes = CVPixelBufferAttributes(rawAttributes: [
                String(kCVPixelBufferPixelFormatTypeKey): kCVPixelFormatType_32BGRA,
                String(kCVPixelBufferMetalCompatibilityKey): true  // Required for CVMetalTextureCache on iOS
            ])
            let v = AVPlayerItemVideoOutput(pixelBufferAttributes: attributes)
            return v
        }()
        
        player.volume = 1.0
        
        player.isMuted = false
        
        player.actionAtItemEnd = .none
        
    }
    
    public func loopVideo(){

        guard let videoUrl, let videoOutput else { return }

        // Re-register the playback-end observer if stopVideo() removed it.
        // Without this, videoPlayerDidCompleteLoop never fires after a stop→play cycle.
        if playbackEndObserver == nil {
            playbackEndObserver = NotificationCenter.default.addObserver(forName: AVPlayerItem.didPlayToEndTimeNotification, object: nil, queue: .main) { [weak self] vidObjItem in
                guard let self = self else { return }
                guard let vItem = vidObjItem.object as? AVPlayerItem else { return }
                if vItem == self.player.currentItem {
                    self.delegate?.videoPlayerDidCompleteLoop(identifier: self.identifier)
                    self.player.seek(to: CMTime.zero)
                    self.player.play()
                }
            }
        }

        let videoItem = AVPlayerItem(url: videoUrl)

        videoItem.add(videoOutput)

        videoItem.preferredForwardBufferDuration = TimeInterval(0.5)

        player.replaceCurrentItem(with: videoItem)

        player.seek(to: CMTime.zero)

        player.play()

}
    
    /// Play a pre-composed AVPlayerItem (e.g., from VideoMerge.compose()).
    ///
    /// Attaches the video output for pixel buffer extraction and starts looped playback.
    /// This replaces any currently playing content. The existing loop observer handles
    /// seek-to-zero on completion, and directBufferCheck() works unchanged.
    ///
    /// - Parameter playerItem: An AVPlayerItem, typically from ``VideoMerge/compose(urls:)``
    public func loadMergedVideo(playerItem: AVPlayerItem) {
        if let videoOutput {
            playerItem.add(videoOutput)
        }

        playerItem.preferredForwardBufferDuration = 0.5

        player.replaceCurrentItem(with: playerItem)
        player.seek(to: CMTime.zero)
        player.play()
    }

    public func stopVideo(pausePlayer:Bool = false){
        player.pause()
        player.replaceCurrentItem(with: nil) // We need to do this or we'll get a stray frame during the renderLoop even when the video isn't active.
        lastPixelBuffer = nil
        if let observer = playbackEndObserver {
            NotificationCenter.default.removeObserver(observer)
            playbackEndObserver = nil
        }
    }
    
    
    // This could be called from the render loop instead of the direct methods below.
    public func indirectBufferCheck() {
        guard let videoOutput else {
            
            delegate?.VideoPlayerBuffer(pixelBuffer: lastPixelBuffer)
            return  }
        if videoOutput.hasNewPixelBuffer(forItemTime: player.currentTime()) {
            if let readOnlyBuffer = videoOutput.pixelBufferAndDisplayTime(forItemTime: player.currentTime()).pixelBuffer {
                let pixelBuffer = readOnlyBuffer.withUnsafeBuffer { $0 }
                lastPixelBuffer = pixelBuffer
                delegate?.VideoPlayerBuffer(pixelBuffer: pixelBuffer)
            } else {
                elog.error("indirectBufferCheck: cannot convert pixel buffer")
                delegate?.VideoPlayerBuffer(pixelBuffer: lastPixelBuffer)
            }
        } else {
            delegate?.VideoPlayerBuffer(pixelBuffer: lastPixelBuffer)
        }
    }
    
    /// Direct buffer check - optimized for synchronous calls from render loop
    /// Returns pixel buffer immediately if available, or the last cached buffer if no new frame
    public func directBufferCheck() -> CVPixelBuffer? {
        guard let videoOutput else { return lastPixelBuffer }
        
        let currentTime = player.currentTime()
        
        // Check if there's a new pixel buffer available
        if videoOutput.hasNewPixelBuffer(forItemTime: currentTime) {
            if let readOnlyBuffer = videoOutput.pixelBufferAndDisplayTime(forItemTime: currentTime).pixelBuffer {
                let pixelBuffer = readOnlyBuffer.withUnsafeBuffer { $0 }
                // Cache the new buffer and return it
                lastPixelBuffer = pixelBuffer
                return pixelBuffer
            } else {
                elog.error("directBufferCheck [\(self.identifier)]: cannot convert pixel buffer")
                // Return cached buffer as fallback
                return lastPixelBuffer
            }
        } else {
            // No new buffer available, return the cached one
            return lastPixelBuffer
        }
    }

    /// Asynchronous buffer check using dedicated processing queue
    /// Calls completion handler with pixel buffer on the processing queue
    public func asyncBufferCheck(completion: @escaping @Sendable (CVPixelBuffer?) -> Void) {
        processingQueue.async { [weak self] in
            guard let self = self else {
                completion(nil)
                return
            }
            guard let videoOutput = self.videoOutput else {
                completion(nil)
                return
            }
            let currentTime = self.player.currentTime()
            if videoOutput.hasNewPixelBuffer(forItemTime: currentTime) {
                if let readOnlyBuffer = videoOutput.pixelBufferAndDisplayTime(forItemTime: currentTime).pixelBuffer {
                    let pixelBuffer = readOnlyBuffer.withUnsafeBuffer { $0 }
                    completion(pixelBuffer)
                } else {
                    elog.error("asyncBufferCheck [\(self.identifier)]: cannot convert pixel buffer")
                    completion(nil)
                }
            } else {
                completion(nil)
            }
        }
    }
}



