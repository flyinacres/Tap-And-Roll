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
    var fileDir = ""
    var timer = NSTimer()
    
    
    @IBAction func rollButton(sender: AnyObject) {
        rollDie()
    }
    
    func imageTapped(sender: UITapGestureRecognizer) {
        rollDie()
    }
    
    func rollDie() {
        timer = NSTimer.scheduledTimerWithTimeInterval(0.3, target: self, selector: Selector("doDieAnimation"), userInfo: nil, repeats: true)
        //UIView.animateWithDuration(1, animations: { () -> Void in
        //    self.dieImage.center = CGPointMake(self.dieImage.center.x + 400, self.dieImage.center.y)
        //})
        
    }
    
    var counter = 0
    var maxSides = 10
    var totalRolls = 0
    var curRolls = 0
    var dieSides = 5
    func doDieAnimation() {
        let filePath = fileDir.stringByAppendingPathComponent("dieImage\(counter).png");
        println(filePath)
        dieImage.image = UIImage(named: filePath)
        
        if counter == dieSides-1 {
            counter = 0
        } else {
            counter++
        }
        
        if curRolls == totalRolls {
            curRolls = 0
            timer.invalidate()
        } else {
            curRolls++
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        println(self.view.frame)
        // Do any additional setup after loading the view, typically from a nib.
        fileDir = getWritablePath()
        createDieImage(fileDir, width: UIScreen.mainScreen().bounds.size.width, height: UIScreen.mainScreen().bounds.size.height)
        let filePath = fileDir.stringByAppendingPathComponent("dieImage3.png");
        println(filePath)
        dieImage.image = UIImage(named: filePath)
        println(dieImage.image)
        
        totalRolls = Int(arc4random_uniform(UInt32(dieSides + 4)))
        
        dieImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "imageTapped:"))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getWritablePath() -> String {
        let dirs : [String] = (NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.AllDomainsMask, true) as? [String])!
        return dirs[0] //documents directory
    }
    
    func createDieImage(fileDir: String, width: CGFloat, height: CGFloat) {
    
        let dieSize = CGSize(width: Int(width), height: Int(height))
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        println("size is \(rect)")
        
        for centerX in 0...dieSides {
            UIGraphicsBeginImageContext(dieSize)
            let context = UIGraphicsGetCurrentContext()
            
            //draw a circle at centerX
            drawPolygonUsingPath(context, x: CGRectGetMidX(rect),y: CGRectGetMidY(rect),radius: CGRectGetWidth(rect)/3, sides: dieSides, startAngle: degree2radian((360/CGFloat(dieSides*2))*CGFloat(centerX)), color: UIColor.blueColor())
            
            // Create a snapshot
            let image = UIGraphicsGetImageFromCurrentImageContext()
            
            // Write the image as a file
            let data = UIImagePNGRepresentation(image)
            let filePath = fileDir.stringByAppendingPathComponent("dieImage\(centerX).png");
            //println(filePath)
            var b = data.writeToFile(filePath, atomically: true)
            println("success of the write is \(b)")
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
            println("point is \(p)")
            CGPathAddLineToPoint(path, nil, p.x, p.y)
        }
        CGPathCloseSubpath(path)
        return path
    }
    
    func drawPolygonUsingPath(ctx:CGContextRef, x:CGFloat, y:CGFloat, radius:CGFloat, sides:Int, startAngle:CGFloat, color:UIColor) {
        let path = polygonPath(x, y: y, radius: radius, sides: sides, startAngle: startAngle)
        CGContextAddPath(ctx, path)
        CGContextSetFillColorWithColor(ctx, color.CGColor)
        CGContextFillPath(ctx)
        
        // Code to draw a single pip
        // TODO: Need to put varying number of pips on sides
        let rectangle = CGRect(x: x, y: y, width: 20, height: 20)
        CGContextSetFillColorWithColor(ctx, UIColor.whiteColor().CGColor)
        CGContextSetLineWidth(ctx, 3)
        CGContextSetStrokeColorWithColor(ctx, UIColor.blackColor().CGColor)
        CGContextAddEllipseInRect(ctx, rectangle)
        CGContextDrawPath(ctx, kCGPathFillStroke)
    }
 
}

