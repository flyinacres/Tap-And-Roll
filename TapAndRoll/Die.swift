//
//  Die.swift
//  TapAndRoll
//
//  Created by Ronald Fischer on 10/29/15.
//  Copyright (c) 2015 qpiapps. All rights reserved.
//

import Foundation
import UIKit


class Die {
    
    var dieSet: Int = 0
    var name: String = ""
    var color: String = "#0000FF" {
        didSet {
            if color != oldValue  {
                lighterColor = getLighterColor(UIColor(hexString: color), delta: delta)
            }
        }
    }

    var sides: Int = 6
    var width = standardDieWidth
    var height = standardDieHeight
    var radius = standardDieRadius
    var sideImages = [UIImage?]()
    
    // This instance of the font will have some standard UI parameters for all of its sides
    var font: String = "Helvetica Bold"
    var fontChoice = Int(arc4random_uniform(4))
    var drawableSides = 4
    // Give this die a slightly different size
    var arcRadius = Int(arc4random_uniform(10)) + 1
    // Jitter the delta a bit...  Make some dice look flatter than others
    var delta: CGFloat = CGFloat(arc4random_uniform(200)) / CGFloat(500) + 0.2
    var lighterColor = UIColor.blueColor()

    // Reference to the class that does all of the actual dice image drawing
    let drawDice = DrawDice()

    // Empty initializer returns all defaults.  
    // Needed because POS Swift has an NSCoder standard which requires some object,
    // such as those that subclass UIImage to initialize every possible value, no matter
    // how useless these initializations are, and whether NSCoder functionality will ever
    // be used
    init() {
        sideImages = [UIImage?](count: sides, repeatedValue: nil)

    }
    
    init(dieSet: Int, name: String, color: String, sides: Int, width: CGFloat, height: CGFloat, radius: CGFloat) {
        self.dieSet = dieSet
        self.name = name
        self.color = color
        self.sides = sides
        self.width = width
        self.height = height
        self.radius = radius
        sideImages = [UIImage?](count: sides, repeatedValue: nil)
        
        // It makes no sense to have fewer than 2 or more than 10 sides...
        drawableSides = sides
        if sides == 2 {
            // We have a coin
            drawableSides = 4
        } else if sides < 5 {
            drawableSides = 5
        } else if sides > 12 {
            drawableSides = 12
        }
        drawableSides = drawableSides - 2
        
        // Pick a different brightness for the die
        lighterColor = getLighterColor(UIColor(hexString: color), delta: delta)
        
        // Figure out the font for the die (just a little variety)
        switch fontChoice {
        case 1:
            font = "Verdana-Bold"
        case 2:
            font = "Palatino-Bold"
        case 3:
            font = "Superclarendon-Bold"
        default:
            font = "Helvetica Bold"
        }
    }
    
    
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

    
    // Get the image for a particular side
    // The sides are zero-indexed
    func getImage(dieSide: Int) -> UIImage {
        if sideImages[dieSide] == nil {
            let dieSize = CGSize(width: Int(width), height: Int(height))
            UIGraphicsBeginImageContext(dieSize)
            let context = UIGraphicsGetCurrentContext()
            
            //draw a shape at centerX
            sideImages[dieSide] = drawDice.drawPolygonUsingPath(context, x: width/2, y: height/2, radius: CGFloat(radius), sides: drawableSides, curSide: dieSide+1, color: UIColor(hexString: color), lighterColor: lighterColor, arcRadius: arcRadius, font: font)
        
            UIGraphicsEndImageContext()
        }
        
        return sideImages[dieSide]!
    }

    
    // Release unneeded images.  Possibly save the iconic,last image, as that is used
    // to represent the die in UI components
    // Tested in profiler--this seems to be working!
    func releaseImages(saveIconicImage: Bool) {
        if saveIconicImage {
            sideImages = [UIImage?](count: sides-1, repeatedValue: nil)
        } else {
            sideImages = [UIImage?](count: sides, repeatedValue: nil)
        }
    }
    
    // should have an array of images for each side
    // should have an image getter for the die, and side
    // if the image does not yet exist, it is added to the array
    // low memory should free these images
    
    // These images should be used for all displays
    // Use an algorithm similar to that I used in the watch animation code
}