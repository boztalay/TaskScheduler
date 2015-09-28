//
//  Priority.swift
//  TaskScheduler
//
//  Created by Ben Oztalay on 9/18/15.
//  Copyright © 2015 Ben Oztalay. All rights reserved.
//

import UIKit

enum PriorityConversionError: ErrorType {
    case UnknownLevel
}

class Priority: NSObject {
    
    let name: String
    let level: Int16
    
    init(name: String, level: Int16) {
        self.name = name
        self.level = level
    }
    
    static func fromLevel(level: Int16) throws -> Priority {
        switch level {
            case 0:
                return Priority(name: "Lowest", level: level)
            case 1:
                return Priority(name: "Low", level: level)
            case 2:
                return Priority(name: "Medium", level: level)
            case 3:
                return Priority(name: "High", level: level)
            case 4:
                return Priority(name: "Highest", level: level)
            default:
                throw PriorityConversionError.UnknownLevel
        }
    }
}
//
//var priority: Priority {
//set {
//    self.rawPriority = newValue.level
//}
//get {
//    return try! Priority.fromLevel(self.rawPriority)
//}
//}
//
//init?(context: NSManagedObjectContext, title: String, dueDate: NSDate, priority: Priority, type: String) {
//    let entity = NSEntityDescription.entityForName("Task", inManagedObjectContext: context)!
//    super.init(entity: entity, insertIntoManagedObjectContext: context)
//    
//    print("Stupid: \(priority.name)")
//    
//    self.title = title
//    self.dueDate = dueDate
//    self.type = type
//    self.rawPriority = Int16(3)
//    self.priority = priority
//}
