//
//  MainWindow_initConfig.swift
//  DesignWorkspace
//
//  Pipeline stage that stands up the app's UI layer (the main window).
//

import Foundation
import AppKit
import OSLog
import LoggingKit

extension AppManager {

    // MARK: - Platform UI Init

    /// Pipeline stage: create and show the main window (the three-panel UI layer).
    /// Runs on the main thread as part of the SequentialInitializer chain.
    internal func initMainWindow() {
        guard mainWindowController == nil else {
            appInitializer = .stageComplete
            return
        }

        let controller = MainWindowController()
        mainWindowController = controller
        controller.show()

        elog.debug("Main window initialized")
        appInitializer = .stageComplete
    }
}
