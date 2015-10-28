//
//  DieButton.swift
//  TapAndRoll
//
//  Created by Ronald Fischer on 10/28/15.
//  Copyright (c) 2015 qpiapps. All rights reserved.
//

import UIKit

class DieButton: UIButton {


    override func drawRect(rect: CGRect) {
        
        self.layer.cornerRadius = 5.0;
        self.layer.borderColor = UIColor.blackColor().CGColor
        self.layer.borderWidth = 1.0
        self.backgroundColor = UIColor.blueColor()
        tintColor = UIColor.blackColor()
        self.alpha = 1.0
        clipsToBounds = true
        
        let image = UIImage(named: "WoodBackground.png") as UIImage?
        setBackgroundImage(image, forState: .Normal)
        
        titleLabel!.font = UIFont(name: "COPPERPLATE-BOLD", size: 20)

    }


}
