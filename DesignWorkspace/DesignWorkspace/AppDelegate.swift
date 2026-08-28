//
//  AppDelegate.swift
//  MetalPreviewApp
//
//  Created by Dustin Nielson on 6/23/26.
//

import Cocoa


class AppDelegate: NSObject, NSApplicationDelegate {

    


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // `-ComponentLab` runs the DesignScaffold component lab INSTEAD of the workspace app.
        // Kept as a separate path rather than an extra panel: the lab exists to reproduce
        // gesture and hit-testing behaviour, and the Metal preview pipeline starting up
        // underneath it is one more variable in every measurement.
        if LabWindowController.requested {
            LabWindowController.present()
            return
        }
        // Insert code here to initialize your application
        let appManager = AppManager.shared()
         // This is the actual main application initialization kickoff after appManager is initialized
        appManager.initApp()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }


}

