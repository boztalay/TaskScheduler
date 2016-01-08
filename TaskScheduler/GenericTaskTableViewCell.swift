//
//  GenericTaskTableViewCell.swift
//  TaskScheduler
//
//  Created by Ben Oztalay on 1/3/16.
//  Copyright © 2016 Ben Oztalay. All rights reserved.
//

import UIKit

class GenericTaskTableViewCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var workLabel: UILabel!
    @IBOutlet weak var statusDot: UIView!
    @IBOutlet weak var dueByLabel: UILabel!
    @IBOutlet weak var priorityLabel: UILabel!
    
    static let ReuseIdentifier = "GenericTaskTableViewCell"
    private static let NibName = GenericTaskTableViewCell.ReuseIdentifier
    static let Nib = UINib(nibName: GenericTaskTableViewCell.NibName, bundle: nil)
    
    private static var dateFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.formattingContext = .MiddleOfSentence
        formatter.dateStyle = .MediumStyle
        formatter.timeStyle = .NoStyle
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()
    
    override func awakeFromNib() {
        self.statusDot.layer.cornerRadius = self.statusDot.frame.width / 2.0
    }
    
    private func setCommonTextLabelsFromTask(task: Task) {
        self.titleLabel.text = task.title
        self.dueByLabel.text = "Due " + GenericTaskTableViewCell.dateFormatter.stringFromDate(task.dueDate)
        self.priorityLabel.text = "\(try! PriorityPrettifier.priorityNameFromLevel(task.priority)) Priortiy"
    }

    func setFromTask(task: Task) {
        self.setCommonTextLabelsFromTask(task)
        
        self.workLabel.text = "\(task.workEstimate) hour"
        if task.workEstimate != 1.0 {
            self.workLabel.text! += "s"
        }
        
        if task.isComplete {
            self.statusDot.backgroundColor = TaskSchedulerColors.TaskComplete
        } else if task.isDueInPast && !task.isComplete {
            self.statusDot.backgroundColor = TaskSchedulerColors.TaskIncomplete
        } else if task.isDropped {
            self.statusDot.backgroundColor = TaskSchedulerColors.TaskDropped
        } else {
            self.statusDot.backgroundColor = TaskSchedulerColors.TaskInProgess
        }
    }
    
    func setFromWorkSession(workSession: TaskWorkSession) {
        let task = workSession.parentTask
        self.setCommonTextLabelsFromTask(task)
        
        self.workLabel.text = "For \(workSession.amountOfWork) hour"
        if workSession.amountOfWork != 1.0 {
            self.workLabel.text! += "s"
        }
        
        if workSession.hasBeenCompleted {
            self.statusDot.backgroundColor = TaskSchedulerColors.TaskComplete
        } else if task.isDropped {
            self.statusDot.backgroundColor = TaskSchedulerColors.TaskDropped
        } else {
            self.statusDot.backgroundColor = TaskSchedulerColors.TaskInProgess
        }
    }
}
