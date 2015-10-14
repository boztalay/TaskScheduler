//
//  Task.swift
//  TaskScheduler
//
//  Created by Ben Oztalay on 9/28/15.
//  Copyright © 2015 Ben Oztalay. All rights reserved.
//

import Foundation
import CoreData

enum TaskError: ErrorType {
    case WorkSessionDoesntBelong
}

class Task: NSManagedObject {
    static var entityName = "Task"
    
    @NSManaged var title: String
    @NSManaged var dueDate: NSDate
    @NSManaged var priority: Int
    @NSManaged var workEstimate: Float
    @NSManaged var workSessions: NSMutableSet
    @NSManaged var dropped: Bool
    @NSManaged var isComplete: Bool
    
    var workSessionsArray: [TaskWorkSession] {
        return self.workSessions.allObjects as! [TaskWorkSession]
    }
    
    var totalWorkScheduled: Float {
        return self.workSessionsArray.map({ $0.amountOfWork }).reduce(0.0, combine: +)
    }
    
    var workNotScheduled: Float {
        return self.workEstimate - self.totalWorkScheduled
    }
    
    var workCompleted: Float {
        return self.workSessionsArray.filter({ $0.hasBeenCompleted }).map({ $0.amountOfWork }).reduce(0.0, combine: +)
    }
    
    var workLeftToDo: Float {
        return self.workEstimate - self.workCompleted
    }
    
    init(context: NSManagedObjectContext, title: String, dueDate: NSDate, priority: Int, workEstimate: Float) {
        let entity = NSEntityDescription.entityForName(Task.entityName, inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.title = title
        self.dueDate = dueDate
        self.priority = priority
        self.workEstimate = workEstimate
        self.dropped = false
        self.isComplete = false
    }
    
    func addWorkSession(dayScheduledOn: WorkDay, amountOfWork: Float) {
        let workSession = TaskWorkSession(context: self.managedObjectContext!, parentTask: self, dayScheduledOn: dayScheduledOn, amountOfWork: amountOfWork)
        self.workSessions.addObject(workSession)
        dayScheduledOn.workSessions.addObject(workSession)
    }
    
    func completedWorkSession(workSession: TaskWorkSession) throws {
        if workSession.parentTask === self {
            workSession.hasBeenCompleted = true
            if self.workCompleted >= self.workLeftToDo {
                self.isComplete = true
            }
        } else {
            throw TaskError.WorkSessionDoesntBelong
        }
    }
}
