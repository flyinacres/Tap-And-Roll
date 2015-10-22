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
var dieColor = UIColor.blueColor()

class OptionsViewController: UIViewController, UIPopoverPresentationControllerDelegate  {

    
    @IBOutlet weak var curStepperValue: UIStepper!
    @IBOutlet weak var sidesLabel: UILabel!
    
    @IBOutlet weak var colorButton: UIButton!
    
    @IBAction func sidesChoice(sender: UIStepper) {
        sidesLabel.text = Int(sender.value).description
        dieSides = Int(sender.value)
    }
    
    @IBAction func colorSelection(sender: UIButton) {
        
        let popoverVC = storyboard?.instantiateViewControllerWithIdentifier("colorPickerPopover") as! ColorPickerViewController
        popoverVC.modalPresentationStyle = .Popover
        popoverVC.preferredContentSize = CGSizeMake(284, 446)
        if let popoverController = popoverVC.popoverPresentationController {
            popoverController.sourceView = sender
            popoverController.sourceRect = CGRect(x: 0, y: 0, width: 85, height: 30)
            popoverController.permittedArrowDirections = .Any
            popoverController.delegate = self
            popoverVC.delegate = self 
        }
        presentViewController(popoverVC, animated: true, completion: nil)
    }
    
    // Override the iPhone behavior that presents a popover as fullscreen
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        // Return no adaptive presentation style, use default presentation behaviour
        return .None
    }
    
    func setButtonColor (color: UIColor) {
        colorButton.setTitleColor(color, forState:UIControlState.Normal)
        dieColor = color
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
