//
//  DrawDice.swift
//  TapAndRoll
//
//  Created by Ronald Fischer on 10/27/15.
//  Copyright (c) 2015 qpiapps. All rights reserved.
//

import Foundation
import UIKit

let standardDieWidth: CGFloat = 100
let standardDieHeight: CGFloat = 100
let standardDieRadius: CGFloat = 50

class DrawDice {

    // Cannot share this with the watchkit extension.  The functionality has been moved to Die.swit anyway.
    
//    // Create the images for all of the die's sides
//    func createDieImages(name: String, sides: Int, color: UIColor, width: CGFloat, height: CGFloat, radius: CGFloat) -> UIImage? {
//        
//        let dieSize = CGSize(width: Int(width), height: Int(height))
//        
//        // It makes no sense to have fewer than 2 or more than 10 sides...
//        var drawableSides = sides
//        if sides == 2 {
//            // We have a coin 
//            drawableSides = 4
//        } else if sides < 5 {
//            drawableSides = 5
//        } else if sides > 12 {
//            drawableSides = 12
//        }
//        drawableSides = drawableSides - 2
//        var arcRadius = Int(arc4random_uniform(10)) + 1
//        
//        // Pick a different brightness for the die
//        // Jitter the delta a bit...  Make some dice look flatter than others
//        var delta: CGFloat = CGFloat(arc4random_uniform(200)) / CGFloat(500) + 0.2
//        var lighterColor = getLighterColor(color, delta: delta)
//        
//        // Figure out the font for the die (just a little variety)
//        var font: String = "Helvetica Bold"
//        var fontChoice = Int(arc4random_uniform(4))
//        switch fontChoice {
//        case 1:
//            font = "Verdana-Bold"
//        case 2:
//            font = "Palatino-Bold"
//        case 3:
//            font = "Superclarendon-Bold"
//        default:
//            font = "Helvetica Bold"
//        }
//        
//        var image: UIImage? = nil
//        
//        for centerX in 1...sides {
//            UIGraphicsBeginImageContext(dieSize)
//            let context = UIGraphicsGetCurrentContext()
//            
//            //draw a shape at centerX
//            image = drawPolygonUsingPath(context, x: width/2, y: height/2, radius: radius, sides: drawableSides, curSide: centerX, color: color, lighterColor: lighterColor, arcRadius: arcRadius, font: font)
//            
//            // Write the image as a file
//            imageFile.writeImage(UIImagePNGRepresentation(image), dieName: name, fileNumber: centerX)
//            
//            UIGraphicsEndImageContext()
//        }
//        
//        return image
//    }
    
    
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
    
    
    // Note that the process for creating the arcs involves the use
    // of tangent lines.  That's why this algorithm is different from
    // the one that simply draws the paths between points
    func roundedPolygonPath(x:CGFloat, y:CGFloat, radius:CGFloat, sides:Int, startAngle:CGFloat, arcRadius: Int) -> CGPathRef {
        let path = CGPathCreateMutable()
        let points = polygonPointArray(sides, x: x, y: y,radius: radius, startAngle: startAngle)
        
        // In order to use arc, must not start at the actual point
        var midPoint = CGPoint(x: (points[0].x + points[1].x) / 2, y: (points[0].y + points[1].y) / 2)
        CGPathMoveToPoint(path, nil, midPoint.x, midPoint.y)
        var previousPoint = CGPoint(x: 0, y: 0)
        
        for (i, p) in enumerate(points) {
            // Don't start from the first point--that was handled by the MoveTo above
            if i > 1 {
                CGPathAddArcToPoint(path, nil, previousPoint.x, previousPoint.y, p.x, p.y, CGFloat(arcRadius))
            }
            previousPoint = p
        }
        // And the last tangent line to specify
        CGPathAddArcToPoint(path, nil, previousPoint.x, previousPoint.y, points[1].x, points[1].y, CGFloat(arcRadius))
        
        CGPathCloseSubpath(path)
        return path
    }
    
    
    // Painful to create but cool now that it is working--fill the dice with a gradient
    // pre-clipped to the path I already created
    func fillWithGradient(ctx: CGContextRef, color: UIColor, lighterColor: UIColor, x: CGFloat, y: CGFloat) {
        
        // Set up the color space

        let colors = [color.CGColor, lighterColor.CGColor]
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        
        //4 - set up the color stops
        let colorLocations:[CGFloat] = [0.0, 1.0]
        
        //5 - create the gradient
        let gradient = CGGradientCreateWithColors(colorSpace,
            colors,
            colorLocations)
        
        //6 - draw the gradient
        var startPoint = CGPoint.zeroPoint
        var endPoint = CGPoint(x: 100, y: 100)
        CGContextDrawLinearGradient(ctx,
            gradient,
            startPoint,
            endPoint,
            0)
    }
    
    var innerRadiusDelta: CGFloat = 24
    let brightnessDelta: CGFloat = 0.05
    
    
    // Get a lighter hue of the same color
    func getLighterColor(color: UIColor, delta: CGFloat) -> UIColor {
        // Change the brightness just a touch
        var h:CGFloat = 0.0
        var s:CGFloat = 0.0
        var b:CGFloat = 0.0
        var a:CGFloat = 0.0
        color.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        
        var bd = delta
        if b > 0.5 {
            bd = -delta
        }
        return UIColor(hue: h, saturation: s, brightness: b+bd, alpha: a)
    }
    
    
    
    // Draws the polygon, or if it has two sides, the circle.  Should be split into two different functions...
    func drawPolygonUsingPath(ctx:CGContextRef, x:CGFloat, y:CGFloat, radius:CGFloat, sides:Int, curSide: Int, color:UIColor, lighterColor: UIColor, arcRadius: Int, font: String)->UIImage {
        
        // If it has two sides it is really just a coin--make a circle
        if sides == 2 {
            var startAngle: Float = Float(2 * M_PI)
            var endAngle: Float = 0.0
            
            // Find the middle of the circle
            let center = CGPointMake(x, y)
            
            // Set the stroke color
            CGContextSetStrokeColorWithColor(ctx, color.CGColor)
            
            // Set the line width
            CGContextSetLineWidth(ctx, CGFloat(6))
            
            // Rotate the angles so that the inputted angles are intuitive like the clock face: the top is 0 (or 2π), the right is π/2, the bottom is π and the left is 3π/2.
            // In essence, this appears like a unit circle rotated π/2 anti clockwise.
            startAngle = startAngle - Float(M_PI_2)
            endAngle = endAngle - Float(M_PI_2)
            
            // Draw the arc around the circle
            CGContextAddArc(ctx, center.x, center.y, CGFloat(radius) - CGFloat(arcRadius), CGFloat(startAngle), CGFloat(endAngle), 0)
            CGContextClip(ctx)
            
            // Draw the arc
            CGContextDrawPath(ctx, kCGPathStroke) // or kCGPathFillStroke to fill and stroke the circle
            fillWithGradient(ctx, color: color, lighterColor: lighterColor, x: x, y: y)
        } else {
            let startAngle: CGFloat = degree2radian((360/CGFloat(sides*2))*CGFloat(curSide))
            var path = roundedPolygonPath(x, y: y, radius: radius, sides: sides, startAngle: startAngle, arcRadius: arcRadius)
            
            // Use the path I already created to clip
            CGContextAddPath(ctx, path)
            CGContextClip(ctx)

            fillWithGradient(ctx, color: color, lighterColor: lighterColor, x: x, y: y)
            
            // Draw the inset portion of the polygon, if needed
            // Gives a small 3d effect
            if sides > 4 {
                // Ensure that this value scales with the radius
                innerRadiusDelta = radius / 2 - 1
                
                var innerPath = roundedPolygonPath(x, y: y, radius: radius-innerRadiusDelta, sides: sides, startAngle: startAngle, arcRadius: arcRadius)
                CGContextAddPath(ctx, innerPath)
                
                CGContextSetFillColorWithColor(ctx, lighterColor.CGColor)
                CGContextFillPath(ctx)
                
                // And draw the side lines
                let innerPoints = polygonPointArray(sides, x: x, y: y,radius: radius-innerRadiusDelta, startAngle: startAngle)
                let outerPoints = polygonPointArray(sides, x: x, y: y,radius: radius, startAngle: startAngle)
                let sideLinesPath = CGPathCreateMutable()

                for (outer, inner) in zip (outerPoints, innerPoints) {
                    CGPathMoveToPoint(sideLinesPath, nil, outer.x, outer.y)
                    CGPathAddLineToPoint(sideLinesPath, nil, inner.x, inner.y)
                }
                CGPathCloseSubpath(sideLinesPath)
                CGContextAddPath(ctx, sideLinesPath)
                CGContextSetStrokeColorWithColor(ctx, lighterColor.CGColor)
                CGContextDrawPath(ctx, kCGPathStroke)
            }
            
            //drawPip(ctx, x: x, y: y)
            //        drawText(ctx, x: x, y: y, radius: radius, color: UIColor.blackColor(), text: "\(curSide)")
        }
        return textToImage("\(curSide)", inImage: UIGraphicsGetImageFromCurrentImageContext(), atPoint: CGPoint(x: x, y: y), font: font, radius: radius)
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
    var fontSize: CGFloat = 24
    func textToImage(drawText: NSString, inImage: UIImage, atPoint:CGPoint, font: String, radius: CGFloat)->UIImage{
        
        // Setup the font specific variables
        var textColor: UIColor = UIColor.whiteColor()
        
        // Scale the fontSize with the radius.  Hopefully it does not end up at an invalid size
        fontSize = radius / 2 - 1
 
        var textFont: UIFont? = UIFont(name: font, size: fontSize)
        if textFont == nil {
            println("Font \(font) failed")
            // A known default
            textFont = UIFont(name: "Helvetica Bold", size: fontSize)
        }
        
        // Get the size of the display text, useful for centering
        let textSize: CGSize = drawText.sizeWithAttributes([NSFontAttributeName: textFont!.fontWithSize(fontSize)])
        
        //Setup the image context using the passed image.
        UIGraphicsBeginImageContext(inImage.size)
        
        //Setups up the font attributes that will be later used to dictate how the text should be drawn
        let textFontAttributes = [
            NSFontAttributeName: textFont!,
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