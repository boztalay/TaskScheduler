//
//  ScheduleConfirmationViewController.swift
//  TaskScheduler
//
//  Created by Ben Oztalay on 1/2/16.
//  Copyright © 2016 Ben Oztalay. All rights reserved.
//

import UIKit

protocol ScheduleConfirmationDelegate {
    func scheduleConfirmationComplete()
}

class ScheduleConfirmationViewController: UITableViewController {

    var user: User?
    var delegate: ScheduleConfirmationDelegate?
    
    override func viewDidLoad() {
        // Set stuff up
    }
}
