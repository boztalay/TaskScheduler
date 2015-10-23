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
    
    // The date that this work day is for
    @NSManaged var date: NSDate
    
    // The total number of hours of work available
    // to be scheduled on this work day
    @NSManaged var totalAvailableWork: Float
    
    // A set of TaskWorkSessions that are scheduled
    // to be done on this work day
    @NSManaged var workSessions: NSMutableSet

    // An unordered array of all of the TaskWorkSessions
    var workSessionsArray: [TaskWorkSession] {
        return self.workSessions.allObjects as! [TaskWorkSession]
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
    
    // Makes a new WorkDay and inserts it into the context
    init(context: NSManagedObjectContext, date: NSDate, totalAvailableWork: Float) {
        let entity = NSEntityDescription.entityForName(WorkDay.entityName, inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.date = date
        self.totalAvailableWork = totalAvailableWork
    }
}
