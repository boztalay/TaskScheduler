//
//  WorkDay.swift
//  TaskScheduler
//
//  Created by Ben Oztalay on 10/12/15.
//  Copyright © 2015 Ben Oztalay. All rights reserved.
//

import Foundation
import CoreData

class WorkDay: NSManagedObject {
    // The CoreData entity name to use for this class
    static var entityName = "WorkDay"
    
    // The user that owns this work day
    @NSManaged var parentUser: User
    
    // The date that this work day is for
    @NSManaged var date: NSDate
    
    // The total number of hours of work available
    // to be scheduled on this work day
    @NSManaged var totalAvailableWorkNum: NSNumber
    
    // A set of TaskWorkSessions that are scheduled
    // to be done on this work day
    @NSManaged var workSessions: NSSet

    // A convenience accessor for totalAvailableWorkNum
    var totalAvailableWork: Float {
        set(newTotalAvailableWork) {
            self.totalAvailableWorkNum = NSNumber(float: newTotalAvailableWork)
        }
        get {
            return self.totalAvailableWorkNum.floatValue
        }
    }
    
    // An unordered array of all of the TaskWorkSessions
    var workSessionsArray: [TaskWorkSession] {
        return Array(self.workSessions as! Set<TaskWorkSession>)
    }
    
    // The number of hours of work that have been
    // scheduled for this work day (completed or not)
    var workScheduled: Float {
        return self.workSessionsArray.map({ $0.amountOfWork }).reduce(0.0, combine: +)
    }
    
    // The number of hours in the work day that are
    // still available to be scheduled
    var workLeftToBeScheduled: Float {
        return (self.totalAvailableWork - self.workScheduled)
    }
    
    // Adds the given TaskWorkSession to this work day
    func addWorkSession(workSession: TaskWorkSession) {
        self.workSessions = self.workSessions.setByAddingObject(workSession)
    }
    
    // Makes a new WorkDay and inserts it into the context
    convenience init(context: NSManagedObjectContext, date: NSDate, totalAvailableWork: Float) {
        let entity = NSEntityDescription.entityForName(WorkDay.entityName, inManagedObjectContext: context)!
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.date = date
        self.totalAvailableWork = totalAvailableWork
    }
    
    // Removes all of the incomplete work sessions from this work day and returns them
    func removeIncompleteWorkSessions() -> [TaskWorkSession] {
        let incompleteWorkSessions = self.workSessionsArray.filter({ !$0.hasBeenCompleted })
        self.workSessions = NSMutableSet.init(array: self.workSessionsArray.filter({ $0.hasBeenCompleted }))
        
        return incompleteWorkSessions
    }
}
