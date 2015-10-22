//
//  ViewController.swift
//  TapAndRoll
//
//  Created by Ronald Fischer on 10/5/15.
//  Copyright (c) 2015 qpiapps. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var dieImage: UIImageView!
    var timer = NSTimer()
    
    // Functions for manipulating image files
    var imageFile = ImageFile()

    
    @IBAction func rollButton(sender: AnyObject) {
        if !isAnimating {
            rollDie()
        }
    }
    
    func imageTapped(sender: UITapGestureRecognizer) {
        if !isAnimating {
            rollDie()
        }
    }
    
    func rollDie() {
        
        totalRolls = Int(arc4random_uniform(UInt32(dieSides + 4))) + 1
        
        isAnimating = true
        timer = NSTimer.scheduledTimerWithTimeInterval(0.3, target: self, selector: Selector("doDieAnimation"), userInfo: nil, repeats: true)
        
        // This sort of code could be used to animate the appearance of the die...
        //UIView.animateWithDuration(1, animations: { () -> Void in
        //    self.dieImage.center = CGPointMake(self.dieImage.center.x + 400, self.dieImage.center.y)
        //})
        
    }
    
    var maxSides = 10
    var totalRolls = 0
    var curRolls = 0

    var curSide = 1
    var isAnimating = false
    func doDieAnimation() {
        curSide = pickNextDieSide(curSide)
        setCurDieImage(curSide)
        
        if curRolls >= totalRolls {
            curRolls = 0
            timer.invalidate()
            isAnimating = false
        } else {
            curRolls++
        }
    }
    
    func setCurDieImage(currentSide: Int) {
        dieImage.image = UIImage(named: imageFile.imageFilePath(currentSide))
    }
    
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
        createDieImages(UIScreen.mainScreen().bounds.size.width, height: UIScreen.mainScreen().bounds.size.height)
        
        curSide = 1
        setCurDieImage(curSide)
        
        dieImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "imageTapped:"))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func createDieImages(width: CGFloat, height: CGFloat) {
    
        let dieSize = CGSize(width: Int(width), height: Int(height))
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        
        for centerX in 1...dieSides {
            UIGraphicsBeginImageContext(dieSize)
            let context = UIGraphicsGetCurrentContext()
            
            //draw a shape at centerX
            drawPolygonUsingPath(context, x: CGRectGetMidX(rect),y: CGRectGetMidY(rect),radius: CGRectGetWidth(rect)/3, sides: dieSides, curSide: centerX, color: dieColor)
            
            // Create a snapshot
            let image = UIGraphicsGetImageFromCurrentImageContext()
            
            // Write the image as a file
            imageFile.writeImage(UIImagePNGRepresentation(image), fileNumber: centerX)

            UIGraphicsEndImageContext()
        }
        
        
    }

    
    func degree2radian(a:CGFloat)->CGFloat {
        let b = CGFloat(M_PI) * a/180
        return b
    }
    
    func polygonPointArray(sides:Int,x:CGFloat,y:CGFloat,radius:CGFloat, startAngle:CGFloat)->[CGPoint] {
        println("Total number of sides is \(sides)")
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
    
    func drawPolygonUsingPath(ctx:CGContextRef, x:CGFloat, y:CGFloat, radius:CGFloat, sides:Int, curSide: Int, color:UIColor) {
        let startAngle: CGFloat = degree2radian((360/CGFloat(sides*2))*CGFloat(curSide))
        let path = polygonPath(x, y: y, radius: radius, sides: sides, startAngle: startAngle)
        CGContextAddPath(ctx, path)
        CGContextSetFillColorWithColor(ctx, color.CGColor)
        CGContextFillPath(ctx)
        
        
        //drawPip(ctx, x: x, y: y)
        drawText(ctx, x: x, y: y, radius: radius, color: UIColor.blackColor(), text: "\(curSide)")
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
    
    func drawText(ctx:CGContextRef, x:CGFloat, y:CGFloat, radius:CGFloat, color:UIColor, text:String) {
        
        // Flip text co-ordinate space, see: http://blog.spacemanlabs.com/2011/08/quick-tip-drawing-core-text-right-side-up/
//        CGContextTranslateCTM(ctx, 0.0, CGRectGetHeight(rect))
        CGContextTranslateCTM(ctx, 0.0, 568)
        CGContextScaleCTM(ctx, 1.0, -1.0)
        // dictates on how inset the ring of numbers will be
        let inset:CGFloat = radius/3.5
        let path = CGPathCreateMutable()
        

        // Font name must be written exactly the same as the system stores it (some names are hyphenated, some aren't) and must exist on the user's device. Otherwise there will be a crash. (In real use checks and fallbacks would be created.) For a list of iOS 7 fonts see here: http://support.apple.com/en-us/ht5878
        let aFont = UIFont(name: "Optima-Bold", size: radius/2)
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

