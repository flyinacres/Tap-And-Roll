//
//  DicePersistence.swift
//  TapAndRoll
//
//  Created by Ronald Fischer on 10/24/15.
//  Copyright (c) 2015 qpiapps. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class DicePersistence {
    
    static let sharedInstance = DicePersistence()
    
    var appDel:AppDelegate
    var context: NSManagedObjectContext

    init() {
        appDel = UIApplication.sharedApplication().delegate as! AppDelegate
        context = appDel.managedObjectContext!
    }

    // Save an entire die set to storage
    func saveDieSet(dieSet: Int, theSavedDice: [(dieSet: Int, name: String, color: String, sides: Int)]) {
        for die in theSavedDice {
            if dieSet == die.dieSet {
                saveDieToStorage(dieSet, name: die.name, color: die.color, sides: die.sides)
            }
        }
    }
    
    // Update an existing die in storage
    func updateDieInStorage(dieSet: Int, name: String, color: String, sides: Int) {
        var e: NSErrorPointer = NSErrorPointer()
        
        let request = NSFetchRequest(entityName: "DieInfo")
        request.returnsObjectsAsFaults = false
        let predicateDieSet = NSPredicate(format: "dieSet == %i", dieSet)
        let predicateName = NSPredicate(format: "name == %@", name)
        let predicate = NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType,
            subpredicates: [predicateDieSet, predicateName])
        
//        request.predicate = NSPredicate(format: "dieSet == %@ AND name == %@", dieSet, name)
        request.predicate = predicate


        let results = context.executeFetchRequest(request, error: e)
        if e != nil {
            println("Error reading die for update: \(e)")
        } else if let saveDieResults = results {
            if saveDieResults.count == 1 {
                // This should be the unique result we wish to update
                var result = saveDieResults[0] as! NSManagedObject
                
                result.setValue(dieSet, forKey: "dieSet")
                result.setValue(name, forKey: "name")
                result.setValue(color, forKey: "color")
                result.setValue(sides, forKey: "sides")
                
                // Now actually save the values
                context.save(e)
                if e != nil {
                    println("Error updating die \(name): \(e)")
                }

            } else {
                println("Error, found \(saveDieResults.count) items, expecting one unique item")
            }
        } else {
            println("Error, no results found when searching from storage.")
        }
    }

    // Save a new die to storage
    func saveDieToStorage(dieSet: Int, name: String, color: String, sides: Int) {
        var e: NSErrorPointer = NSErrorPointer()
        
        var newDie: AnyObject = NSEntityDescription.insertNewObjectForEntityForName("DieInfo", inManagedObjectContext: context)
        newDie.setValue(dieSet, forKey: "dieSet")
        newDie.setValue(name, forKey: "name")
        newDie.setValue(color, forKey: "color")
        newDie.setValue(sides, forKey: "sides")
        
        context.save(e)
        if e != nil {
            println("Error saving die \(name): \(e)")
        }
    }

    // Load all of the values for a particular Die Set
    func loadDiceFromStorage(dieSet: Int) ->  [(dieSet: Int, name: String, color: String, sides: Int)]? {
        var e: NSErrorPointer = NSErrorPointer()
        
        var loadedDice: [(dieSet: Int, name: String, color: String, sides: Int)] = []
        
        let request = NSFetchRequest(entityName: "DieInfo")
        request.returnsObjectsAsFaults = false
        
        let results = context.executeFetchRequest(request, error: e)
        if e != nil {
            println("Error reading die: \(e)")
        } else if let saveDieResults = results {
            if saveDieResults.count > 0 {
                for result in saveDieResults as! [NSManagedObject] {
                    let curDieSet = result.valueForKey("dieSet") as! Int
                    if curDieSet == dieSet {
                        let newDie = (dieSet: dieSet,
                            name: result.valueForKey("name") as! String,
                            color: result.valueForKey("color") as! String,
                            sides: result.valueForKey("sides") as! Int)
                        loadedDice.append(newDie)
                    }
                }
                if loadedDice.count == 0 {
                    println("Error, no dice found for dieSet \(dieSet)")
                }
            } else {
                println("Error, count of items in storage is 0 when values expected")
            }
        } else {
            println("Error, no results found when reading from storage.")
        }
        
        return loadedDice
    }
}
