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
    
    @NSManaged var dueDate: NSDate
    @NSManaged var rawPriority: Int16
    @NSManaged var title: String?
    @NSManaged var type: String?

    var priority: Priority {
        set {
            self.rawPriority = newValue.level
        }
        get {
            return try! Priority.fromLevel(self.rawPriority)
        }
    }
    
    convenience init(context: NSManagedObjectContext, title: String, dueDate: NSDate, priority: Priority, type: String) {
        let entity = NSEntityDescription.entityForName("Task", inManagedObjectContext: context)!
        self.init(entity: entity, insertIntoManagedObjectContext: context)

        // This needs to be set explicitly (even though it's set by self.priority)
        self.rawPriority = Int16(0)

        self.title = title
        self.dueDate = dueDate
        self.type = type
        self.priority = priority
    }
}
