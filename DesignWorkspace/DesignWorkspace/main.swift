//
//  main.swift
//  App Bootstrap - No IB
//
//  Created by Dustin Nielson.
//  Copyright (c) 2017 Meru Interactive. All rights reserved.
//

import AppKit

/// When compared to Objective-C example, an `autoreleasepool`
/// is not required because Swift expected to install one automatically.
/// Anyway you can install one if you want to be defensive.

// Entry point — AppKit apps run on the main thread.
//
// main.swift executes on Thread 1 (the main thread) at process start.
// We use MainActor.assumeIsolated to access @MainActor-isolated types
// without triggering Swift 6 concurrency diagnostics.

let app = NSApplication.shared

MainActor.assumeIsolated {
    let delegate = AppDelegate()
    app.delegate = delegate
}

// Keep dock icon visible (comment out to hide)
// app.setActivationPolicy(.accessory)  // Hides the dock icon
app.run()




