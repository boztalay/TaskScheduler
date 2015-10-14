//
//  TaskWorkSession.swift
//  TaskScheduler
//
//  Created by Ben Oztalay on 10/12/15.
//  Copyright © 2015 Ben Oztalay. All rights reserved.
//

import Foundation
import CoreData

class TaskWorkSession: NSManagedObject {
    static var entityName = "TaskWorkSession"

    @NSManaged var parentTask: Task
    @NSManaged var dayScheduledOn: WorkDay
    @NSManaged var amountOfWork: Float
    @NSManaged var hasBeenCompleted: Bool
    
    init(context: NSManagedObjectContext, parentTask: Task, dayScheduledOn: WorkDay, amountOfWork: Float) {
        let entity = NSEntityDescription.entityForName(TaskWorkSession.entityName, inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)

        self.parentTask = parentTask
        self.dayScheduledOn = dayScheduledOn
        self.amountOfWork = amountOfWork
        self.hasBeenCompleted = false
    }
}
