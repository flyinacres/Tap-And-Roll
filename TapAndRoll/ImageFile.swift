//
//  ImageFile.swift
//  TapAndRoll
//
//  Created by Ronald Fischer on 10/22/15.
//  Copyright (c) 2015 qpiapps. All rights reserved.
//

import Foundation

class ImageFile {
    var fileDir = ""

    init() {
        let dirs : [String] = (NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.AllDomainsMask, true) as? [String])!
        fileDir = dirs[0] //documents directory
    }
    
    func writeImage(data: NSData, dieName: String, fileNumber: Int) {
        var b = data.writeToFile(imageFilePath(dieName, fileNumber: fileNumber), atomically: true)
        //println("Write of \(dieName)\(fileNumber) is \(b)")
        //NSLog("testing, 1, 2, 3")
        
    }
    
    func imageFilePath(dieName: String, fileNumber: Int) -> String {
        let fileName = "dieImage\(dieName)\(fileNumber).png"
        //println("The filenName is \(fileName)")
        //NSLog("The fileName is \(fileName)")
        return fileDir.stringByAppendingPathComponent(fileName);
    }

    
}