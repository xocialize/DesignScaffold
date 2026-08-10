//
//  AppDelegate.swift
//  MetalPreviewApp
//
//  Created by Dustin Nielson on 6/23/26.
//

import Cocoa


class AppDelegate: NSObject, NSApplicationDelegate {

    


    func applicationDidFinishLaunching(_ aNotification: Notification) {
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

