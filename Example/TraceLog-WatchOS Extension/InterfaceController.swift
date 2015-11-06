//
//  InterfaceController.swift
//  TraceLog-WatchOS Extension
//
//  Created by Tony Stone on 11/6/15.
//  Copyright © 2015 Tony Stone. All rights reserved.
//

import WatchKit
import Foundation
import TraceLog

class InterfaceController: WKInterfaceController {

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        // Logging a Trace level 1 event with a closure
        logTrace() {
            
            //
            // This closure will only be executed
            // if logging in enabled.
            //
            if let unwrappedContext = context {
                return "Application awoke with context: " + unwrappedContext.stringValue
            } else {
                return "Application awoke with no context."
            }
        }
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        // Logging an Trace level 4 event
        logTrace("Application will activate", level: 4)
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        
        // Logging an Trace level 4 event
        logTrace("Application did deactivate", level: 4)
    }

}
