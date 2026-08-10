//
//  ZoneLayoutConfig.swift
//  DesignWorkspace
//
//  Created by Dustin Nielson on 8/4/26.
//


import Foundation
import CoreGraphics
import ZoneLayoutGenerator
import LoggingKit

struct ZoneLayoutConfig {
    
    // MARK: - Canvas Presets

    static let landscapeCanvas = CGSize(width: 3840, height: 2160)
    static let portraitCanvas = CGSize(width: 2160, height: 3840)
    static let squareCanvas = CGSize(width: 3840, height: 3840)
    
    /// Layout:
    /// - baseZone  (zIndex 0): Full-screen base layer (portrait 16:9)
    static func defaultModeLayout(orientation: Orientation) -> [ZoneConfiguration] {
        
        let canvasSize = orientation == .landscape ? landscapeCanvas : portraitCanvas
        
        var zoneId: Int = 0
        var zones: [ZoneConfiguration] = []
        
        repeat { // Doing it this way in case we ever want to change the number of zones.
            
            let zoneConfig = ZoneConfiguration(
                zoneBaseConfig: ZoneConfigOptions(
                    identifier: "zone\(zoneId)",
                    zIndex: zoneId,
                    orientation: .init(rawValue: orientation.rawValue) ?? .landscape,
                    renderSafeAspectRatio: orientation == .landscape
                        ? (AspectWidth: 16, AspectHeight: 9)
                        : (AspectWidth: 9, AspectHeight: 16),
                    constraints: ["H:|[zone\(zoneId)]|", "V:|[zone\(zoneId)]|"]
                ),
                size: canvasSize
            )
            
            zones.append(zoneConfig)

            zoneId += 1
            
        } while zoneId <= 3
        
        var screenZoneConstraints = orientation == .landscape ? ["H:|[zone\(zoneId)]|", "V:[zone\(zoneId)]-3-|"] : ["H:|[zone\(zoneId)]|", "V:[zone\(zoneId)]-3-|"]
        
        // Screen Zone: Screen capture PIP — capture content is always landscape aspect
        let screenZone = ZoneConfiguration(
            zoneBaseConfig: ZoneConfigOptions(
                identifier: "zone\(zoneId)",
                zIndex: zoneId,
                orientation: canvasSize.width > canvasSize.height ? .landscape : .portrait,
                renderSafeAspectRatio: (AspectWidth: 16, AspectHeight: 9), // TODO: Use the aspect ratio from the main screen size for dynamic edge to edge fit
                constraints: screenZoneConstraints
            ),
            size: canvasSize
        )
        
        //mlog.debug("ScreenZone \(screenZone)")
        
        zones.append(screenZone)
        
        zoneId += 1
        
        // PIP Zone: Playlist or device content — positioned above screenZone
        let pipZone = ZoneConfiguration(
            zoneBaseConfig: ZoneConfigOptions(
                identifier: "zone\(zoneId)",
                zIndex: zoneId,
                orientation: canvasSize.width > canvasSize.height ? .landscape : .portrait,
                renderSafeAspectRatio: (AspectWidth: 16, AspectHeight: 9),
                constraints: ["H:|[zone\(zoneId)]|","V:[zone\(zoneId)]-2-[zone\(zoneId - 1)]|"]
            ),
            size: canvasSize
        )
        
        elog.debug("pipZone \(pipZone)")
        
        zones.append(pipZone)
        
        zoneId += 1
        
        screenZoneConstraints = orientation == .landscape ? ["H:|[zone\(zoneId)]|", "V:[zone\(zoneId)]-20-|"] : ["H:|[zone\(zoneId)]|", "V:[zone\(zoneId)]-20-|"]
        
        // Screen Zone: Screen capture PIP — capture content is always landscape aspect
        let screenSoloZone = ZoneConfiguration(
            zoneBaseConfig: ZoneConfigOptions(
                identifier: "zone\(zoneId)",
                zIndex: zoneId,
                orientation: canvasSize.width > canvasSize.height ? .landscape : .portrait,
                renderSafeAspectRatio: (AspectWidth: 16, AspectHeight: 9), // TODO: Use the aspect ratio from the main screen size for dynamic edge to edge fit
                constraints: screenZoneConstraints
            ),
            size: canvasSize
        )
        
        //mlog.debug("ScreenSoloZone \(screenZone)")
        
        zones.append(screenSoloZone)
        
        return zones
        
    }
    
    static func aspectRatio(size: CGSize){
//        
//        func gcd<T: BinaryInteger>(_ a: T, _ b: T) -> T {
//            b == 0 ? a : gcd(b, a % b)
//        }
//        
//        let ratio = gcd(Int(size.width), Int(size.height))
        
        
        /*
         
         const aspectRatio = computed(() => {
           const gcd = (a, b) => {
             return b == 0 ? a : gcd(b, a % b);
           };

           // const workingWidth = props.width ? props.width : props.orientation === 'portrait' ? '1080' : '1920';
           //const workingHeight = props.height ? props.height : props.orientation === 'portrait' ? '1920' : '1080';

           const w = workingSize.value.width;
           const h = workingSize.value.height;
           const r = gcd(w, h);
           const aspectRatioCalculated = {
             aspectWidth: w / r,
             aspectHeight: h / r,
           };

           return {
             width: workingSize.value.width,
             height: workingSize.value.height,
             aspectWidth: aspectRatioCalculated.aspectWidth,
             aspectHeight: aspectRatioCalculated.aspectHeight,
           };
         });

         const maxWidth = ref(0);
         const maxHeight = ref(0);

         const aspectFit = computed(() => {
           // Stackoverflow: https://stackoverflow.com/questions/6565703/math-algorithm-fit-image-to-screen-retain-aspect-ratio
           // prep

           const imgWidth = aspectRatio.value.width;
           const imgHeight = aspectRatio.value.height;

           // calc
           const widthRatio = maxWidth.value / imgWidth;
           const heightRatio = maxHeight.value / imgHeight;

           const bestRatio = Math.min(widthRatio, heightRatio);

           // output
           const newWidth = imgWidth * bestRatio;
           const newHeight = imgHeight * bestRatio;

           const asp = {
             scale: `scale(${bestRatio})`,
             width: `${aspectRatio.value.width}px`,
             height: `${aspectRatio.value.height}px`,
             containerWidth: `${newWidth}px`,
             containerHeight: `${newHeight}px`,
           };
           return asp;
         });
         
         */
    }
    
    /// Config:  Allows for simple changeover of layouts
    static func mainZoneConfiguration(canvasSize: CGSize = landscapeCanvas, zoneConfigurations: [ZoneConfiguration]) -> ZoneLayoutConfiguration {

        return ZoneLayoutConfiguration(
            name: "default-mode-\(Int(canvasSize.width))x\(Int(canvasSize.height))",
            identifier: Int64(Date().timeIntervalSince1970 * 1000),
            renderCanvasSize: canvasSize,
            canvasOrigin: .topLeft,
            zoneConfigurations: zoneConfigurations
        )

    }

    /// Convenience: build the full default mode configuration for a given orientation.
    static func configuration(for orientation: Orientation) -> ZoneLayoutConfiguration {
        let canvasSize = orientation == .landscape ? landscapeCanvas : portraitCanvas
        let zones = defaultModeLayout(orientation: orientation)
        return mainZoneConfiguration(canvasSize: canvasSize, zoneConfigurations: zones)
    }
}


