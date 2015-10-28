//
//  ViewController.swift
//  TapAndRoll
//
//  Created by Ronald Fischer on 10/5/15.
//  Copyright (c) 2015 qpiapps. All rights reserved.
//

import UIKit
import AVFoundation


// Functions for manipulating image files
let imageFile = ImageFile()
let reuseIdentifier = "AvailableDieCell"

class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var dieImage: UIImageView!
    @IBOutlet weak var diceView: UIView!
    
    @IBOutlet weak var dieSelectionCollectionView: UICollectionView!

    // Reference to the class that does all of the actual dice image drawing
    let drawDice = DrawDice()
    
    // Audio player for sound effects
    var player: AVAudioPlayer = AVAudioPlayer()
    
    // The current die side showing
    var curSide = 1

    private static var allDice = [Die]()
    
    var numDSCVRows = 1


    let defaultDiceViewBounds: CGFloat = 110
    let diceViewBoundsMax: CGFloat = 320
    let diceViewBoundsDelta: CGFloat = 105
    let maxDicePerRow: Int = 3
    
    // Add the specified die to the view, if possible
    func addDieToDiceView(name: String, sides: Int, color: UIColor, startPoint: CGPoint) {
        var totalDiceInView = ViewController.allDice.count
        
        if totalDiceInView == 9 {
            let alertController = UIAlertController(title: "Maximum Dice", message:
                "No more dice can be added.", preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default,handler: nil))
            
            self.presentViewController(alertController, animated: true, completion: nil)
            return
        }

        // Need to figure out how to increase the bounds, and where to add the new die
        var height = CGFloat((totalDiceInView / maxDicePerRow + 1) * 105 + 5)
        
        var newDieImage = UIImage(named: imageFile.imageFilePath(name, fileNumber: sides))

        let newDie = Die(image: newDieImage!, name: name, sides: sides, dieSound: player, rdfv: removeDieFromDiceView)
        
        ViewController.allDice.append(newDie)
        
        // Animate the adding of the die
        newDie.center = startPoint
        diceView.addSubview(newDie)
        newDie.removeDieFromView = self.removeDieFromDiceView

        var finalFrame = figureDiePosFrameRect(totalDiceInView)
        var finalPoint = CGPointMake(finalFrame.midX, finalFrame.midY)
        println("Starting from \(startPoint) to \(finalPoint)")
        UIView.animateWithDuration(1, animations: { () -> Void in
            newDie.center = finalPoint
            })

    }
    
    // Calculate the placement (or re-placement) of a die from the total number and current height
    func figureDiePosFrameRect(dieNumber: Int) -> CGRect {
        var height = CGFloat((dieNumber / maxDicePerRow + 1) * 105 + 5)
        var xStart = CGFloat(dieNumber % maxDicePerRow * 105 + 5)
        var yStart = CGFloat(height - 105)
        
        return CGRect(x: xStart, y: yStart, width: 100, height: 100)
    }
    
    
    // The painful process of removing a particular die
    func removeDieFromDiceView(dieToRemove: Die) {
        
        // A little delta in the y angle to make it interesting
        var yDelta = CGFloat(arc4random_uniform(200)) - 100
        
        UIView.animateWithDuration(1, animations: { () -> Void in
            dieToRemove.center = CGPointMake(dieToRemove.center.x + 400, dieToRemove.center.y + yDelta)
            }, completion: { finished in
                // Do the actual removal work after the cool animation
                // Remove the die from the list of all the dice
                var found = false
                for (i, die) in enumerate(ViewController.allDice) {
                    if die == dieToRemove {
                        ViewController.allDice.removeAtIndex(i)
                        dieToRemove.removeFromSuperview()
                        found = true
                    } else if found {
                        // After removing the indicated die, move the others to their new positions
                        UIView.animateWithDuration(1, animations: { () -> Void in
                            var finalFrame = self.figureDiePosFrameRect(i-1)
                            var finalPoint = CGPointMake(finalFrame.midX, finalFrame.midY)
                            die.center = finalPoint
                        })

                       // die.frame = self.figureDiePosFrameRect(i-1)
                    }
                }
        })
        
    }

    // Roll the die if the button is tapped
    @IBAction func rollButton(sender: AnyObject) {
        for die in ViewController.allDice {
            die.rollDie()
        }
    }

    
    // Enable this view controller to get shake events, and others
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    
    // Roll the die if the phone is shaken
    override func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent) {
        if motion == .MotionShake {
            for die in ViewController.allDice {
                die.rollDie()
            }
        }
    }
    
    // TODO: This does not make a difference.  Still cannot get dice to update when color is changed
    // Warning, this also causes the view to segue back to the Dice Creation page--the order
    // the operations have is undetermined
    @IBAction func changeDiceSelected(sender: AnyObject) {
        println("This should always be called when the changeButton is hit")
        for die in ViewController.allDice {
            die.removeFromSuperview()
        }
        for cell in dieSelectionCollectionView.visibleCells() as! [DieViewCell] {
            cell.dieCellImage.image = nil
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        curSide = 1
        // Set up the sound effects
        var e: NSErrorPointer = NSErrorPointer()
        let audioPath = NSBundle.mainBundle().pathForResource("diceroll", ofType: "caf")!
        player = AVAudioPlayer(contentsOfURL: NSURL(fileURLWithPath: audioPath), error: e)
        if e != nil {
            println("Error playing sound effect \(e)")
        }
        
        dieSelectionCollectionView.layer.borderWidth = 3
        dieSelectionCollectionView.layer.cornerRadius = 20.0

        diceView.layer.borderWidth = 3
        diceView.layer.cornerRadius = 20.0
        diceView.clipsToBounds = true
        var diceViewBackground = UIImageView(image: UIImage(named: "WoodBackground.png"))
        diceView.addSubview(diceViewBackground)
        
        // Put a first die in the view
        for die in ViewController.allDice {
            diceView.addSubview(die)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // UICollectionViewDataSource Protocol:
    // Returns the number of rows in collection view
    internal func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return numDSCVRows
    }
    // UICollectionViewDataSource Protocol:
    // Returns the number of columns in collection view
    internal func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return savedDice.count
    }
    // UICollectionViewDataSource Protocol:
    // Initializes the collection view cells
    internal func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        var cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! DieViewCell
        
        let i = indexPath.section
        // Read the image--if it does not exist then create the image set
        var readImage = UIImage(named: imageFile.imageFilePath(savedDice[i].name, fileNumber: savedDice[i].sides))
        if readImage == nil {
            readImage = drawDice.createDieImages(savedDice[i].name, sides: savedDice[i].sides, color: UIColor(hexString: savedDice[i].color), width: 100, height: 100, radius: 50)
        }
        
        cell.dieCellImage.image = readImage
        
        cell.backgroundColor = UIColor.clearColor()
        cell.tag = i
        
        return cell
    }
    
    // Recognizes and handles when a collection view cell has been selected
    internal func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        var cell: UICollectionViewCell  = collectionView.cellForItemAtIndexPath(indexPath)! as UICollectionViewCell
        
        // Update to the selected die
        currentDie = cell.tag
        
        // Note that I had to convert the cell.center to the proper coordinate system
        addDieToDiceView(savedDice[currentDie].name, sides: savedDice[currentDie].sides, color: UIColor(hexString: savedDice[currentDie].color), startPoint: collectionView.convertPoint(cell.center, toView: diceView))
        
        // dispatch this so that the UI is updated
        dispatch_async(dispatch_get_main_queue()) {
            //self.dieLabel.text = savedDice[currentDie].name
        }
        
    }
}

