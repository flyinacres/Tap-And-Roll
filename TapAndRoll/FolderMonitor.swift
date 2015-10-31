//
//  FolderMonitor.swift
//  TapAndRoll
//
//  Created by Ronald Fischer on 10/30/15.
//  Copyright (c) 2015 qpiapps. All rights reserved.
//

import Foundation

public class FolderMonitor {
    
    enum State {
        case On, Off
    }
    
    private var source: dispatch_source_t? = nil
    private let descriptor: CInt
    private let qq: dispatch_queue_t = dispatch_get_main_queue()
    private var state: State = .Off
    
    /// Creates a folder monitor object with monitoring enabled.
    // Wow--crap implementation fails if the folder does not already exist.
    public init(url: NSURL, handler: ()->Void) {
        
        state = .Off
        descriptor = open(url.fileSystemRepresentation, O_EVTONLY)
        
        if descriptor > 0 {
            source = dispatch_source_create(
                DISPATCH_SOURCE_TYPE_VNODE,
                UInt(descriptor),
                DISPATCH_VNODE_WRITE,
                qq
            )
            
            if source != nil {
                dispatch_source_set_event_handler(source!, handler)
                start()
            } else {
                NSLog("source could not be set for \(url.fileSystemRepresentation) so FolderMonitor is not initialized")
            }
        } else {
            NSLog("folder \(url.fileSystemRepresentation) could not be found so FolderMonitor is not initialized")
        }
    }
    
    /// Starts sending notifications if currently stopped
    public func start() {
        if state == .Off && source != nil {
            state = .On
            dispatch_resume(source!)
        }
    }
    
    /// Stops sending notifications if currently enabled
    public func stop() {
        if state == .On && source != nil {
            state = .Off
            dispatch_suspend(source!)
        }
    }
    
    deinit {
        if descriptor > 0 && source != nil {
            close(descriptor)
            dispatch_source_cancel(source!)
        }
    }
}
