//
//  ViewController.swift
//  TapAndRoll
//
//  Created by Ronald Fischer on 10/5/15.
//  Copyright (c) 2015 qpiapps. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    @IBOutlet weak var dieLabel: UILabel!
    @IBOutlet weak var dieImage: UIImageView!
    
    // Timer for animating the die
    var timer = NSTimer()
    
    // Audio player for sound effects
    var player: AVAudioPlayer = AVAudioPlayer()

    // Functions for manipulating image files
    var imageFile = ImageFile()
    
    // The total times the die roll animation plays
    var totalRolls = 0
    
    // The number of times the die roll animation has currently played
    var curRolls = 0
    
    // The current die side showing
    var curSide = 1
    
    // True when an animation is already in process
    var isAnimating = false


    // Roll the die if the button is tapped
    @IBAction func rollButton(sender: AnyObject) {
            rollDie()
    }
    
    
    // Roll the die if the image is tapped
    func imageTapped(sender: UITapGestureRecognizer) {
            rollDie()
    }
    
    
    // Enable this view controller to get shake events, and others
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    
    // Roll the die if the phone is shaken
    override func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent) {
        if motion == .MotionShake {
            rollDie()
        }
    }
    
    
    // Function to actually do the die roll animation
    func rollDie() {
        
        // Don't allow die roll when it is still animating another roll
        if isAnimating {
            return
        }
        
        totalRolls = Int(arc4random_uniform(6)) + 2
        
        isAnimating = true
        timer = NSTimer.scheduledTimerWithTimeInterval(0.3, target: self, selector: Selector("doDieAnimation"), userInfo: nil, repeats: true)
        
        // This sort of code could be used to animate the appearance of the die...
        //UIView.animateWithDuration(1, animations: { () -> Void in
        //    self.dieImage.center = CGPointMake(self.dieImage.center.x + 400, self.dieImage.center.y)
        //})
        
    }
    
    func doDieAnimation() {
        curSide = pickNextDieSide(curSide)
        setCurDieImage(curSide)
        
        // Play the sound effect just after the rolls start
        if (curRolls == 1) {
            player.play()
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
    
    // Set the die image based upon the number of the side
    func setCurDieImage(currentSide: Int) {
        dieImage.image = UIImage(named: imageFile.imageFilePath(savedDice[currentDie].name, fileNumber: currentSide))
    }
    
    // Intelligently pick a side--never duplicate numbers consecutively
    func pickNextDieSide(curSide: Int) -> Int {
        var nextSide = Int(arc4random_uniform(UInt32(dieSides-1))) + 1
        if nextSide == curSide {
            nextSide++
            if nextSide > dieSides {
                nextSide = 1
            }
        }
        
        return nextSide
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        println(self.view.frame)
        
        // Do any additional setup after loading the view, typically from a nib.
//        createDieImages(UIScreen.mainScreen().bounds.size.width, height: UIScreen.mainScreen().bounds.size.height, radius: 100)
        createDieImages(100, height: 100, radius: 50)
        
        curSide = 1
        setCurDieImage(curSide)
        
        dieImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "imageTapped:"))
        
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
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // Create the images for all of the die's sides
    func createDieImages(width: CGFloat, height: CGFloat, radius: CGFloat) {
    
        let dieSize = CGSize(width: Int(width), height: Int(height))
        
        // It makes no sense to have fewer than 3 or more than 6 sides...
        var drawableSides = dieSides
        if dieSides < 5 {
            drawableSides = 5
        } else if dieSides > 8 {
            drawableSides = 8
        }
        drawableSides = drawableSides - 2
        
        for centerX in 1...dieSides {
            UIGraphicsBeginImageContext(dieSize)
            let context = UIGraphicsGetCurrentContext()
            
            //draw a shape at centerX
            let image = drawPolygonUsingPath(context, x: width/2, y: height/2, radius: radius, sides: drawableSides, curSide: centerX, color: dieColor)
            
            // Write the image as a file
            imageFile.writeImage(UIImagePNGRepresentation(image), dieName: savedDice[currentDie].name, fileNumber: centerX)

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
 
}

