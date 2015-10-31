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
    
    // The other type of persistence handled here--sharing to defaults so that an AppleWatch can get the info
    let sharedDefaults = NSUserDefaults(suiteName: "group.com.qpiapps.TapAndRoll")
    

    var appDel:AppDelegate
    var context: NSManagedObjectContext

    init() {
        appDel = UIApplication.sharedApplication().delegate as! AppDelegate
        context = appDel.managedObjectContext!
    }

    // Save an entire die set to storage
    func saveDieSet(dieSet: Int, theSavedDice: [Die]) {
        for die in theSavedDice {
            if dieSet == die.dieSet {
                saveDieToStorage(die)
            }
        }
    }
    
    // Update the dice as shared with the Apple Watch (where dice cannot be created)
    func updateSharedDice() {
        var dieNames = [String]()
        
        for die in savedDice {
            dieNames.append(die.name)
            sharedDefaults?.setValue(die.dieSet, forKey: "\(die.name)DieSet")
            sharedDefaults?.setValue(die.sides, forKey: "\(die.name)Sides")
            sharedDefaults?.setValue(die.color, forKey: "\(die.name)Color")
        }
        sharedDefaults?.setObject(dieNames, forKey: "DieNames")
    }
    
    // Update a single Die as shared with the Apple Watch (where dice cannot be created)
    func updateSharedDice(die: Die) {
        sharedDefaults?.setValue(die.dieSet, forKey: "\(die.name)DieSet")
        sharedDefaults?.setValue(die.sides, forKey: "\(die.name)Sides")
        sharedDefaults?.setValue(die.color, forKey: "\(die.name)Color")
        
        // The hard part: if the name exists, do nothing.  If not, I need to append it and 
        // resave the list
        var dieNames: [String]? = sharedDefaults?.stringArrayForKey("DieNames") as? [String]
        if dieNames == nil {
            // Seems like the first die
            dieNames = [die.name]
            sharedDefaults?.setObject(dieNames, forKey: "DieNames")
        } else if !contains(dieNames!, die.name) {
            // It appears to be a new name, so add it
            dieNames?.append(die.name)
            sharedDefaults?.setObject(dieNames, forKey: "DieNames")
        }
        // Otherwise the name already exists so nothing to do

        
        // create Realm_DB-File in shared App-Groups Folder
        let directory: NSURL = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier("group.com.qpiapps.TapAndRoll")!
        //writing
        let file = "file.txt"
        let fileURL: NSURL = directory.URLByAppendingPathComponent(file)
        let text = "update folder by writing this string to it"
        var e: NSErrorPointer = NSErrorPointer()
        text.writeToURL(fileURL, atomically: true, encoding: NSUTF8StringEncoding, error: e)
        if e != nil {
            NSLog("ERROR, could not write sentinel file to app groups URL: \(fileURL)")
        }
    }
    
    // Update an existing die in storage
    func updateDieInStorage(die: Die) {
        var e: NSErrorPointer = NSErrorPointer()
        
        let request = NSFetchRequest(entityName: "DieInfo")
        request.returnsObjectsAsFaults = false
        let predicateDieSet = NSPredicate(format: "dieSet == %i", die.dieSet)
        let predicateName = NSPredicate(format: "name == %@", die.name)
        let predicate = NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType,
            subpredicates: [predicateDieSet, predicateName])
        
        request.predicate = predicate


        let results = context.executeFetchRequest(request, error: e)
        if e != nil {
            println("Error reading die for update: \(e)")
        } else if let saveDieResults = results {
            if saveDieResults.count == 1 {
                // This should be the unique result we wish to update
                var result = saveDieResults[0] as! NSManagedObject
                
                result.setValue(die.dieSet, forKey: "dieSet")
                result.setValue(die.name, forKey: "name")
                result.setValue(die.color, forKey: "color")
                result.setValue(die.sides, forKey: "sides")
                
                // Now actually save the values
                context.save(e)
                if e != nil {
                    println("Error updating die \(die.name): \(e)")
                }

            } else {
                println("Error, found \(saveDieResults.count) items, expecting one unique item")
            }
        } else {
            println("Error, no results found when searching from storage.")
        }
    }

    // Save a new die to storage
    func saveDieToStorage(die: Die) {
        var e: NSErrorPointer = NSErrorPointer()
        
        var newDie: AnyObject = NSEntityDescription.insertNewObjectForEntityForName("DieInfo", inManagedObjectContext: context)
        newDie.setValue(die.dieSet, forKey: "dieSet")
        newDie.setValue(die.name, forKey: "name")
        newDie.setValue(die.color, forKey: "color")
        newDie.setValue(die.sides, forKey: "sides")
        
        context.save(e)
        if e != nil {
            println("Error saving die \(die.name): \(e)")
        }
    }

    // Load all of the values for a particular Die Set
    func loadDiceFromStorage(dieSet: Int) ->  [Die]? {
        var e: NSErrorPointer = NSErrorPointer()
        
        var loadedDice: [Die] = []
        
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
                        let newDie = Die(dieSet: dieSet,
                            name: result.valueForKey("name") as! String,
                            color: result.valueForKey("color") as! String,
                            sides: result.valueForKey("sides") as! Int,
                            width: standardDieWidth, height: standardDieHeight, radius: standardDieRadius)
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
