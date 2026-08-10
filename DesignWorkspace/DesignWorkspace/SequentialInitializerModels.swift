//
//  SequentialInitializerModels.swift
//  MVS Marquee Expo
//
//  Created by Dustin Nielson on 1/13/26.
//

import Foundation

enum SequentialInitializer: String, CustomStringConvertible {

    // MARK: - Control States
    case idle = "idle"
    case stageComplete = "Stage Complete"
    case stageFailure = "Stage Failure (Recoverable)"
    case fatalFailure = "Stage Failure (Fatal)"
    case pipelineComplete = "Pipeline Complete"

    // MARK: - Pipeline Stages
    case metalPipelineInit = "Initializing Metal Pipeline"
    case displayLinkInit = "Initializing Display Link"
    case platformInit = "Initializing Platform UI"
    
    // MARK: - MacOS Pipeline
    case MenuBar = "Initializing Menu Bar"
    case ExternalWindow = "Initializing External Window"
    
    var description: String { rawValue }
}
