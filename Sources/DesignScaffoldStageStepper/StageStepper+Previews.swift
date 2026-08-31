//
//  ⚠️ macOS-only, and only because `@Previewable` is iOS 17+. This is DEVELOPMENT code —
//  guarding it keeps the package's iOS floor at 16, where the SHIPPING code actually sits,
//  instead of letting a preview macro set the floor for every consumer. See Docs/PLATFORMS.md.
//
#if os(macOS)

//  StageStepper+Previews.swift
//  Canvas gallery for the stepper. No theme calls: the scaffold look IS the default.

import DesignScaffold
import SwiftUI

private let sixNodePlan = [
    StageNode(id: "prompt", title: "Read prompt", detail: "Encoding the prompt"),
    StageNode(id: "generate", title: "Generate", detail: "Denoising"),
    StageNode(id: "upscale", title: "Upscale", detail: "Raising resolution"),
    StageNode(id: "refine", title: "Refine", detail: "Second pass at full resolution"),
    StageNode(id: "decode", title: "Render frames", detail: "Decoding frames",
              slowHint: "this step often takes the longest"),
    StageNode(id: "finish", title: "Finish", detail: "Writing the file"),
]

#Preview("Mid-run with counters") {
    StageStepper(progress: StageProgress(
        nodes: sixNodePlan, currentIndex: 1,
        counterText: "step 5 of 8 · pass 1 of 2", elapsedInNode: 42))
        .padding(Tokens.Space.l)
        .cardSurface()
        .padding(Tokens.Space.xl)
        .frame(width: 720)
}

#Preview("Quiet slow node — liveness affordance") {
    StageStepper(progress: StageProgress(
        nodes: sixNodePlan, currentIndex: 4, elapsedInNode: 195))
        .padding(Tokens.Space.l)
        .cardSurface()
        .padding(Tokens.Space.xl)
        .frame(width: 720)
}

#Preview("Before the run — plan drawn, nothing lit") {
    StageStepper(progress: StageProgress(nodes: sixNodePlan))
        .padding(Tokens.Space.l)
        .cardSurface()
        .padding(Tokens.Space.xl)
        .frame(width: 720)
}

#Preview("Complete, dark") {
    StageStepper(progress: StageProgress(
        nodes: sixNodePlan, currentIndex: sixNodePlan.count))
        .padding(Tokens.Space.l)
        .cardSurface()
        .padding(Tokens.Space.xl)
        .frame(width: 720)
        .preferredColorScheme(.dark)
}

#endif
