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
    static var entityName = "User"
    
    @NSManaged private var sunAvailableWorkTime: Float
    @NSManaged private var monAvailableWorkTime: Float
    @NSManaged private var tueAvailableWorkTime: Float
    @NSManaged private var wedAvailableWorkTime: Float
    @NSManaged private var thuAvailableWorkTime: Float
    @NSManaged private var friAvailableWorkTime: Float
    @NSManaged private var satAvailableWorkTime: Float
    @NSManaged var tasks: NSMutableSet
    @NSManaged var workDays: NSMutableSet
    
    var tasksArray: [Task] {
        return self.tasks.allObjects as! [Task]
    }
    
    var workDaysArray: [WorkDay] {
        return self.workDays.allObjects as! [WorkDay]
    }
    
    var droppedTasks: [Task] {
        return self.tasksArray.filter({ $0.dropped })
    }
    
    var notDroppedTasks: [Task] {
        return self.tasksArray.filter({ !$0.dropped })
    }
    
    var completedTasks: [Task] {
        return self.tasksArray.filter({ $0.workLeftToDo <= 0.0 })
    }
    
    var outstandingTasks: [Task] {
        return self.tasksArray.filter({ $0.workLeftToDo > 0.0 }).filter({ $0.dueDate.compare(DateUtils.todayDay()) != .OrderedAscending }).filter({ $0.isComplete == false})
    }
    
    init(context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName(User.entityName, inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
        
    func scheduleWorkTime(sun sun: Float, mon: Float, tue: Float, wed: Float, thu: Float, fri: Float, sat: Float) {
        self.sunAvailableWorkTime = sun
        self.monAvailableWorkTime = mon
        self.tueAvailableWorkTime = tue
        self.wedAvailableWorkTime = wed
        self.thuAvailableWorkTime = thu
        self.friAvailableWorkTime = fri
        self.satAvailableWorkTime = sat
    }
    
    private func workAvailableOnDate(date: NSDate) throws -> Float {
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
    
    func workDayForDate(date: NSDate) -> WorkDay {
        for workDay in self.workDays {
            if let workDay = workDay as? WorkDay {
                if workDay.date.compare(date) == .OrderedSame {
                    return workDay
                }
            }
        }
        
        let newWorkDay = WorkDay(context: self.managedObjectContext!, date: date, totalAvailableWork: try! self.workAvailableOnDate(date))
        self.workDays.addObject(newWorkDay)
        
        return newWorkDay
    }
    
    func workDayBeforeDay(day: WorkDay) -> WorkDay {
        return self.workDayForDate(DateUtils.dateBySubtractingDay(day.date))
    }
    
    func workDayAfterDay(day: WorkDay) -> WorkDay {
        return self.workDayForDate(DateUtils.dateByAddingDay(day.date))
    }
    
    func availableWorkTimeBetweenNowAnd(date date: NSDate) -> Float {
        var currentDay = DateUtils.todayDay()
        var totalAvailableWorkTime: Float = 0.0
        
        while currentDay.compare(date) == .OrderedAscending {
            let workDay = self.workDayForDate(currentDay)
            totalAvailableWorkTime += workDay.totalAvailableWork
            currentDay = DateUtils.dateByAddingDay(currentDay)
        }
        
        return totalAvailableWorkTime
    }
    
    func workToDoBetweenNowAnd(date date: NSDate) -> Float {
        return self.notDroppedTasks.filter({ $0.dueDate.compare(date) != .OrderedDescending }).map({ $0.workLeftToDo }).reduce(0.0, combine: +)
    }
    
    func resetWorkDays() {
        for workDay in self.workDays {
            if let workDay = workDay as? WorkDay {
                workDay.workSessions = []
            }
        }
    }
}
