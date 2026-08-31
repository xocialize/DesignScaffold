//
//  ⚠️ macOS-only. This target is wrapped in `#if os(macOS)` because it is built on AppKit
//  API with no iOS equivalent — see `Docs/PLATFORMS.md`. On iOS the module compiles to
//  nothing, so an app that adds this product by mistake gets "cannot find X in scope"
//  rather than a wall of AppKit errors, and the package as a whole still builds.
//
#if os(macOS)

//  Exports.swift
@_exported import DesignScaffold

#endif
