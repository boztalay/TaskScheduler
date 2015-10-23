//
//  User.swift
//  TaskScheduler
//
//  Created by Ben Oztalay on 10/12/15.
//  Copyright © 2015 Ben Oztalay. All rights reserved.
//

import Foundation
import CoreData

enum UserError: ErrorType {
    case BadDayOfWeekError
}

class User: NSManagedObject {
    // The CoreData entity name to use for this class
    static var entityName = "User"
    
    // The number of hours of work available on Sundays
    @NSManaged private var sunAvailableWorkTime: Float
    
    // The number of hours of work available on Mondays
    @NSManaged private var monAvailableWorkTime: Float
    
    // The number of hours of work available on Tuesdays
    @NSManaged private var tueAvailableWorkTime: Float
    
    // The number of hours of work available on Wednesdays
    @NSManaged private var wedAvailableWorkTime: Float
    
    // The number of hours of work available on Thursdays
    @NSManaged private var thuAvailableWorkTime: Float
    
    // The number of hours of work available on Fridays
    @NSManaged private var friAvailableWorkTime: Float
    
    // The number of hours of work available on Saturdays
    @NSManaged private var satAvailableWorkTime: Float
    
    // A set of Tasks to be done
    @NSManaged var tasks: NSMutableSet
    
    // A set of WorkDays to schedule tasks on
    @NSManaged var workDays: NSMutableSet
    
    // An unordered array of all of the tasks
    var tasksArray: [Task] {
        return self.tasks.allObjects as! [Task]
    }
    
    // An unordered array of all of the work days
    var workDaysArray: [WorkDay] {
        return self.workDays.allObjects as! [WorkDay]
    }
    
    // An unordered array of all of the dropped tasks
    var droppedTasks: [Task] {
        return self.tasksArray.filter({ $0.dropped })
    }
    
    // An unordered array of all of the not dropped tasks
    var notDroppedTasks: [Task] {
        return self.tasksArray.filter({ !$0.dropped })
    }
    
    // An unordered array of all of the completed tasks
    var completedTasks: [Task] {
        return self.tasksArray.filter({ $0.workLeftToDo <= 0.0 || $0.isComplete })
    }
    
    // An unordered array of all of the tasks that still need to be done
    var outstandingTasks: [Task] {
        return self.tasksArray.filter({ $0.workLeftToDo > 0.0 && $0.isComplete == false && !$0.isDueInPast})
    }
    
    // Makes a new User and inserts it into the context
    init(context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName(User.entityName, inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    // Sets the amount of work available to be scheduled on all days of the week
    func scheduleWorkTime(sun sun: Float, mon: Float, tue: Float, wed: Float, thu: Float, fri: Float, sat: Float) {
        self.sunAvailableWorkTime = sun
        self.monAvailableWorkTime = mon
        self.tueAvailableWorkTime = tue
        self.wedAvailableWorkTime = wed
        self.thuAvailableWorkTime = thu
        self.friAvailableWorkTime = fri
        self.satAvailableWorkTime = sat
    }
    
    // The amount of work available to be scheduled on a given date,
    // according to the work time scheduled by weekday
    func totalAvailableWorkOnDate(date: NSDate) throws -> Float {
        let dayOfWeek = NSCalendar.currentCalendar().components(NSCalendarUnit.Weekday, fromDate: date).weekday
        switch dayOfWeek {
            case 1: return self.sunAvailableWorkTime
            case 2: return self.monAvailableWorkTime
            case 3: return self.tueAvailableWorkTime
            case 4: return self.wedAvailableWorkTime
            case 5: return self.thuAvailableWorkTime
            case 6: return self.friAvailableWorkTime
            case 7: return self.satAvailableWorkTime
            default: throw UserError.BadDayOfWeekError
        }
    }
    
    // Returns the WorkDay for the given date, creating a new
    // one if one doesn't exist
    func workDayForDate(date: NSDate) -> WorkDay {
        for workDay in self.workDays {
            if let workDay = workDay as? WorkDay {
                if workDay.date.compare(date) == .OrderedSame {
                    return workDay
                }
            }
        }
        
        let newWorkDay = WorkDay(context: self.managedObjectContext!, date: date, totalAvailableWork: try! self.totalAvailableWorkOnDate(date))
        self.workDays.addObject(newWorkDay)
        
        return newWorkDay
    }

    // Returns the WorkDay just before the given WorkDay,
    // creating a new one if needed
    func workDayBeforeDay(day: WorkDay) -> WorkDay {
        return self.workDayForDate(DateUtils.dateBySubtractingDay(day.date))
    }
    
    // Returns the WorkDay just after the given WorkDay,
    // creating a new one if needed
    func workDayAfterDay(day: WorkDay) -> WorkDay {
        return self.workDayForDate(DateUtils.dateByAddingDay(day.date))
    }
    
    // Calculates the amount of work time available to be scheduled 
    // between now and the given date
    func availableWorkTimeBetweenNowAnd(date date: NSDate) -> Float {
        var currentDay = DateUtils.todayDay()
        var totalAvailableWorkTime: Float = 0.0
        
        while currentDay.compare(date) == .OrderedAscending {
            let workDay = self.workDayForDate(currentDay)
            totalAvailableWorkTime += workDay.workLeftToBeScheduled
            currentDay = DateUtils.dateByAddingDay(currentDay)
        }
        
        return totalAvailableWorkTime
    }
    
    // Calculates the amount of work to do between now and the given date
    func workToDoBetweenNowAnd(date date: NSDate) -> Float {
        return self.notDroppedTasks.filter({ !$0.isDueInPast }).map({ $0.workLeftToDo }).reduce(0.0, combine: +)
    }
    
    // Removes all of the incomplete work sessions from all of
    // this user's work days, to prepare for the scheduler
    func resetWorkDays() {
        for workDay in self.workDays {
            if let workDay = workDay as? WorkDay {
                workDay.workSessions = NSMutableSet.init(array: workDay.workSessionsArray.filter({ $0.hasBeenCompleted }))
            }
        }
    }
}
