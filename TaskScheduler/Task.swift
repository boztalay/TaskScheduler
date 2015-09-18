//
//  Task.swift
//  TaskScheduler
//
//  Created by Ben Oztalay on 9/18/15.
//  Copyright © 2015 Ben Oztalay. All rights reserved.
//

import UIKit

class Task: NSObject {
    
    let title: String
    let dueDate: NSDate
    let priority: Priority
    let type: String
    
    init?(title: String, dueDate: NSDate, priority: Priority, type: String) {
        self.title = title
        self.dueDate = dueDate
        self.priority = priority
        self.type = type
    }
}
