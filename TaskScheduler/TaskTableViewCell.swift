//
//  TaskTableViewCell.swift
//  TaskScheduler
//
//  Created by Ben Oztalay on 12/21/15.
//  Copyright © 2015 Ben Oztalay. All rights reserved.
//

import UIKit

class TaskTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dueByLabel: UILabel!
    @IBOutlet weak var priorityLabel: UILabel!
    @IBOutlet weak var typeLabel: UILabel!
    
    private static var dateFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.formattingContext = .MiddleOfSentence
        formatter.dateStyle = .MediumStyle
        formatter.timeStyle = .NoStyle
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()
    
    func setTask(task: Task) {
        self.titleLabel.text = "\(task.title) (\(task.workEstimate) hours)"
        self.dueByLabel.text = "Due " + TaskTableViewCell.dateFormatter.stringFromDate(task.dueDate)
        self.priorityLabel.text = String(task.priority)
        self.typeLabel.text = task.type
    }
}
