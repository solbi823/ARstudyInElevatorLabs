//
//  addGIF.swift
//  GifInSceneKit
//
//  Created by 최솔비 on 2018. 7. 23..
//  Copyright © 2018년 최솔비. All rights reserved.
//

import Foundation
import UIKit
import SceneKit
import ARKit


func addGIF(fileName: String, imageSize : Int) -> SCNNode{
    
    guard let url = Bundle.main.url(forResource: fileName, withExtension: "gif")else {
        print("@@@@@@@@@@@@@@@@no file")
        let node = SCNNode(geometry: nil)
        return node
    }
    
    let animation = createGIFAnimation(url: url)
    
    let layer = CALayer()
    
    layer.bounds = CGRect(x: 0, y: 0,
                          width : (animation?.values![0] as! CGImage).width * imageSize,
                          height : (animation?.values![0] as! CGImage).height * imageSize)
    layer.add(animation!, forKey: "contents")
    layer.bounds.size = layer.frame.size
    
    let tempView = UIView.init(frame : CGRect(x: 0, y:0 , width:1000, height : 1000))
    tempView.layer.bounds = CGRect(x: -500, y:-500 , width: tempView.frame.size.width, height: tempView.frame.size.height)
    tempView.backgroundColor = UIColor(white: 1, alpha: 0)
    tempView.layer.addSublayer(layer)
    
    let newMaterial = SCNMaterial()
    newMaterial.isDoubleSided = true
    newMaterial.diffuse.contents = tempView.layer
    
    let plane = SCNPlane(width: 2, height: 2)
    plane.materials = [newMaterial]
    let node = SCNNode(geometry: plane)
    
    return node
    
}


func createGIFAnimation(url:URL) -> CAKeyframeAnimation?{
    
    guard let src = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
    let frameCount = CGImageSourceGetCount(src)
    
    // Total loop time
    var time : Float = 0
    
    // Arrays
    var framesArray = [AnyObject]()
    var tempTimesArray = [NSNumber]()
    
    // Loop
    for i in 0..<frameCount {
        
        // Frame default duration
        var frameDuration : Float = 0.1;
        
        let cfFrameProperties = CGImageSourceCopyPropertiesAtIndex(src, i, nil)
        guard let framePrpoerties = cfFrameProperties as? [String:AnyObject] else {return nil}
        guard let gifProperties = framePrpoerties[kCGImagePropertyGIFDictionary as String] as? [String:AnyObject]
            else { return nil }
        
        // Use kCGImagePropertyGIFUnclampedDelayTime or kCGImagePropertyGIFDelayTime
        if let delayTimeUnclampedProp = gifProperties[kCGImagePropertyGIFUnclampedDelayTime as String] as? NSNumber {
            frameDuration = delayTimeUnclampedProp.floatValue
        }
        else{
            if let delayTimeProp = gifProperties[kCGImagePropertyGIFDelayTime as String] as? NSNumber {
                frameDuration = delayTimeProp.floatValue
            }
        }
        
        // Make sure its not too small
        if frameDuration < 0.011 {
            frameDuration = 0.100;
        }
        
        
        // Add frame to array of frames
        if let frame = CGImageSourceCreateImageAtIndex(src, i, nil) {
            tempTimesArray.append(NSNumber(value: frameDuration))
            framesArray.append(frame)
        }
        
        // Compile total loop time
        time = time + frameDuration
    }
    
    var timesArray = [NSNumber]()
    var base : Float = 0
    for duration in tempTimesArray {
        timesArray.append(NSNumber(value: base))
        base = base + ( duration.floatValue / time )
    }
    
    // From documentation of 'CAKeyframeAnimation':
    // the first value in the array must be 0.0 and the last value must be 1.0.
    // The array should have one more entry than appears in the values array.
    // For example, if there are two values, there should be three key times.
    timesArray.append(NSNumber(value: 1.0))
    
    // Create animation
    let animation = CAKeyframeAnimation(keyPath: "contents")
    
    animation.beginTime = AVCoreAnimationBeginTimeAtZero
    animation.duration = CFTimeInterval(time)
    animation.repeatCount = Float.greatestFiniteMagnitude;
    animation.isRemovedOnCompletion = false
    animation.fillMode = kCAFillModeForwards
    animation.values = framesArray
    animation.keyTimes = timesArray
    //animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
    animation.calculationMode = kCAAnimationDiscrete
    
    
    return animation;
}



