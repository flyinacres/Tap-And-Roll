//
//  Die.swift
//  TapAndRoll
//
//  Created by Ronald Fischer on 10/26/15.
//  Copyright (c) 2015 qpiapps. All rights reserved.
//

import UIKit
import Foundation
import AVFoundation

class Die: UIImageView {
    
    // Audio player for sound effects
    private var dieSound: AVAudioPlayer? = nil
    
    // Indicates whether this die is currently being animated
    private var isAnimating = false
    
    // Timer for animating the die
    private var timer = NSTimer()
    
    // The total times the die roll animation plays
    private var totalRolls = 0
    
    // The number of times the die roll animation has currently played
    private var curRolls = 0
    
    // The current die side showing
    private var curSide = 1
    
    // The name of this die
    private var name: String
    
    // The number of sides this die has
    private var sides:Int
    
    var removeDieFromView: (dieToRemove: Die) -> Void
    
    init(image: UIImage, name: String, sides: Int, dieSound: AVAudioPlayer?, rdfv: (dieToRemove: Die) -> Void) {
        
        self.name = name
        self.sides = sides
        self.dieSound = dieSound
        self.removeDieFromView = rdfv
        
        super.init(image: image)
        
        var dieImage = UIImage(named: imageFile.imageFilePath(name, fileNumber: sides))
        

        self.userInteractionEnabled = true
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "imageTapped:"))
        self.addGestureRecognizer(UISwipeGestureRecognizer(target: self, action: "imageSwiped:"))
        
        self.bounds = CGRect(x: 0, y: 0, width: 100, height: 100)
    }

    // TODO: Not sure why this was required
    required init(coder aDecoder: NSCoder) {
        
        name = "unnamed"
        sides = 0
        dieSound = nil
        // Another hack because the arrogant idiots designing Swift have no
        // business making a new language. 
        removeDieFromView = Die.dummyFuncBecauseSwiftDesignersAreIdiots

        super.init(coder: aDecoder)
    }
    
    class func dummyFuncBecauseSwiftDesignersAreIdiots(dieToRemove: Die) {
        // This language is not ready for prime time
    }
    
    // Roll the die if the image is tapped
    func imageTapped(sender: UITapGestureRecognizer) {
        rollDie()
    }
    
    func imageSwiped(sender: UISwipeGestureRecognizer) {
        removeDieFromView(dieToRemove: self)
    }
    
    func rollDie() {
        // Don't allow die roll when it is still animating another roll
        if isAnimating {
            return
        }
        
        totalRolls = Int(arc4random_uniform(6)) + 2
        
        isAnimating = true
        timer = NSTimer.scheduledTimerWithTimeInterval(0.3, target: self, selector: Selector("doDieAnimation"), userInfo: nil, repeats: true)

    }
    
    // Macro to convert--easier to think in degrees
    func DEGREES_TO_RADIANS(x: CGFloat) -> CGFloat {
        return (CGFloat(M_PI) * (x) / 180.0)    // Set the die image based upon the number of the side
    }
    
    
    // Do the actual animation
    func doDieAnimation() {
        curSide = pickNextDieSide(curSide)
        
        var rotation = CGFloat(0)
        if curRolls < totalRolls {
            var degrees = Int(arc4random_uniform(80)) - 40
            rotation = DEGREES_TO_RADIANS(CGFloat(degrees))
        }
        
        setCurDieImage(curSide, rotation: rotation)
        
        // Play the sound effect just after the rolls start
        if curRolls == 1 {
            if dieSound != nil {
                dieSound!.play()
            }
        }
        
        // Check for the end of the animation
        if curRolls >= totalRolls {
            curRolls = 0
            timer.invalidate()
            isAnimating = false
        } else {
            curRolls++
        }
    }
    
    func setCurDieImage(currentSide: Int, rotation: CGFloat) {
        var image = UIImage(named: imageFile.imageFilePath(name, fileNumber: currentSide))
        if image == nil {
            println("ERROR: The image fetched for \(name) \(currentSide) is \(image)")
        }
        self.image = image
        self.transform = CGAffineTransformMakeRotation(rotation)
    }
    
    // Intelligently pick a side--never duplicate numbers consecutively
    func pickNextDieSide(curSide: Int) -> Int {
        var nextSide = Int(arc4random_uniform(UInt32(sides))) + 1
        if nextSide == curSide {
            nextSide++
            if nextSide > dieSides {
                nextSide = 1
            }
        }
        
        return nextSide
    }
    
    
    
}