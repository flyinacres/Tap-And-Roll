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
    
    func writeImage(data: NSData, fileNumber: Int) {
        var b = data.writeToFile(imageFilePath(fileNumber), atomically: true)
        println("success of the write is \(b)")
        
    }
    
    func imageFilePath(fileNumber: Int) -> String {
        return fileDir.stringByAppendingPathComponent("dieImage\(fileNumber).png");
    }

    
}