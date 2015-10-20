//
//  InterfaceController.swift
//  TapAndRoll WatchKit Extension
//
//  Created by Ronald Fischer on 10/5/15.
//  Copyright (c) 2015 qpiapps. All rights reserved.
//

import WatchKit
import Foundation


class InterfaceController: WKInterfaceController {

    @IBOutlet weak var dieLabel: WKInterfaceLabel!
    @IBOutlet weak var dieImage: WKInterfaceImage!
    
    
    @IBAction func rollButton() {
        dieImage.startAnimating()
    }
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        createDieImage()
        dieImage.setImageNamed("path\\dieImage0.png")
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    func createDieImage() {
        var dieSize = CGSize(width: 150, height: 150)
        UIGraphicsBeginImageContext(dieSize)
        
        let context = UIGraphicsGetCurrentContext()
        
        for centerX in 0...10 {
            //draw a circle at centerX
            var rect = CGRect(x: centerX, y: 300, width: 150, height: 150)
            var path = UIBezierPath(ovalInRect: rect)
            UIColor.greenColor().setFill()
            path.fill()
            
            // Create a snapshot
            let image = UIGraphicsGetImageFromCurrentImageContext()
            
            // Write the image as a file
            let data = UIImagePNGRepresentation(image)
            let file = "path\\dieImage\(centerX).png"
            println(file)
            data.writeToFile(file, atomically: true)
            
        }
    }

}
