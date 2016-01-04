//
//  GenericTaskTableViewCell.swift
//  TaskScheduler
//
//  Created by Ben Oztalay on 1/3/16.
//  Copyright © 2016 Ben Oztalay. All rights reserved.
//

import UIKit

struct TaskStateColors {
    static let NormalColor = UIColor.whiteColor()
    static let CompleteColor = UIColor(white: 0.80, alpha: 1.0)
    static let DroppedColor = UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.25)
}

class GenericTaskTableViewCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var workLabel: UILabel!
    @IBOutlet weak var dueByLabel: UILabel!
    @IBOutlet weak var priorityLabel: UILabel!
    
    static let ReuseIdentifier = "GenericTaskTableViewCell"
    static let NibName = GenericTaskTableViewCell.ReuseIdentifier
    static let Nib = UINib(nibName: GenericTaskTableViewCell.NibName, bundle: nil)
    
    private static var dateFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.formattingContext = .MiddleOfSentence
        formatter.dateStyle = .MediumStyle
        formatter.timeStyle = .NoStyle
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()

    func setFromTask(task: Task) {
        self.titleLabel.text = task.title
        
        self.workLabel.text = "\(task.workEstimate) hour"
        if task.workEstimate != 1.0 {
            self.workLabel.text! += "s"
        }
        
        self.dueByLabel.text = "Due " + GenericTaskTableViewCell.dateFormatter.stringFromDate(task.dueDate)
        self.priorityLabel.text = "\(try! PriorityPrettifier.priorityNameFromLevel(task.priority)) Priortiy"
        
        if task.isComplete {
            self.backgroundColor = TaskStateColors.CompleteColor
        } else if task.isDropped {
            self.backgroundColor = TaskStateColors.DroppedColor
        } else {
            self.backgroundColor = TaskStateColors.NormalColor
        }
    }
    
    func setFromWorkSession(workSession: TaskWorkSession) {
        let task = workSession.parentTask
        self.titleLabel.text = task.title
        
        self.workLabel.text = "For \(workSession.amountOfWork) hour"
        if workSession.amountOfWork != 1.0 {
            self.workLabel.text! += "s"
        }
        
        self.dueByLabel.text = "Due " + GenericTaskTableViewCell.dateFormatter.stringFromDate(task.dueDate)
        self.priorityLabel.text = "\(try! PriorityPrettifier.priorityNameFromLevel(task.priority)) Priortiy"
        
        if workSession.hasBeenCompleted {
            self.backgroundColor = TaskStateColors.CompleteColor
        } else if task.isDropped {
            self.backgroundColor = TaskStateColors.DroppedColor
        } else {
            self.backgroundColor = TaskStateColors.NormalColor
        }
    }
}
