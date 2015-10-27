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
var imageFile = ImageFile()
let reuseIdentifier = "AvailableDieCell"

class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var dieLabel: UILabel!
    @IBOutlet weak var dieImage: UIImageView!
    @IBOutlet weak var diceView: UIView!
    
    @IBOutlet weak var dieSelectionCollectionView: UICollectionView!

    
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
    func addDieToDiceView(name: String, sides: Int, color: UIColor) {
        var totalDiceInView = ViewController.allDice.count
        
        if totalDiceInView == 9 {
            let alertController = UIAlertController(title: "Maximum Dice", message:
                "No more dice can be added.", preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default,handler: nil))
            
            self.presentViewController(alertController, animated: true, completion: nil)
            return
        }
        
        // TODO: Need to figure out how to avoid doing this if die images already exist
        createDieImages(name, sides: sides, color: color, width: 100, height: 100, radius: 50)

        // Need to figure out how to increase the bounds, and where to add the new die
        var height = CGFloat((totalDiceInView / maxDicePerRow + 1) * 105 + 5)
        
        var newDieImage = UIImage(named: imageFile.imageFilePath(name, fileNumber: sides))

        let newDie = Die(image: newDieImage!, name: name, sides: sides, dieSound: player, rdfv: removeDieFromDiceView)
        
        ViewController.allDice.append(newDie)
        
        newDie.frame = figureDiePosFrameRect(totalDiceInView)
        newDie.removeDieFromView = removeDieFromDiceView
        // Actually add the die
        diceView.addSubview(newDie)
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
        
        // Remove the die from the list of all the dice
        var found = false
        for (i, die) in enumerate(ViewController.allDice) {
            if die == dieToRemove {
                ViewController.allDice.removeAtIndex(i)
                dieToRemove.removeFromSuperview()
                found = true
            } else if found {
                // After removing the indicated die, move the others to their new positions
                die.frame = figureDiePosFrameRect(i-1)
            }
        }
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

    

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        curSide = 1
        
        // Update the label on this page to reflect the die
        // in use
        dieLabel.text = savedDice[currentDie].name
        
        // Set up the sound effects
        var e: NSErrorPointer = NSErrorPointer()
        let audioPath = NSBundle.mainBundle().pathForResource("diceroll", ofType: "caf")!
        player = AVAudioPlayer(contentsOfURL: NSURL(fileURLWithPath: audioPath), error: e)
        if e != nil {
            println("Error playing sound effect \(e)")
        }
        
        diceView.layer.borderWidth = 3
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
    
    
    // Create the images for all of the die's sides
    func createDieImages(name: String, sides: Int, color: UIColor, width: CGFloat, height: CGFloat, radius: CGFloat) {
    
        let dieSize = CGSize(width: Int(width), height: Int(height))
        
        // It makes no sense to have fewer than 3 or more than 6 sides...
        var drawableSides = sides
        if sides < 5 {
            drawableSides = 5
        } else if sides > 8 {
            drawableSides = 8
        }
        drawableSides = drawableSides - 2
        
        for centerX in 1...sides {
            UIGraphicsBeginImageContext(dieSize)
            let context = UIGraphicsGetCurrentContext()
            
            //draw a shape at centerX
            let image = drawPolygonUsingPath(context, x: width/2, y: height/2, radius: radius, sides: drawableSides, curSide: centerX, color: color)
            
            // Write the image as a file
            imageFile.writeImage(UIImagePNGRepresentation(image), dieName: name, fileNumber: centerX)

            UIGraphicsEndImageContext()
        }
        
        
    }

    
    func degree2radian(a:CGFloat)->CGFloat {
        let b = CGFloat(M_PI) * a/180
        return b
    }
    
    func polygonPointArray(sides:Int,x:CGFloat,y:CGFloat,radius:CGFloat, startAngle:CGFloat)->[CGPoint] {
        let angle = degree2radian(360/CGFloat(sides))
        let cx = x // x origin
        let cy = y // y origin
        let r  = radius // radius of circle
        var i = 0
        var points = [CGPoint]()
        while i <= sides {
            var xpo = cx + r * cos(angle * CGFloat(i) + startAngle)
            var ypo = cy + r * sin(angle * CGFloat(i) + startAngle)
            points.append(CGPoint(x: xpo, y: ypo))
            i++;
        }
        return points
    }
    
    func polygonPath(x:CGFloat, y:CGFloat, radius:CGFloat, sides:Int, startAngle:CGFloat) -> CGPathRef {
        let path = CGPathCreateMutable()
        let points = polygonPointArray(sides, x: x, y: y,radius: radius, startAngle: startAngle)
        var cpg = points[0]
        CGPathMoveToPoint(path, nil, cpg.x, cpg.y)
        for p in points {
            CGPathAddLineToPoint(path, nil, p.x, p.y)
        }
        CGPathCloseSubpath(path)
        return path
    }
    
    func drawPolygonUsingPath(ctx:CGContextRef, x:CGFloat, y:CGFloat, radius:CGFloat, sides:Int, curSide: Int, color:UIColor)->UIImage {
        let startAngle: CGFloat = degree2radian((360/CGFloat(sides*2))*CGFloat(curSide))
        let path = polygonPath(x, y: y, radius: radius, sides: sides, startAngle: startAngle)
        CGContextAddPath(ctx, path)
        CGContextSetFillColorWithColor(ctx, color.CGColor)
        CGContextFillPath(ctx)
        
        
        //drawPip(ctx, x: x, y: y)
//        drawText(ctx, x: x, y: y, radius: radius, color: UIColor.blackColor(), text: "\(curSide)")
        return textToImage("\(curSide)", inImage: UIGraphicsGetImageFromCurrentImageContext(), atPoint: CGPoint(x: x, y: y))
    }
    
    func drawPip(ctx:CGContextRef, x:CGFloat, y:CGFloat) {
        
        // Code to draw a single pip
        // TODO: Need to put varying number of pips on sides
        let rectangle = CGRect(x: x, y: y, width: 20, height: 20)
        CGContextSetFillColorWithColor(ctx, UIColor.whiteColor().CGColor)
        CGContextSetLineWidth(ctx, 3)
        CGContextSetStrokeColorWithColor(ctx, UIColor.blackColor().CGColor)
        CGContextAddEllipseInRect(ctx, rectangle)
        CGContextDrawPath(ctx, kCGPathFillStroke)
    }
    
    // Draw arbitrary text on to my image
    let fontSize: CGFloat = 24
    func textToImage(drawText: NSString, inImage: UIImage, atPoint:CGPoint)->UIImage{
        
        // Setup the font specific variables
        var textColor: UIColor = UIColor.whiteColor()
        var textFont: UIFont = UIFont(name: "Helvetica Bold", size: fontSize)!
        
        // Get the size of the display text, useful for centering
        let textSize: CGSize = drawText.sizeWithAttributes([NSFontAttributeName: textFont.fontWithSize(fontSize)])
        
        //Setup the image context using the passed image.
        UIGraphicsBeginImageContext(inImage.size)
        
        //Setups up the font attributes that will be later used to dictate how the text should be drawn
        let textFontAttributes = [
            NSFontAttributeName: textFont,
            NSForegroundColorAttributeName: textColor,
        ]
        
        //Put the image into a rectangle as large as the original image.
        inImage.drawInRect(CGRectMake(0, 0, inImage.size.width, inImage.size.height))
        
        // Creating a point within the space that is as bit as the image.
        var rect: CGRect = CGRectMake(atPoint.x - (textSize.width/2), atPoint.y - (textSize.height/2), inImage.size.width, inImage.size.height)
        
        //Now Draw the text into an image.
        drawText.drawInRect(rect, withAttributes: textFontAttributes)
        
        // Create a new image out of the images we have created
        var newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()
        
        // End the context now that we have the image we need
        UIGraphicsEndImageContext()
        
        //And pass it back up to the caller.
        return newImage
        
    }
    
    // A deep-in-the-mud way to draw text on an image.  Not sure I will use this
    func drawText(ctx:CGContextRef, x:CGFloat, y:CGFloat, radius:CGFloat, color:UIColor, text:String) {
        
        // Flip text co-ordinate space, see: http://blog.spacemanlabs.com/2011/08/quick-tip-drawing-core-text-right-side-up/
//        CGContextTranslateCTM(ctx, 0.0, CGRectGetHeight(rect))
        CGContextTranslateCTM(ctx, 0.0, 568)
        CGContextScaleCTM(ctx, 1.0, -1.0)
        // dictates on how inset the ring of numbers will be
        let inset:CGFloat = radius/3.5
        let path = CGPathCreateMutable()
        

        // Font name must be written exactly the same as the system stores it (some names are hyphenated, some aren't) and must exist on the user's device. Otherwise there will be a crash. (In real use checks and fallbacks would be created.) For a list of iOS 7 fonts see here: http://support.apple.com/en-us/ht5878
        let aFont = UIFont(name: "Optima-Bold", size: radius/4)
        // create a dictionary of attributes to be applied to the string
        let attr:CFDictionaryRef = [NSFontAttributeName:aFont!,NSForegroundColorAttributeName:color]
        // create the attributed string
        let text = CFAttributedStringCreate(nil, text, attr)
        // create the line of text
        let line = CTLineCreateWithAttributedString(text)
        // retrieve the bounds of the text
        let bounds = CTLineGetBoundsWithOptions(line, CTLineBoundsOptions.UseOpticalBounds)
        // set the line width to stroke the text with
        CGContextSetLineWidth(ctx, 1.5)
        // set the drawing mode to stroke
        CGContextSetTextDrawingMode(ctx, kCGTextFill)
        // Set text position and draw the line into the graphics context, text length and height is adjusted for
        CGContextSetTextPosition(ctx, x-15, y-15)
        // the line of text is drawn - see https://developer.apple.com/library/ios/DOCUMENTATION/StringsTextFonts/Conceptual/CoreText_Programming/LayoutOperations/LayoutOperations.html
        // draw the line of text
        CTLineDraw(line, ctx)

        
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
        cell.dieCellImage.image = UIImage(named: imageFile.imageFilePath(savedDice[i].name, fileNumber: savedDice[i].sides))
        
        cell.backgroundColor = UIColor.clearColor()
        cell.tag = i
        
        return cell
    }
    
    // Recognizes and handles when a collection view cell has been selected
    internal func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        var cell: UICollectionViewCell  = collectionView.cellForItemAtIndexPath(indexPath)! as UICollectionViewCell
        
        // Update to the selected die
        currentDie = cell.tag
        addDieToDiceView(savedDice[currentDie].name, sides: savedDice[currentDie].sides, color: UIColor(hexString: savedDice[currentDie].color))
        
        // dispatch this so that the UI is updated
        dispatch_async(dispatch_get_main_queue()) {
            self.dieLabel.text = savedDice[currentDie].name
        }
        
    }
}

