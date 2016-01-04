//
//  Priority.swift
//  TaskScheduler
//
//  Created by Ben Oztalay on 9/18/15.
//  Copyright © 2015 Ben Oztalay. All rights reserved.
//

import UIKit

enum PriorityPrettifierError: ErrorType {
    case InvalidPriorityLevel
}

class PriorityPrettifier: NSObject {
    private static let priorityNames = ["Lowest", "Low", "Medium", "High", "Highest"]
    
    static func priorityNameFromLevel(level: Int) throws -> String {
        if level < 0 || level >= PriorityPrettifier.priorityNames.count {
            throw PriorityPrettifierError.InvalidPriorityLevel
        }
        
        return PriorityPrettifier.priorityNames[level]
    }
}
