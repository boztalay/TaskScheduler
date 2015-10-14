//
//  DateUtils.swift
//  TaskScheduler
//
//  Created by Ben Oztalay on 10/12/15.
//  Copyright © 2015 Ben Oztalay. All rights reserved.
//

import Foundation

class DateUtils {
    
    static func todayDay() -> NSDate {
        let calendar = NSCalendar.currentCalendar()
        return calendar.dateFromComponents(calendar.components([.Year, .Month, .Day], fromDate: NSDate()))!
    }
    
    static func dateByAddingDay(date: NSDate) -> NSDate {
        return date.dateByAddingTimeInterval(24 * 60 * 60)
    }
    
    static func dateBySubtractingDay(date: NSDate) -> NSDate {
        return date.dateByAddingTimeInterval(-24 * 60 * 60)
    }
}