//
//  Task.swift
//  TaskScheduler
//
//  Created by Ben Oztalay on 9/28/15.
//  Copyright © 2015 Ben Oztalay. All rights reserved.
//

import Foundation
import CoreData

class Task: NSManagedObject {
    
    @NSManaged var title: String?
    @NSManaged var dueDate: NSDate
    @NSManaged private var rawPriority: Int16
    @NSManaged private var rawType: String?

    var priority: Priority {
        set {
            self.rawPriority = newValue.level.rawValue
        }
        get {
            return try! Priority.fromLevel(PriorityLevel(rawValue: self.rawPriority)!)
        }
    }
    
    var type: TaskType {
        set {
            self.rawType = newValue.rawValue
        }
        get {
            return TaskType(rawValue: self.rawType!)!
        }
    }
    
    convenience init(context: NSManagedObjectContext, title: String, dueDate: NSDate, priority: Priority, type: TaskType) {
        let entity = NSEntityDescription.entityForName("Task", inManagedObjectContext: context)!
        self.init(entity: entity, insertIntoManagedObjectContext: context)

        self.title = title
        self.dueDate = dueDate
        self.type = type
        self.priority = priority
    }
}
