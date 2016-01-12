//
//  DateUtils.swift
//  TaskScheduler
//
//  Created by Ben Oztalay on 10/12/15.
//  Copyright © 2015 Ben Oztalay. All rights reserved.
//

import Foundation

class DateUtils {
    // Returns an NSDate for today, without any time components
    static func todayDay() -> NSDate {
        return DateUtils.removeTimeFromDate(NSDate())
    }
    
    // Returns an NSDate for tomorrow, without any time components
    static func tomorrowDay() -> NSDate {
        return DateUtils.dateByAddingDay(DateUtils.todayDay())
    }
    
    // Returns an NSDate 24 hours in the future from the given date
    static func dateByAddingDay(date: NSDate) -> NSDate {
        return date.dateByAddingTimeInterval(24 * 60 * 60)
    }
    
    // Returns an NSDate 24 hours in the past from the given date
    static func dateBySubtractingDay(date: NSDate) -> NSDate {
        return date.dateByAddingTimeInterval(-24 * 60 * 60)
    }
    
    // Strips the given date of its time components
    static func removeTimeFromDate(date: NSDate) -> NSDate {
        return NSCalendar.currentCalendar().dateBySettingHour(0, minute: 0, second: 0, ofDate: date, options: NSCalendarOptions(rawValue: 0))!
    }
}
