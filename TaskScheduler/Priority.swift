//
//  Priority.swift
//  TaskScheduler
//
//  Created by Ben Oztalay on 9/18/15.
//  Copyright © 2015 Ben Oztalay. All rights reserved.
//

import UIKit

class Priority: NSObject {
    
    let name: String
    let level: UInt8
    
    init?(name: String, level: UInt8) {
        self.name = name
        self.level = level
    }
}
