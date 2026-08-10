//
//  PreviewLayoutConfig.swift
//  DesignWorkspace
//
//  Created by Dustin Nielson on 8/4/26.
//


import Foundation
import CoreGraphics
import ZoneLayoutGenerator
import LoggingKit

struct PreviewLayoutConfig {
    
    // MARK: - Canvas Presets
    static var squareCanvas = CGSize(width: 3840, height: 3840)
    
    /// Layout:
    /// - baseZone  (zIndex 0): Full-screen base layer (portrait 16:9)
    static func defaultModeLayout(_ size: CGSize) -> [ZoneConfiguration] {
        
        func gcd(_ a: Int, _ b: Int) -> Int {
            var x = a
            var y = b
            while y != 0 {
                let temp = y
                y = x % y
                x = temp
            }
            return x
        }
        
        let ratio = gcd(Int(size.width), Int(size.height))
        
        var zoneId: Int = 0
        var zones: [ZoneConfiguration] = []
        
        let calculatedOrientation: Orientation = size.width > size.height ? .landscape : .portrait
        
        let gap = (abs(size.width - size.height) / 2 ) / max(size.width, size.height) * 100
        
        print("GapSpace \(abs(size.width - size.height))")
        
        repeat { // Doing it this way in case we ever want to change the number of zones.
            
            let zoneConfig = ZoneConfiguration(
                zoneBaseConfig: ZoneConfigOptions(
                    identifier: "zone\(zoneId)",
                    zIndex: zoneId,
                    orientation: calculatedOrientation,
                    renderSafeAspectRatio: (AspectWidth: (size.width / CGFloat(ratio)), AspectHeight: (size.height / CGFloat(ratio))),
                    constraints: calculatedOrientation == .landscape ? ["H:|[zone\(zoneId)]|", "V:|-\(Int(gap.rounded()))-[zone\(zoneId)]"] : ["H:|-\(Int(gap.rounded()))-[zone\(zoneId)]", "V:|[zone\(zoneId)]|"]
                ),
                size: squareCanvas
            )
            
            zones.append(zoneConfig)

            zoneId += 1
            
        } while zoneId <= 2
        
        return zones
        
    }
    
    static func configuration(for size: CGSize) -> ZoneLayoutConfiguration? {
        
        let maxSize = max(size.width, size.height)
        
        squareCanvas = CGSize(width: maxSize, height: maxSize)
        
        let zones = defaultModeLayout(size)
        
        return ZoneLayoutConfiguration(
            name: "default-mode-\(Int(size.width))x\(Int(size.height))",
            identifier: Int64(Date().timeIntervalSince1970 * 1000),
            renderCanvasSize: squareCanvas,
            canvasOrigin: .topLeft,
            zoneConfigurations: zones
        )
    }
}



