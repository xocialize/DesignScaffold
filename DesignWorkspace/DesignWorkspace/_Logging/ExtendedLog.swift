//
//  ExtendedLog.swift
//  Xocialize Metal Preview
//
import OSLog
import LoggingKit

// MARK: - Module-level instance

/// Module-level `MarqueeLog` instance for the Expo app.
/// All files in the app use `mlog` instead of per-file `logger` declarations.
let elog = ExtendedLog(
    logger: Logger(subsystem: "com.xocialize.metal-preview", category: "XocializePreview"),
    projectTag: "XocializePreview"
)
