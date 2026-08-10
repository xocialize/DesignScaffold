//
//  ExtensionUIView.swift
//  MeruSignage
//
//  Created by Dustin Nielson on 5/31/22.
//


import Foundation

#if os(iOS) || os(tvOS)
import UIKit
extension UIView  {
    func rotate(angle: Float) {
        self.transform = CGAffineTransform(rotationAngle: CGFloat(angle * .pi/180)); //iOS
        //self.rotate(byDegrees: CGFloat(angle * .pi/180)) //macOS
    }
    
    func addConstraintsWithFormat(format: String, views: UIView...){
        var viewsDictionary = [String: UIView]()
        for(index,view) in views.enumerated(){
            let key = "v\(index)"
            view.translatesAutoresizingMaskIntoConstraints = false
            viewsDictionary[key] = view
        }
        
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: format, options: NSLayoutConstraint.FormatOptions(), metrics: nil, views: viewsDictionary))
    }
    
    func createConstraintsWithFormat(format: String, views: UIView..., options:NSLayoutConstraint.FormatOptions = NSLayoutConstraint.FormatOptions()) -> [NSLayoutConstraint] {
        var viewsDictionary = [String: UIView]()
        for(index,view) in views.enumerated(){
            let key = "v\(index)"
            view.translatesAutoresizingMaskIntoConstraints = false
            viewsDictionary[key] = view
        }
        
        return NSLayoutConstraint.constraints(withVisualFormat: format, options: options, metrics: nil, views: viewsDictionary)
    }
    
    func fadeIn(_ duration: TimeInterval = 1, delay: TimeInterval = 0.0, completion: @escaping ((Bool) -> Void) = {(finished: Bool) -> Void in}) {
        
        DispatchQueue.main.async {
            if self.alpha != 1.0 {
                UIView.animate(withDuration: duration, delay: delay, options: UIView.AnimationOptions.curveEaseIn, animations: {
                    self.alpha = 1.0
                }, completion: completion)
            }
        }
    }
    
    
    func fadeOut(_ duration: TimeInterval = 1, delay: TimeInterval = 0.0, completion: @escaping (Bool) -> Void = {(finished: Bool) -> Void in}) {
        
        DispatchQueue.main.async {
            if self.alpha != 0.0 {
                UIView.animate(withDuration: duration, delay: delay, options: UIView.AnimationOptions.curveEaseIn, animations: {
                    self.alpha = 0
                }, completion: completion)
            }
        }
    }
    
    /// Get `Data` representation of the view.
    ///
    /// - Parameters:
    ///   - fileType: The format of file. Defaults to PNG.
    /// - Returns: `Data` for image.
    
    func data(fileType: String = "png") -> Data? {
        // Create a renderer with the view's bounds
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        
        // Render the view into an image
        let image = renderer.image { context in
            layer.render(in: context.cgContext)
        }
        
        // Convert to the appropriate data format
        switch fileType.lowercased() {
        case "png":
            return image.pngData()
        case "jpg", "jpeg":
            return image.jpegData(compressionQuality: 1.0)
        default:
            return image.pngData()
        }
    }
}
#elseif os(macOS)
import Cocoa
extension NSView {
    
    func rotate(angle: Float) {
        // Convert angle from degrees to radians
        let radians = CGFloat(angle * .pi / 180)
        
        // Ensure the view has a layer
        self.wantsLayer = true
        
        // Set anchor point to center for proper rotation
        let newAnchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        // Calculate the position adjustment needed when changing anchor point
        let oldOrigin = self.frame.origin
        self.layer?.anchorPoint = newAnchorPoint
        let newOrigin = self.frame.origin
        
        // Adjust frame to maintain visual position
        var frame = self.frame
        frame.origin.x -= (newOrigin.x - oldOrigin.x)
        frame.origin.y -= (newOrigin.y - oldOrigin.y)
        self.frame = frame
        
        // Apply the rotation transform
        self.layer?.transform = CATransform3DMakeRotation(radians, 0, 0, 1)
    }
    
    func animatedRotate(angle: Float) {
        let newAnchorPoint = CGPoint(x: 0.5, y: 0.5)
        self.layer?.anchorPoint = newAnchorPoint
                
        // Prevent the anchor point from modifying views location on screen
        var position = self.layer!.position
        position.x += self.bounds.maxX * newAnchorPoint.x
        position.y += self.bounds.maxY * newAnchorPoint.y
        self.layer?.position = position

        // Configure the animation
        let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotateAnimation.byValue = 2 * CGFloat.pi
        rotateAnimation.duration = 2;

        // Trigger the animation
        CATransaction.begin()
        self.layer?.add(rotateAnimation, forKey: "rotate")
        CATransaction.setCompletionBlock {
            // Handle animation completion
        }
        CATransaction.commit()
    }
    /*
     H: (Horizontal) //horizontal direction
     V: (Vertical) //vertical direction
     | (pipe) //superview
     - (dash) //standard spacing (generally 8 points)
     [] (brackets) //name of the object (uilabel, unbutton, uiview, etc.)
     () (parentheses) //size of the object
     == equal widths //can be omitted
     -16- non standard spacing (16 points)
     <= less than or equal to
     >= greater than or equal to
     @250 priority of the constraint //can have any value between 0 and 1000
     */
    func addConstraintsWithFormat(format: String, views: NSView..., options:NSLayoutConstraint.FormatOptions = NSLayoutConstraint.FormatOptions()){
        var viewsDictionary = [String: NSView]()
        for(index,view) in views.enumerated(){
            let key = "v\(index)"
            view.translatesAutoresizingMaskIntoConstraints = false
            viewsDictionary[key] = view
        }
        
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: format, options: options, metrics: nil, views: viewsDictionary))
    }
    
    func createConstraintsWithFormat(format: String, views: NSView..., options:NSLayoutConstraint.FormatOptions = NSLayoutConstraint.FormatOptions()) -> [NSLayoutConstraint] {
        var viewsDictionary = [String: NSView]()
        for(index,view) in views.enumerated(){
            let key = "v\(index)"
            view.translatesAutoresizingMaskIntoConstraints = false
            viewsDictionary[key] = view
        }
        
        return NSLayoutConstraint.constraints(withVisualFormat: format, options: options, metrics: nil, views: viewsDictionary)
    }
    
    func centerConstraints(subView: NSView) {
        subView.translatesAutoresizingMaskIntoConstraints = false
        
        // Center horizontally
        let centerXConstraint = NSLayoutConstraint(
            item: subView,
            attribute: .centerX,
            relatedBy: .equal,
            toItem: self,
            attribute: .centerX,
            multiplier: 1.0,
            constant: 0
        )
        
        // Center vertically
        let centerYConstraint = NSLayoutConstraint(
            item: subView,
            attribute: .centerY,
            relatedBy: .equal,
            toItem: self,
            attribute: .centerY,
            multiplier: 1.0,
            constant: 0
        )
        
        self.addConstraints([centerXConstraint, centerYConstraint])
    }
    
    func fadeViewIn(){
        self.isHidden = false
        self.alphaValue = 0
        NSAnimationContext.runAnimationGroup({_ in
            //Indicate the duration of the animation
            NSAnimationContext.current.duration = 1.0
            //What is being animated? In this example I’m making a view transparent
            self.animator().alphaValue = 1.0
        }, completionHandler:{
            self.isHidden = false
        })
    }
    
    func fadeViewOut(){
        guard ( self.isHidden == false ) || ( self.alphaValue > 0 ) else { return }
        self.alphaValue = 1
        self.isHidden = false
        NSAnimationContext.runAnimationGroup({_ in
            //Indicate the duration of the animation
            NSAnimationContext.current.duration = 1.0
            //What is being animated? In this example I’m making a view transparent
            self.animator().alphaValue = 0
        }, completionHandler:{
            self.isHidden = true
        })
    }
    
    /// Get `Data` representation of the view.
    ///
    /// - Parameters:
    ///   - fileType: The format of file. Defaults to PNG.
    ///   - properties: A dictionary that contains key-value pairs specifying image properties.
    /// - Returns: `Data` for image.
    
    func data(using fileType: NSBitmapImageRep.FileType = .png, properties: [NSBitmapImageRep.PropertyKey  : Any] = [:]) -> Data {
        let imageRepresentation = bitmapImageRepForCachingDisplay(in: bounds)!
        cacheDisplay(in: bounds, to: imageRepresentation)
        return imageRepresentation.representation(using: fileType, properties: properties)!
    }
    
}
#endif




