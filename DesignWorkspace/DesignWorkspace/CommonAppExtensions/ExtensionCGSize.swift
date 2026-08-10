//
//  ExtensionCGSize.swift
//  MVS Marquee Expo iOS
//
//  Created by Dustin Nielson on 2/25/26.
//

import CoreGraphics

extension CGSize {
    func aspectRatio() -> CGSize {
        func aspectRatio(width: Int, height: Int) -> (Int, Int) {
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

            let divisor = gcd(width, height)
            return (width / divisor, height / divisor)
        }

        // Example:
        let (rw, rh) = aspectRatio(width: Int(self.width), height: Int(self.height))
        

        return CGSize(width: rw, height: rh)
    }
}
