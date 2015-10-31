//
//  InterfaceController.swift
//  TapAndRoll WatchKit Extension
//
//  Created by Ronald Fischer on 10/5/15.
//  Copyright (c) 2015 qpiapps. All rights reserved.
//

import WatchKit
import Foundation
import AVFoundation

class InterfaceController: WKInterfaceController {

    @IBOutlet weak var dieImage: WKInterfaceImage!
    @IBOutlet weak var rollLabel: WKInterfaceButton!
    
    var audioPlayer = AVAudioPlayer()
    
    var animationStatus = 0

    var selectedDie: Die? = nil

    @IBAction func rollButton() {
        // Don't allow a roll while animation is in progress
        if animationStatus == 1 {
            return
        }
        
        if selectedDie == nil {
            println("ERROR: No die selected")
            return
        }
        // A crude attempt to stop multiple overlapping button clicks
        animationStatus = 1

        
        // Rolls to show, and images to fetch
        var totalRolls = Int(arc4random_uniform(6)) + 2
        // Make the duration vary based upon the number of rolls, so that the total time is not always constant
        var duration: NSTimeInterval = NSTimeInterval(totalRolls / 3 + 2)
        
        var curSide:Int = 1
        var readImage = [UIImage]()
        for var i = 0; i < totalRolls; i++ {
            curSide = pickNextDieSide(curSide)
            readImage.append(selectedDie!.getImage(curSide))
        }
        
        // Warning: The watchkit is currently ignoring this duration...
        let animatedImage = UIImage.animatedImageWithImages(readImage, duration: 0.1)
        dieImage.setImage(animatedImage)
        
        // Do the sound
        audioPlayer.prepareToPlay()
        audioPlayer.play()
        
        dieImage.startAnimatingWithImagesInRange(NSMakeRange(0, totalRolls), duration: duration, repeatCount: 1)
        animationStatus = 0

    }
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)

        var soundPath = NSBundle.mainBundle().pathForResource("dicecup", ofType: "caf")
        var soundPathURL = NSURL(fileURLWithPath: soundPath!)
        
        var error:NSError?
        
        audioPlayer = AVAudioPlayer(contentsOfURL: soundPathURL, error: &error)
        
        if context != nil {
            selectedDie = context as! Die?
        }
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        if let actualDie = selectedDie {
            dieImage.setImage(actualDie.getImage(actualDie.sides-1))
        }
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    // Intelligently pick a side--never duplicate numbers consecutively
    // Return zero based index
    func pickNextDieSide(curSide: Int) -> Int {
        var nextSide = Int(arc4random_uniform(UInt32(selectedDie!.sides)))
        if nextSide == curSide {
            nextSide++
            if nextSide >= selectedDie!.sides {
                nextSide = 0
            }
        }
        
        return nextSide
    }

}
