//
//  DieView.swift
//  TapAndRoll
//
//  Created by Ronald Fischer on 10/20/15.
//  Copyright (c) 2015 qpiapps. All rights reserved.
//

import UIKit

class DieView: UIView {

    
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
        for centerX in 0...100 {
            //draw a circle at centerX
            var rect = CGRect(x: centerX, y: 300, width: 150, height: 150)
                var path = UIBezierPath(ovalInRect: rect)
            UIColor.greenColor().setFill()
            path.fill()
            UIColor.whiteColor().setFill()
            path.fill()
        }
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
