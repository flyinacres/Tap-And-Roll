//
//  DrawDice.swift
//  TapAndRoll
//
//  Created by Ronald Fischer on 10/27/15.
//  Copyright (c) 2015 qpiapps. All rights reserved.
//

import Foundation
import UIKit

class DrawDice {

    
    // Create the images for all of the die's sides
    func createDieImages(name: String, sides: Int, color: UIColor, width: CGFloat, height: CGFloat, radius: CGFloat) -> UIImage? {
        
        let dieSize = CGSize(width: Int(width), height: Int(height))
        
        // It makes no sense to have fewer than 3 or more than 10 sides...
        var drawableSides = sides
        if sides < 5 {
            drawableSides = 5
        } else if sides > 12 {
            drawableSides = 12
        }
        drawableSides = drawableSides - 2
        var arcRadius = Int(arc4random_uniform(10))
        
        var image: UIImage? = nil
        
        for centerX in 1...sides {
            UIGraphicsBeginImageContext(dieSize)
            let context = UIGraphicsGetCurrentContext()
            
            //draw a shape at centerX
            image = drawPolygonUsingPath(context, x: width/2, y: height/2, radius: radius, sides: drawableSides, curSide: centerX, color: color, arcRadius: arcRadius)
            
            // Write the image as a file
            imageFile.writeImage(UIImagePNGRepresentation(image), dieName: name, fileNumber: centerX)
            
            UIGraphicsEndImageContext()
        }
        
        return image
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
    
    let innerRadiusDelta: CGFloat = 24
    let brightnessDelta: CGFloat = 0.05
    func drawPolygonUsingPath(ctx:CGContextRef, x:CGFloat, y:CGFloat, radius:CGFloat, sides:Int, curSide: Int, color:UIColor, arcRadius: Int)->UIImage {
        let startAngle: CGFloat = degree2radian((360/CGFloat(sides*2))*CGFloat(curSide))
        var path = roundedPolygonPath(x, y: y, radius: radius, sides: sides, startAngle: startAngle, arcRadius: arcRadius)
        CGContextAddPath(ctx, path)
        CGContextSetFillColorWithColor(ctx, color.CGColor)
        CGContextFillPath(ctx)
//        CGContextDrawPath(ctx, kCGPathStroke)
        
        // Draw the inset portion of the polygon, if needed
        // Gives a small 3d effect
        if sides > 4 {
            var innerPath = roundedPolygonPath(x, y: y, radius: radius-innerRadiusDelta, sides: sides, startAngle: startAngle, arcRadius: arcRadius)
            CGContextAddPath(ctx, innerPath)
            
            // Change the brightness just a touch
            var h:CGFloat = 0.0
            var s:CGFloat = 0.0
            var b:CGFloat = 0.0
            var a:CGFloat = 0.0
            color.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
            
            var bd = brightnessDelta
            if b > 0.5 {
                bd = -brightnessDelta
            }
            var lighterColor = UIColor(hue: h, saturation: s, brightness: b+bd, alpha: a)
            
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