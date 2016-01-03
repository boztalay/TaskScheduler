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

struct AvailableWorkSchedule {
    var sundayWork: Float = 0.0
    var mondayWork: Float = 0.0
    var tuesdayWork: Float = 0.0
    var wednesdayWork: Float = 0.0
    var thursdayWork: Float = 0.0
    var fridayWork: Float = 0.0
    var saturdayWork: Float = 0.0
}

class User: NSManagedObject {
    // The CoreData entity name to use for this class
    static var entityName = "User"
    
    // The number of hours of work available on Sundays
    @NSManaged var sunAvailableWorkTime: NSNumber
    
    // The number of hours of work available on Mondays
    @NSManaged var monAvailableWorkTime: NSNumber
    
    // The number of hours of work available on Tuesdays
    @NSManaged var tueAvailableWorkTime: NSNumber
    
    // The number of hours of work available on Wednesdays
    @NSManaged var wedAvailableWorkTime: NSNumber
    
    // The number of hours of work available on Thursdays
    @NSManaged var thuAvailableWorkTime: NSNumber
    
    // The number of hours of work available on Fridays
    @NSManaged var friAvailableWorkTime: NSNumber
    
    // The number of hours of work available on Saturdays
    @NSManaged var satAvailableWorkTime: NSNumber
    
    // A set of Tasks to be done
    @NSManaged var tasks: NSSet
    
    // A set of WorkDays to schedule tasks on
    @NSManaged var workDays: NSSet
    
    // An unordered array of all of the tasks
    var tasksArray: [Task] {
        return Array(self.tasks as! Set<Task>)
    }
    
    // An unordered array of all of the work days
    var workDaysArray: [WorkDay] {
        return Array(self.workDays as! Set<WorkDay>)
    }
    
    // An unordered array of all of the dropped tasks
    
    var droppedTasks: [Task] {
        return self.tasksArray.filter({ $0.isDropped })
    }
    
    // An unordered array of all of the not dropped tasks
    var notDroppedTasks: [Task] {
        return self.tasksArray.filter({ !$0.isDropped })
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
    convenience init(context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName(User.entityName, inManagedObjectContext: context)!
        self.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    // Sets the amount of work available to be scheduled on all days of the week
    func scheduleWorkTime(workSchedule: AvailableWorkSchedule) {
        self.sunAvailableWorkTime = NSNumber(float: workSchedule.sundayWork)
        self.monAvailableWorkTime = NSNumber(float: workSchedule.mondayWork)
        self.tueAvailableWorkTime = NSNumber(float: workSchedule.tuesdayWork)
        self.wedAvailableWorkTime = NSNumber(float: workSchedule.wednesdayWork)
        self.thuAvailableWorkTime = NSNumber(float: workSchedule.thursdayWork)
        self.friAvailableWorkTime = NSNumber(float: workSchedule.fridayWork)
        self.satAvailableWorkTime = NSNumber(float: workSchedule.saturdayWork)
    }
    
    // Adds the given Task to the set of tasks to do
    func addTask(task: Task) {
        self.tasks = self.tasks.setByAddingObject(task)
    }
    
    // Adds the given WorkDay to the set of work days
    func addWorkDay(workDay: WorkDay) {
        self.workDays = self.workDays.setByAddingObject(workDay)
    }
    
    // The amount of work available to be scheduled on a given date,
    // according to the work time scheduled by weekday
    func totalAvailableWorkOnDate(date: NSDate) throws -> Float {
        let dayOfWeek = NSCalendar.currentCalendar().components(NSCalendarUnit.Weekday, fromDate: date).weekday
        switch dayOfWeek {
            case 1: return self.sunAvailableWorkTime.floatValue
            case 2: return self.monAvailableWorkTime.floatValue
            case 3: return self.tueAvailableWorkTime.floatValue
            case 4: return self.wedAvailableWorkTime.floatValue
            case 5: return self.thuAvailableWorkTime.floatValue
            case 6: return self.friAvailableWorkTime.floatValue
            case 7: return self.satAvailableWorkTime.floatValue
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
        self.addWorkDay(newWorkDay)
        
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
    
    // Returns the WorkDay for today
    func todayWorkDay() -> WorkDay {
        return self.workDayForDate(DateUtils.todayDay())
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
        return self.notDroppedTasks.filter({ $0.isDueOnOrBefore(date) && !$0.isDueInPast }).map({ $0.workLeftToDo }).reduce(0.0, combine: +)
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
