//
//  Priority.swift
//  TaskScheduler
//
//  Created by Ben Oztalay on 9/18/15.
//  Copyright © 2015 Ben Oztalay. All rights reserved.
//

import UIKit

// An error type for throwing priority prettifier
// related errors
enum PriorityPrettifierError: ErrorType {
    // Thrown by priorityNameFromLevel if it's
    // passed an invalid numeric priority level
    case InvalidPriorityLevel
}

class PriorityPrettifier: NSObject {
    // Holds all of the possible human-readable priority
    // level names order from lowest to highest priority
    private static let priorityNames = ["Lowest", "Low", "Medium", "High", "Highest"]
    
    // Returns the human-readable name for a given
    // numeric priority level
    static func priorityNameFromLevel(level: Int) throws -> String {
        if level < 0 || level >= PriorityPrettifier.priorityNames.count {
            throw PriorityPrettifierError.InvalidPriorityLevel
        }
        
        return PriorityPrettifier.priorityNames[level]
    }
}
