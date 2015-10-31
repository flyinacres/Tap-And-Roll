//
//  OptionsViewController.swift
//  TapAndRoll
//
//  Created by Ronald Fischer on 10/22/15.
//  Copyright (c) 2015 qpiapps. All rights reserved.
//

import UIKit
import AVFoundation


// The dice currently saved long term, including some pre-created ones
// Start with a standard D&D set
var originalSavedDice: [(dieSet: Int, name: String, color: String, sides: Int)] = [(dieSet: 0, name: "d4", color: "#D0643E", sides: 4), (dieSet: 0, name: "d6", color: "#3246AD", sides: 6), (dieSet: 0, name: "d8", color: "#4B6947", sides: 8), (dieSet: 0, name: "d10", color: "#870A15", sides: 10), (dieSet: 0, name: "d10 alt", color: "#A90C1B", sides: 10), (dieSet: 0, name: "d12", color: "#B81AB8", sides: 12), (dieSet: 0, name: "d20 The Big Gun", color: "#5910F6", sides: 20)]
var savedDice = [Die]()

class OptionsViewController: UIViewController, UIPopoverPresentationControllerDelegate, UITableViewDelegate, UITextFieldDelegate  {

    
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var curStepperValue: UIStepper!
    @IBOutlet weak var sidesLabel: UILabel!
    @IBOutlet weak var colorButton: UIButton!
    @IBOutlet weak var saveButtonLabel: UIButton!
    @IBOutlet weak var dieTableView: UITableView!
    
    // Need a var to save the color from the color picker, as the color picker
    // disappears after a selection has been made
    private var dieColor = UIColor.blueColor()
    
    // Called when the stepper changes
    @IBAction func sidesChoice(sender: UIStepper) {
        sidesLabel.text = "\(Int(sender.value).description) sides"
        nameField.text = "d\(Int(sender.value))"
        
        // Programmatic changes to the field do not trigger the text watcher, so see if I need to update the button label here
        updateButtonLabelsOnChange()
    }
    

    
    // Popup the color selection popover
    @IBAction func colorSelection(sender: UIButton) {
      
        // First, get rid of the keyboard if it is up--it takes too much space away from the color picker
        self.view.endEditing(true)

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
    
    
    // Look up a die by name.  Useful to see if it is a new or existing die
    func findDieByName(name: String) -> Int? {
        for (index, die) in enumerate(savedDice) {
            if die.name == name {
                return index
            }
        }
        
        return nil
    }
    
    // The save (or update) button was hit
    @IBAction func saveButton(sender: AnyObject) {
        var duplicateDie = false
        
        // First check to see if this is an update to an existing die
        if let index = findDieByName(nameField.text) {
            // Only update the color--this die already exists
            savedDice[index].color = dieColor.toHexString()
            
            // Now update the info for this die
            DicePersistence.sharedInstance.updateDieInStorage(savedDice[index])
            
            // Delete the old info so that they will be rewritten.
            savedDice[index].releaseImages(false)

            // Make sure table updates to show any changes
            dieTableView.reloadData()

        } else {
            // Add new die
            
            // Swift bug--thanks for wasting hours of my life... Swift cannot figure out the types of tuples and refuses to add them to an array.
            // Fortunately I switched from tuples to an actual class and everything works great
            var newDie = Die(dieSet: 0 as Int, name: nameField.text as String, color: dieColor.toHexString() as String, sides: Int(curStepperValue.value),
                width: standardDieWidth, height: standardDieHeight, radius: standardDieRadius)
            savedDice.append(newDie)
            
            // Now permanently save this die
            DicePersistence.sharedInstance.saveDieToStorage(newDie)
            
            // Make sure table updates to show this die
            dieTableView.reloadData()
            
            // And update the button labels
            updateButtonLabelsOnChange()
 
        }
    }
    
    
    // The rollbutton was hit--but since it causes a seque to the roll screen, shouldn't try and do anything here
    @IBAction func rollButton(sender: AnyObject) {
    }
    
    
    // Override the iPhone behavior that presents a popover as fullscreen
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        // Return no adaptive presentation style, use default presentation behaviour
        return .None
    }
    
    // Set the last color selected from the popover panel.  Note that the panel disappears, so the
    // color needs to be saved somewhere
    func setOptionColor (color: UIColor) {
        colorButton.setTitleColor(color, forState:UIControlState.Normal)
        dieColor = color
    }
    
    // Only support portrait mode for now
    override func supportedInterfaceOrientations() -> Int {
        return Int(UIInterfaceOrientationMask.Portrait.rawValue)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize the set of saved dice at least the first time.  After this assume that dice are
        // added as they are saved or updated
        if savedDice.count == 0 {
            var readDice = DicePersistence.sharedInstance.loadDiceFromStorage(0)
            if readDice == nil || readDice!.count == 0 {
                // Translate the originally persisted dice from the tuples to actual Die instances...
                var originalSaved = [Die]()
                for d in originalSavedDice {
                    originalSaved.append(Die(dieSet: d.dieSet, name: d.name, color: d.color, sides: d.sides, width: standardDieWidth, height: standardDieHeight, radius: standardDieRadius))
                }
                DicePersistence.sharedInstance.saveDieSet(0, theSavedDice: originalSaved)
                readDice = DicePersistence.sharedInstance.loadDiceFromStorage(0)
                if readDice != nil {
                   savedDice = readDice!
                }
            } else {
                savedDice = readDice!
            }
            
            // Save these dice to the set shared with the Apple Watch extension
            DicePersistence.sharedInstance.updateSharedDice()
        }
        
        // Set up the delegate for working with the editable die name field
        nameField.delegate = self
        
        // On view load the current options must all represent the selected die
        updateForCurrentDie(0)
        
        dieTableView.layer.borderWidth = 3
        dieTableView.layer.cornerRadius = 20.0
        dieTableView.layer.shadowOpacity = 10.0
        
        var gestureRecognizer = UISwipeGestureRecognizer(target: self, action: "segueToRollDice:")
        gestureRecognizer.direction = UISwipeGestureRecognizerDirection.Left
        self.view.addGestureRecognizer(gestureRecognizer)
    }
    
    func segueToRollDice(gesture: UIGestureRecognizer) {
        performSegueWithIdentifier("toRollDice", sender: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        //println("Low memory warning in OptionsViewController")

    }
    
    
    // Get rid of keyboard when return is pressed
    func textFieldShouldReturn(textField: UITextField) -> Bool // called when 'return' key pressed. return NO to ignore.
    {
        textField.resignFirstResponder()
        return true;
    }
    
    
    // Get rid of keyboard when clicking outside edit area
    override func   touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        self.view.endEditing(true)
    }
    
    
    // Limit the number of chars that can be entered for the die name
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange,
        replacementString string: String) -> Bool
    {
        let maxLength = 18
        let currentString: NSString = textField.text
        let newString: NSString =
        currentString.stringByReplacingCharactersInRange(range, withString: string)
        
        return newString.length <= maxLength
    }
    
    // Editing is done--see if this is the name of an existing die
    func textFieldDidEndEditing(textField: UITextField) {
        println("TextField did end editing method called")
        updateButtonLabelsOnChange()
    }
    
    // If the die is not a dup, update the roll button label to include the fact that the button will be saved
    func updateButtonLabelsOnChange() {
        if let index = findDieByName(nameField.text) {
            
            saveButtonLabel.setTitle("Update", forState: .Normal)
            setOptionColor(UIColor(hexString: savedDice[index].color))
        } else {
            // Update the button label so the user knows they will get a new die
            saveButtonLabel.setTitle("Save", forState: .Normal)
        }
    }
    
    // Number of rows in the table view
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return savedDice.count
    }

    
    // Name, color, sides--but start with one section initially...
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    
    // Set all of the variables/display to reflect the currently selected value, if any
    func updateForCurrentDie(currentRow: Int) {
        
        // Ensure this is only performed for a valid row
        if currentRow >= 0 && currentRow < savedDice.count {
            let currentDieFromRow = savedDice[currentRow]
            sidesLabel.text = "\(currentDieFromRow.sides) sides"
            nameField.text = currentDieFromRow.name
            
            curStepperValue.value = Double(currentDieFromRow.sides)
            
            setOptionColor(UIColor(hexString: currentDieFromRow.color))
        }
        
    }
    

    // Make sure that all of the variables/display reflect the row that will be selected
    func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        updateForCurrentDie(indexPath.row)
        updateButtonLabelsOnChange()
        
        return indexPath
    }
    
    
    // Set up the table based upon the contents of the savedDice
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "dieCell")
        cell.textLabel?.text = savedDice[indexPath.row].name
        cell.backgroundColor = UIColor(hexString: savedDice[indexPath.row].color)
        
        return cell
    }


}
