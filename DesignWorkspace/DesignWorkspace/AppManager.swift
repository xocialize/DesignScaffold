//
//  AppManager.swift
//  MetalPreviewApp
//
//  Created by Dustin Nielson on 6/23/26.
//

import Foundation
import AppKit
import Metal
import OSLog
import LoggingKit
import MetalToolBox
import TextureCompositorEngine
import ZoneLayoutGenerator

class AppManager: NSObject {
    
    internal var appInitializer: SequentialInitializer = .idle {
        didSet {
            if appInitializer != .stageComplete {
                elog.debug("App Initializer changed to: \(self.appInitializer.rawValue)")
            }
            do {
                try ExtendedInitializer(from: oldValue, to: appInitializer)
            } catch {
                elog.error("ExtendedInitializer failed: \(error.localizedDescription)")
                appInitializer = .fatalFailure
            }
        }
    }
    
    // MARK: - Metal References
    
    var metalDevice = MTLCreateSystemDefaultDevice()
    var metalCommandQueue: MTLCommandQueue?
    var shaderLibrary: MTLLibrary?
    weak var metalView: EnhancedMetalView?
    
    var textureConverter: TextureConverter?
    
    var compositeEngine: TextureCompositorEngine?
    
    // MARK: - UI Layer
    
    /// Owns the main window (the three-panel UI layer). Created by `.platformInit`.
    var mainWindowController: MainWindowController?
    
    var canvasSize: CGSize = CGSize(width: 800, height: 800) {
        didSet {
            
        }
    }
    
    // MARK: - Flexible Layout Engine / Topology
    
    /// Lock for thread-safe texture access (pixel buffers can come from background queues)
    private let textureLock = NSLock()
    
    var _layer0Texture: MTLTexture? {
        didSet {
            guard let _layer0Texture else { return }
            if oldValue?.width != _layer0Texture.width || oldValue?.height != _layer0Texture.height {
                updateCanvasSize(size: CGSize(width: _layer0Texture.width, height: _layer0Texture.height))
            }
            
        }
    }
    var layer0Texture: MTLTexture? {
        get { textureLock.lock(); defer { textureLock.unlock() }; return _layer0Texture }
        set { textureLock.lock(); _layer0Texture = newValue; textureLock.unlock() }
        
    }
    
    
    // MARK: - DisplayLink (→ DisplayLink_initConfig.swift)
    
    internal var displayLink: CADisplayLink!
    internal var displayLinkRetryCount = 0
    internal let maxDisplayLinkRetries = 10
    
    // MARK: - Singleton
    
    private static var _shared: AppManager?
    private static let lock = NSLock()
    
    /// Thread-safe singleton accessor. Uses NSLock to guard first-time creation.
    static func shared() -> AppManager {
        lock.lock()
        defer { lock.unlock() }
        if _shared == nil {
            _shared = AppManager()
        }
        return _shared!
    }
    
    /// Resolves the Metal device and default shader library. Called once from shared().
    private override init() {
        super.init()
        
        guard let device = metalDevice else {
            elog.fault("No Metal device available")
            return
        }

        guard let shaderLib = EnhancedShaderLibrary(device: device) else {
            elog.fault("Failed to load Metal shader library from app or package bundle")
            return
        }

        shaderLibrary = shaderLib.library

        // 2. Create shared Metal command queue (used by TCE + all EnhancedMetalViews)
        metalCommandQueue = device.makeCommandQueue()

        // 3. Create texture converter and animators (shared across zones)
        textureConverter = TextureConverter(device: device)


        // 4. Create composite engine (TextureCompositorEngine — layout + compositing)
        compositeEngine = TextureCompositorEngine(device: device, shaderLibrary: shaderLibrary, commandQueue: metalCommandQueue)

        // 5. The metal view itself is NOT created here. `metalView` is a `weak`
        // reference, so anything created here would deallocate immediately — its
        // only strong owner must be the on-screen view hierarchy. It is built and
        // mounted lazily by `makeMetalView()` (see `MetalPreviewView`).
        elog.debug("Metal Infrastructure Initialized")
    }

    /// Builds the shared Metal render surface and stores a `weak` reference to it.
    ///
    /// The caller is responsible for installing the returned view into a view
    /// hierarchy that retains it; `AppManager` deliberately holds it only weakly
    /// so it lives exactly as long as it is on screen. `renderLoop` pushes frames
    /// into it via `displayTexture` for as long as the weak reference is alive.
    func makeMetalView() -> EnhancedMetalView? {
        guard let device = metalDevice, let shaderLibrary, let metalCommandQueue else {
            elog.fault("makeMetalView — Metal infrastructure is not initialized")
            return nil
        }
        let emv = EnhancedMetalView(device: device, shaderLibrary: shaderLibrary, commandQueue: metalCommandQueue)
        emv.translatesAutoresizingMaskIntoConstraints = false
        metalView = emv
        return emv
    }
    
    func initApp() {
        // ⚠️ Was `appInitializer = .displayLinkInit`, a hardcoded first stage — which quietly contradicted
        // `SequentialInitializer.initPipeline`'s own comment that "the stage order is defined here and only
        // here". Reordering the pipeline array had no effect, and a stage added at the front never ran at
        // all. Taking the first element from the pipeline makes that comment true.
        guard let first = Self.initPipeline.first else {
            elog.error("initApp — the init pipeline is empty; nothing to run")
            appInitializer = .pipelineComplete
            return
        }
        appInitializer = first
    }
    
    func updateCanvasSize(size: CGSize) {
        guard let compositeEngine else { return }

        
        let maxSize = max(size.width, size.height)
        canvasSize = CGSize(width: maxSize, height: maxSize)
        guard let layoutConfig = PreviewLayoutConfig.configuration(for: size) else { return }
        
        elog.debug("canvasSize: \(canvasSize)")
        elog.debug("LayoutConfig: \(layoutConfig)")
        
        compositeEngine.updateCanvasSize(canvasSize)
        compositeEngine.configureZones(layoutConfig.zoneConfigurations)
        compositeEngine.updateLayoutConfig()
        
    }
    
    // MARK: - Render Loop
    @objc internal func renderLoop() {
        autoreleasepool {
            
//            guard let metalView else {
//                print(metalView as Any)
//                return
//            }
            
            guard let compositeEngine, let textureConverter, let metalView, let _ = metalCommandQueue, let _ = layer0Texture else {
                //elog.debug("renderLoop: skipping frame \(String(describing: metalView))")
                return
            }
            // Flush stale texture cache entries from prior frames
            textureConverter.flush()
            compositeEngine.flushTextureCache()
            
            // Add textures for render
            let zoneList = [layer0Texture]
            var loopId = 0
            for zone in zoneList {
                if zone != nil, let texture = zone {
                    compositeEngine.setZoneTexture(texture, forZone: "zone\(loopId)")
                } else {
                    compositeEngine.clearZoneTexture(forZone: "zone\(loopId)")
                }
                loopId += 1
            }

            compositeEngine.render()
            if let output = compositeEngine.outputTexture {
                // Display consumer (may be absent on headless signage boxes).
                metalView.displayTexture = output
            }
            
        }
    }
    
}
