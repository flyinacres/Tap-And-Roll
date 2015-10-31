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

// Audio player for dice cup sound effects
var diceCupAudio: AVAudioPlayer = AVAudioPlayer()

// Audio player for die roll sound effects
var diceRollAudio: AVAudioPlayer = AVAudioPlayer()

var smallRollAudio: AVAudioPlayer = AVAudioPlayer()
var largeRollAudio: AVAudioPlayer = AVAudioPlayer()

class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var dieImage: UIImageView!
    @IBOutlet weak var diceView: UIView!
    
    @IBOutlet weak var dieSelectionCollectionView: UICollectionView!


    // Reference to the class that does all of the actual dice image drawing
    let drawDice = DrawDice()
    
    // The current die side showing
    var curSide = 1

    private static var allDice = [RollableDie]()
    
    var numDSCVRows = 1


    let defaultDiceViewBounds: CGFloat = 110
    let diceViewBoundsMax: CGFloat = 320
    let diceViewBoundsDelta: CGFloat = 105
    let maxDicePerRow: Int = 3
    
    // Small bugs if the code is allowed to add or delete dice while it is animating adding or deleting of dice...
    // This is not fool proof, but should ameliorate an already rare problem
    var mustFinish = false
    
    // Add the specified die to the view, if possible
    func addDieToDiceView(die: Die, startPoint: CGPoint) {
        var totalDiceInView = ViewController.allDice.count
        
        if totalDiceInView == 9 {
            let alertController = UIAlertController(title: "Maximum Dice", message:
                "No more dice can be added.", preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default,handler: nil))
            
            self.presentViewController(alertController, animated: true, completion: nil)
            return
        }
        
        // If something is already going on that needs to complete, don't allow this add to continue
        if mustFinish {
            println("An attempt to add another die while add or remove is in progress")
            return
        } else {
            // Set the protection flag to avoid problems during the animation
            mustFinish = true
        }

        // Need to figure out how to increase the bounds, and where to add the new die
        var height = CGFloat((totalDiceInView / maxDicePerRow + 1) * 105 + 5)
        
        let newDie = RollableDie(die: die, rdfv: removeDieFromDiceView)
        
        ViewController.allDice.append(newDie)
        
        // Animate the adding of the die in the main view
        // Coordinates are originally in diceView space, so make them work for the main view
        view.addSubview(newDie)
        newDie.center = view.convertPoint(startPoint, fromView: diceView)

        var finalFrame = figureDiePosFrameRect(totalDiceInView)
        var finalPoint = CGPointMake(finalFrame.midX, finalFrame.midY)
        
        UIView.animateWithDuration(0.75, animations: { () -> Void in
            newDie.center = self.view.convertPoint(finalPoint, fromView: self.diceView)
            }, completion: { finished in
                // remove from super view
                newDie.removeFromSuperview()
                
                // add to subview
                self.diceView.addSubview(newDie)
                
                // put it in proper location
                newDie.center = finalPoint
                
                newDie.removeDieFromView = self.removeDieFromDiceView
                self.mustFinish = false
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
    func removeDieFromDiceView(dieToRemove: RollableDie) {
        
        
        // A little delta in the y angle to make it interesting
        var yDelta = CGFloat(arc4random_uniform(200)) - 100
        
        // Guard against adding new dice while the delete is proceeding
        // Delete pretty much must be done, as all other code already expects it to proceed
        mustFinish = true
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
                        UIView.animateWithDuration(0.5, animations: { () -> Void in
                            var finalFrame = self.figureDiePosFrameRect(i-1)
                            var finalPoint = CGPointMake(finalFrame.midX, finalFrame.midY)
                            die.center = finalPoint
                        })

                       // die.frame = self.figureDiePosFrameRect(i-1)
                    }
                    
                    self.mustFinish = false
                }
        })
        
    }

    // Roll the die if the button is tapped
    @IBAction func rollButton(sender: AnyObject) {
        
        diceRollAudio = smallRollAudio
        if ViewController.allDice.count > 2 {
            diceRollAudio = largeRollAudio
        }
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
        
        diceRollAudio = smallRollAudio
        if motion == .MotionShake {
            if ViewController.allDice.count > 2 {
                diceRollAudio = largeRollAudio
            }
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
    
    
    // Only support portrait mode for now
    override func supportedInterfaceOrientations() -> Int {
        return Int(UIInterfaceOrientationMask.Portrait.rawValue)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        curSide = 1
        // Set up the sound effects
        var e: NSErrorPointer = NSErrorPointer()
        var audioPath = NSBundle.mainBundle().pathForResource("diceroll", ofType: "caf")!
        smallRollAudio = AVAudioPlayer(contentsOfURL: NSURL(fileURLWithPath: audioPath), error: e)
        audioPath = NSBundle.mainBundle().pathForResource("manyDice", ofType: "caf")!
        largeRollAudio = AVAudioPlayer(contentsOfURL: NSURL(fileURLWithPath: audioPath), error: e)
        diceRollAudio = smallRollAudio
        if e != nil {
            println("Error fetching diceroll sound effect \(e)")
        }
        
        // Set up the sound effects
        audioPath = NSBundle.mainBundle().pathForResource("dicecup2", ofType: "caf")!
        diceCupAudio = AVAudioPlayer(contentsOfURL: NSURL(fileURLWithPath: audioPath), error: e)
        if e != nil {
            println("Error fetching dicecup sound effect \(e)")
        }

        dieSelectionCollectionView.layer.borderWidth = 2
        dieSelectionCollectionView.layer.cornerRadius = 20.0

        diceView.layer.borderWidth = 2
        diceView.layer.cornerRadius = 20.0
        diceView.clipsToBounds = true
        
        var gestureRecognizer = UISwipeGestureRecognizer(target: self, action: "segueToCreateDice:")
        gestureRecognizer.direction = UISwipeGestureRecognizerDirection.Right
        self.view.addGestureRecognizer(gestureRecognizer)
        
        // Put a first die in the view
        for die in ViewController.allDice {
            diceView.addSubview(die)
        }
        
        
        // In case it got stuck (it should not), reset this var
        mustFinish = false
    }
    
    // On a swipe segue to the other main view
    func segueToCreateDice(gesture: UIGestureRecognizer) {
        performSegueWithIdentifier("toCreateDice", sender: nil)
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Accordingto profiler, this actually works like a champ.  (Used the 'simulate low memory' in the simulator
        // And the images on screen stayed visible!
        for die in savedDice {
            die.releaseImages(false)
        }
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
        var readImage = savedDice[i].getImage(savedDice[i].sides-1)
        
        cell.dieCellImage.alpha = 1.0
        cell.dieCellImage.image = readImage
        var gestureRecognizer = UISwipeGestureRecognizer(target: self, action: "cellSwiped:")
        gestureRecognizer.direction = UISwipeGestureRecognizerDirection.Down
        cell.addGestureRecognizer(gestureRecognizer)

        cell.backgroundColor = UIColor.clearColor()
        cell.tag = i
        
        return cell
    }
    
    // Allow user to swipe down to add a die to the set
    func cellSwiped(gesture: UIGestureRecognizer) {
        let view: UIView = gesture.view!
        
        addDieToDiceView(savedDice[view.tag], startPoint: dieSelectionCollectionView.convertPoint(view.center, toView: diceView))
    }
    
    // Recognizes and handles when a collection view cell has been selected
    internal func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        var cell: UICollectionViewCell  = collectionView.cellForItemAtIndexPath(indexPath)! as UICollectionViewCell
        
        // Note that I had to convert the cell.center to the proper coordinate system
        addDieToDiceView(savedDice[cell.tag], startPoint: collectionView.convertPoint(cell.center, toView: diceView))
    }

}

