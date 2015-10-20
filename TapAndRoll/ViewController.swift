//
//  ViewController.swift
//  TapAndRoll
//
//  Created by Ronald Fischer on 10/5/15.
//  Copyright (c) 2015 qpiapps. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        //createDieImage()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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

