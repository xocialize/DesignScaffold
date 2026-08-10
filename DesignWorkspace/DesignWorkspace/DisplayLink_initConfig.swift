//
//  DisplayLink_initConfig.swift
//  MVS Marquee Expo
//
//  Created by Dustin Nielson on 2/10/26.
//

import Foundation
import QuartzCore
import OSLog
import LoggingKit
#if os(macOS)
import Cocoa
#endif


extension AppManager {
    
    // MARK: - Display Link Init
    
    /// Pipeline stage 1: Create a CADisplayLink tied to the main screen's refresh rate.
    /// On macOS, retries up to 10 times if no screen is available (headless server). Fires renderLoop() each frame.
    internal func initDisplayLink() {
#if os(macOS)
        guard displayLink == nil, NSScreen.screens.count > 0 else {
            return
        }
        
        let screen = NSScreen.main
        
        if let screen = screen {
            displayLink = screen.displayLink(target: self, selector: #selector(renderLoop))
            
            displayLink?.preferredFrameRateRange = CAFrameRateRange(minimum: 20, maximum: 120, preferred: 60)
            displayLink?.add(to: .main, forMode: .common)
            displayLinkRetryCount = 0
            
        } else if displayLinkRetryCount < maxDisplayLinkRetries {
            displayLinkRetryCount += 1
            elog.debug("No screen available for display link, retry \(self.displayLinkRetryCount)/\(self.maxDisplayLinkRetries)")
            self.perform(#selector(retryDisplayLink), with: nil, afterDelay: 0.2)
        } else {
            elog.error("Failed to create display link after \(self.maxDisplayLinkRetries) retries")
        }
#else
        guard displayLink == nil else { return }
        displayLink = CADisplayLink(target: self, selector: #selector(renderLoop))
        
        guard let displayLink else { return }
        
        displayLink.add(to: .current, forMode: .default)
#endif
        appInitializer = .stageComplete
    }
    
    /// Remove the display link from the run loop and invalidate it. Called during shutdown or pipeline rebuild.
    internal func deinitDisplayLink() {
        guard let _ = displayLink else { return }
        displayLink.isPaused = false
        displayLink.remove(from: .main, forMode: .common)
        displayLink.invalidate()
        displayLink = nil
    }
    
    /// Retry display link creation after a 200ms delay when NSScreen.main is nil (macOS headless startup).
    @objc internal func retryDisplayLink() {
        initDisplayLink()
    }
    
}
