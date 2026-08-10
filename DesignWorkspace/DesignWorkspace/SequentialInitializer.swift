//
//  SequentialInitializer.swift
//  MetalPreviewApp
//
//  Created by Dustin Nielson on 6/23/26.
//


import Foundation
import CoreGraphics
import Metal
import OSLog
import LoggingKit

extension AppManager {
    
    // MARK: - Pipeline Definition
    // The stage order is defined here and only here.
    // To add a stage: (1) add enum case, (2) add entry here, (3) add dispatch case below, (4) create config file.
    
    static let initPipeline: [SequentialInitializer] = [
        .displayLinkInit,
        .platformInit
    ]
    
    internal func ExtendedInitializer(from oldState: SequentialInitializer, to newState: SequentialInitializer) throws {
        
        // --- Fatal failure: halt the chain ---
        if newState == .fatalFailure {
            elog.fault("FATAL failure during stage: \(oldState.rawValue) — pipeline halted")
            return
        }

        // --- Recoverable failure: log and advance ---
        if newState == .stageFailure {
            elog.error("Recoverable failure during stage: \(oldState.rawValue) — advancing")
            advanceFromStage(oldState)
            return
        }

        // --- Stage complete: advance to next ---
        if newState == .stageComplete {
            advanceFromStage(oldState)
            return
        }

        // --- Pipeline complete: run post-init hooks ---
        if newState == .pipelineComplete {
            //elog.notice("Pipeline complete — all stages finished")
            onPipelineComplete()
            return
        }

        elog.debug("Running stage: \(newState.rawValue)")
        // --- Dispatch: run the stage function ---
        switch newState {
        case .displayLinkInit:
            initDisplayLink()
            break
        case .platformInit:
            initMainWindow()
            break
        default:
            break
        }
        
    }
    
    // MARK: - Pipeline Advancement

    /// Advance to the next pipeline stage after the current one completes. Fires .pipelineComplete when all stages are done.
    private func advanceFromStage(_ completedStage: SequentialInitializer) {
        guard let currentIndex = Self.initPipeline.firstIndex(of: completedStage) else {
            elog.error("No pipeline entry for stage: \(completedStage.rawValue)")
            return
        }

        let nextIndex = currentIndex + 1
        if nextIndex < Self.initPipeline.count {
            appInitializer = Self.initPipeline[nextIndex]
        } else {
           appInitializer = .pipelineComplete
        }
    }
    
    private func onPipelineComplete() {
        // TODO: - Check preferences for last runtime and set appropriately
        
        
       
    }
    
}

