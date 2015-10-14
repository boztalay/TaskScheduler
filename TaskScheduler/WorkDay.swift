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
    static var entityName = "WorkDay"
    
    @NSManaged var date: NSDate
    @NSManaged var totalAvailableWork: Float
    @NSManaged var workSessions: NSMutableSet
    
    var workSessionsArray: [TaskWorkSession] {
        return self.workSessions.allObjects as! [TaskWorkSession]
    }
    
    var workScheduled: Float {
        return self.workSessionsArray.map({ $0.amountOfWork }).reduce(0.0, combine: +)
    }
    
    var workLeftToBeScheduled: Float {
        return (self.totalAvailableWork - self.workScheduled)
    }
    
    init(context: NSManagedObjectContext, date: NSDate, totalAvailableWork: Float) {
        let entity = NSEntityDescription.entityForName(WorkDay.entityName, inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.date = date
        self.totalAvailableWork = totalAvailableWork
    }
}
