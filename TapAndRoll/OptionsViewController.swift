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
// This is the color of the current die
var dieColor = UIColor.blueColor()
// This is the current die to use from the list of savedDice
var currentDie = 0

// The dice currently saved long term, including some pre-created ones
// Start with a standard D&D set
var originalSavedDice: [(dieSet: Int, name: String, color: String, sides: Int)] = [(dieSet: 0, name: "d4", color: "#D0643E", sides: 4), (dieSet: 0, name: "d6", color: "#3246AD", sides: 6), (dieSet: 0, name: "d8", color: "#4B6947", sides: 8), (dieSet: 0, name: "d10", color: "#870A15", sides: 10), (dieSet: 0, name: "d10 alt", color: "#A90C1B", sides: 10), (dieSet: 0, name: "d12", color: "#B81AB8", sides: 12), (dieSet: 0, name: "d20 The Big Gun", color: "#5910F6", sides: 20)]
var savedDice: [(dieSet: Int, name: String, color: String, sides: Int)]  = []

class OptionsViewController: UIViewController, UIPopoverPresentationControllerDelegate, UITableViewDelegate, UITextFieldDelegate  {

    
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var curStepperValue: UIStepper!
    @IBOutlet weak var sidesLabel: UILabel!
    @IBOutlet weak var colorButton: UIButton!
    @IBOutlet weak var saveButtonLabel: UIButton!
    @IBOutlet weak var dieTableView: UITableView!
    
    // Called when the stepper changes
    @IBAction func sidesChoice(sender: UIStepper) {
        sidesLabel.text = Int(sender.value).description
        dieSides = Int(sender.value)
        nameField.text = "D\(dieSides)"
        
        // Programmatic changes to the field do not trigger the text watcher, so see if I need to update the button label here
        updateSaveButtonLabelOnChange()
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
        
        if let index = findDieByName(nameField.text) {
            // Only update the color--this die already exists
            savedDice[index] = (dieSet: 0, name: savedDice[index].name, color: dieColor.toHexString(), sides: savedDice[index].sides)
            
            // Now update the info for this die
            DicePersistence.sharedInstance.updateDieInStorage(0, name: savedDice[index].name, color: dieColor.toHexString(), sides: savedDice[index].sides)
            
            // Delete the old file so that they will be rewritten.
            var e = NSErrorPointer()
            println("Removing file \(savedDice[index].name) \(savedDice[index].sides)")
            var result = NSFileManager.defaultManager().removeItemAtPath(imageFile.imageFilePath(savedDice[index].name, fileNumber: savedDice[index].sides), error: e)
            if e != nil {
                println("Error trying to erase previous file: \(e)")
            }
            println("Result of the delete was \(result)")
            var readImage = UIImage(named: imageFile.imageFilePath(savedDice[index].name, fileNumber: savedDice[index].sides))
            if readImage != nil {
                println("Found file that should have been deleted")
            }

            // Make sure table updates to show any changes
            dieTableView.reloadData()

        } else {
            // Add new die
            
            // Swift bug--thanks for wasting hours of my life...
            // Swift cannot figure out the types of tuples and refuses to add them to an array.
            savedDice.append(dieSet: 0 as Int, name: nameField.text as String, color: dieColor.toHexString() as String, sides: dieSides as Int)
            
            // Now permanently save this die
            DicePersistence.sharedInstance.saveDieToStorage(0, name: nameField.text, color: dieColor.toHexString(), sides: dieSides)
            
            // Don't forget to update the selection to the newly added die
            currentDie = savedDice.count - 1
            
            
            // Make sure table updates to show this die
            dieTableView.reloadData()
            
            // And update the button labels
            updateSaveButtonLabelOnChange()
 
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
    
    func setButtonColor (color: UIColor) {
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
            var readDice: [(dieSet: Int, name: String, color: String, sides: Int)]?
            readDice = DicePersistence.sharedInstance.loadDiceFromStorage(0)
            if readDice == nil || readDice!.count == 0 {
                DicePersistence.sharedInstance.saveDieSet(0, theSavedDice: originalSavedDice)
                readDice = DicePersistence.sharedInstance.loadDiceFromStorage(0)
                if readDice != nil {
                   savedDice = readDice!
                }
            } else {
                savedDice = readDice!
            }

        }
        
        // Set up the delegate for working with the editable die name field
        nameField.delegate = self
        
        // On view load the current options must all represent the selected die
        updateForCurrentDie(currentDie)
        
        dieTableView.layer.borderWidth = 3
        dieTableView.layer.cornerRadius = 20.0
        dieTableView.layer.shadowOpacity = 10.0
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        
        updateSaveButtonLabelOnChange()
        return newString.length <= maxLength
    }
    
    
    // If the die is not a dup, update the roll button label to include the fact that the button will be saved
    func updateSaveButtonLabelOnChange() {
        if let index = findDieByName(nameField.text) {
            
            saveButtonLabel.setTitle("Update", forState: .Normal)
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
            
            dieSides = currentDieFromRow.sides
            curStepperValue.value = Double(dieSides)
            
            setButtonColor(UIColor(hexString: currentDieFromRow.color))
            
            // Now update the global current die, to ensure it is in sync with the UI
            currentDie = currentRow
        }
        
    }
    

    // Make sure that all of the variables/display reflect the row that will be selected
    func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        updateForCurrentDie(indexPath.row)
        updateSaveButtonLabelOnChange()
        
        return indexPath
    }
    
    
    // Set up the table based upon the contents of the savedDice array of tuples
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "dieCell")
        cell.textLabel?.text = savedDice[indexPath.row].name
        cell.backgroundColor = UIColor(hexString: savedDice[indexPath.row].color)
        
        return cell
    }


}
