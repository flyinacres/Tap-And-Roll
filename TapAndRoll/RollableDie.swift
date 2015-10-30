//
//  Die.swift
//  TapAndRoll
//
//  Created by Ronald Fischer on 10/26/15.
//  Copyright (c) 2015 qpiapps. All rights reserved.
//

import UIKit
import AVFoundation

class RollableDie: UIImageView {
    
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
    
    // The Die associated with this RollableDie instance
    private var die: Die = Die()

    
    var removeDieFromView: (dieToRemove: RollableDie) -> Void
    
    init(die: Die, rdfv: (dieToRemove: RollableDie) -> Void) {
        
        self.die = die
        self.removeDieFromView = rdfv
        
        super.init(image: die.getImage(die.sides - 1))
        
        //var dieImage = UIImage(named: imageFile.imageFilePath(die.name, fileNumber: sides))
        

        self.userInteractionEnabled = true
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "imageTapped:"))
        self.addGestureRecognizer(UISwipeGestureRecognizer(target: self, action: "imageSwiped:"))
        
        self.bounds = CGRect(x: 0, y: 0, width: 100, height: 100)
    }

    // TODO: Not sure why this was required
    required init(coder aDecoder: NSCoder) {
        
        // Another hack because the arrogant idiots designing Swift have no
        // business making a new language. 
        removeDieFromView = RollableDie.dummyFuncBecauseSwiftDesignersAreIdiots

        super.init(coder: aDecoder)
    }
    
    class func dummyFuncBecauseSwiftDesignersAreIdiots(dieToRemove: RollableDie) {
        // This language is not ready for prime time
    }
    
    // Roll the die if the image is tapped
    func imageTapped(sender: UITapGestureRecognizer) {
        // When a single die is tapped, don't make the big sound
        diceRollAudio = smallRollAudio
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
        
        diceCupAudio.prepareToPlay()
        
        // Play the dice cup sound effect at the start of the roll
        var b: Bool = diceCupAudio.play()
        
        if b == false {
            println("ERROR: Attempt to play sound during animation failed")
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
        if curRolls == 2 {
            var b: Bool = diceRollAudio.play()
            if b == false {
                println("ERROR: Attempt to play sound during animation failed")
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
        //var image = UIImage(named: imageFile.imageFilePath(name, fileNumber: currentSide))
        self.image = die.getImage(currentSide-1)
        self.transform = CGAffineTransformMakeRotation(rotation)
    }
    
    // Intelligently pick a side--never duplicate numbers consecutively
    func pickNextDieSide(curSide: Int) -> Int {
        var nextSide = Int(arc4random_uniform(UInt32(die.sides))) + 1
        if nextSide == curSide {
            nextSide++
            if nextSide > die.sides {
                nextSide = 1
            }
        }
        
        return nextSide
    }
    
    
    
}