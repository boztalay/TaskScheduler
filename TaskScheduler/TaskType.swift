//
//  TaskType.swift
//  TaskScheduler
//
//  Created by Ben Oztalay on 9/28/15.
//  Copyright © 2015 Ben Oztalay. All rights reserved.
//

import UIKit

enum TaskType: String {
    case Chore, Project, Homework, Exercise
    
    static var count: Int {
        return 4
    }
}
