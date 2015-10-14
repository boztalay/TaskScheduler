//
//  Priority.swift
//  TaskScheduler
//
//  Created by Ben Oztalay on 9/18/15.
//  Copyright © 2015 Ben Oztalay. All rights reserved.
//

import UIKit

enum PriorityLevel: Int16 {
    case Lowest = 0, Low, Medium, High, Highest
    
    static var count: Int {
        return Int(PriorityLevel.Highest.rawValue) + 1
    }
}

class Priority: NSObject {
    let name: String
    let level: PriorityLevel
    
    init(name: String, level: PriorityLevel) {
        self.name = name
        self.level = level
    }
    
    static func fromLevel(level: PriorityLevel) throws -> Priority {
        switch level {
            case .Lowest:
                return Priority(name: "Lowest", level: level)
            case .Low:
                return Priority(name: "Low", level: level)
            case .Medium:
                return Priority(name: "Medium", level: level)
            case .High:
                return Priority(name: "High", level: level)
            case .Highest:
                return Priority(name: "Highest", level: level)
        }
    }
}
