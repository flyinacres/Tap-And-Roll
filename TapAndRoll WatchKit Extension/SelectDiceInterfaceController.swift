//
//  SelectDiceInterfaceController.swift
//  TapAndRoll
//
//  Created by Ronald Fischer on 10/30/15.
//  Copyright (c) 2015 qpiapps. All rights reserved.
//

import WatchKit
import Foundation


class SelectDiceInterfaceController: WKInterfaceController {

    @IBOutlet weak var diceTable: WKInterfaceTable!
    
    // The dice currently saved long term, including some pre-created ones
    // Start with a standard D&D set
    var originalSavedDice: [(dieSet: Int, name: String, color: String, sides: Int)] = [(dieSet: 0, name: "d4", color: "#D0643E", sides: 4), (dieSet: 0, name: "d6", color: "#3246AD", sides: 6), (dieSet: 0, name: "d8", color: "#4B6947", sides: 8), (dieSet: 0, name: "d10", color: "#870A15", sides: 10), (dieSet: 0, name: "d10 alt", color: "#A90C1B", sides: 10), (dieSet: 0, name: "d12", color: "#B81AB8", sides: 12), (dieSet: 0, name: "d20 The Big Gun", color: "#5910F6", sides: 20)]
    var savedDice = [Die]()
    var smallDice = [Die]()
    
    // The other type of persistence handled here--sharing to defaults so that an AppleWatch can get the info
    let sharedDefaults = NSUserDefaults(suiteName: "group.com.qpiapps.TapAndRoll")

    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        var defaults = NSUserDefaults(suiteName: "group.com.qpiapps.TapAndRoll")
        
        // Need to figure out how to store my data in this storage...
        var receivedData: AnyObject? = defaults?.objectForKey("SavedDice")
        
        savedDice = getSharedDice()
        
        // Populate from the defaults stored on the watch if nothing was found in shared storage
        if savedDice.count == 0 {
            // Translate the originally persisted dice from the tuples to actual Die instances...
            for d in originalSavedDice {
                savedDice.append(Die(dieSet: d.dieSet, name: d.name, color: d.color, sides: d.sides, width: standardDieWidth, height: standardDieHeight, radius: standardDieRadius))
                smallDice.append(Die(dieSet: d.dieSet, name: d.name, color: d.color, sides: d.sides, width: standardDieWidth/2, height: standardDieHeight/2, radius: standardDieRadius/2))
            }
        } else {
            // Make sure that the small dice matches the big dice in contents
            for d in savedDice {
                smallDice.append(Die(dieSet: d.dieSet, name: d.name, color: d.color, sides: d.sides, width: standardDieWidth/2, height: standardDieHeight/2, radius: standardDieRadius/2))
            }
        }
        
        diceTable.setNumberOfRows(savedDice.count, withRowType: "diceTableRowController")
        
        // The small images go into the list
        var j = 0
        for die in smallDice {
            let row = diceTable.rowControllerAtIndex(j) as! TableRowController
            row.rowLabel.setText(die.name)
            row.rowImage.setImage(die.getImage(die.sides-1))
            j++
        }

    }
    
    func getSharedDice() -> [Die] {
        var dies = [Die]()
        
        var dieNames: [String]? = sharedDefaults?.stringArrayForKey("DieNames") as? [String]
        if dieNames != nil {
            for dieName in dieNames! {
                var dieSet: Int? = sharedDefaults?.integerForKey("\(dieName)DieSet") as Int?
                var sides: Int? = sharedDefaults?.integerForKey("\(dieName)Sides") as Int?
                var color: String? = sharedDefaults?.stringForKey("\(dieName)Color") as String?
                dies.append(Die(dieSet: dieSet!, name: dieName, color: color!, sides: sides!, width: standardDieWidth, height: standardDieHeight, radius: standardDieRadius))
            }
        }
        
        return dies
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    

    
    override func table(table: WKInterfaceTable, didSelectRowAtIndex rowIndex: Int) {
        if rowIndex < 0 || rowIndex > savedDice.count - 1 {
            println("ERROR: Row \(rowIndex) selected, but now savedDice at that location")
        } else {
            self.pushControllerWithName("Roll Die", context: savedDice[rowIndex])
        }
    }

}
