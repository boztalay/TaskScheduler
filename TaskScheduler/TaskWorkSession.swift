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
    // The CoreData entity name to use for this class
    static var entityName = "TaskWorkSession"

    // The task that this work session is for
    @NSManaged var parentTask: Task
    
    // The day that this work sessions is scheduled on
    @NSManaged var dayScheduledOn: WorkDay
    
    // The number of hours of work to be done in
    // this work session
    @NSManaged var amountOfWork: Float
    
    // Whether or not this work session has been completed
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
