//
//  OptionsViewController.swift
//  TapAndRoll
//
//  Created by Ronald Fischer on 10/22/15.
//  Copyright (c) 2015 qpiapps. All rights reserved.
//

import UIKit

// This is the number of sides to use for the die
var dieSides = 8

class OptionsViewController: UIViewController {

    
    @IBOutlet weak var curStepperValue: UIStepper!
    @IBOutlet weak var sidesLabel: UILabel!
    
    @IBAction func sidesChoice(sender: UIStepper) {
        sidesLabel.text = Int(sender.value).description
        dieSides = Int(sender.value)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sidesLabel.text = dieSides.description
        curStepperValue.value = Double(dieSides)

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
