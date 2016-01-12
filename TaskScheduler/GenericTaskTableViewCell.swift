//
//  GenericTaskTableViewCell.swift
//  TaskScheduler
//
//  Created by Ben Oztalay on 1/3/16.
//  Copyright © 2016 Ben Oztalay. All rights reserved.
//

import UIKit

class GenericTaskTableViewCell: UITableViewCell {
    static let ReuseIdentifier = "GenericTaskTableViewCell"
    private static let NibName = GenericTaskTableViewCell.ReuseIdentifier
    static let Nib = UINib(nibName: GenericTaskTableViewCell.NibName, bundle: nil)

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var workLabel: UILabel!
    @IBOutlet weak var statusDot: UIView!
    @IBOutlet weak var dueByLabel: UILabel!
    @IBOutlet weak var priorityLabel: UILabel!
    
    private static var dateFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.formattingContext = .MiddleOfSentence
        formatter.dateStyle = .MediumStyle
        formatter.timeStyle = .NoStyle
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()
    
    override func awakeFromNib() {
        // Make the dot into a circle
        self.statusDot.layer.cornerRadius = self.statusDot.frame.width / 2.0
    }


    func setFromTask(task: Task) {
        self.setCommonTextLabelsFromTask(task)
        
        self.workLabel.text = "\(task.workEstimate) hour"
        self.pluralizeWorkLabelForWork(task.workEstimate)
        
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
        self.pluralizeWorkLabelForWork(workSession.amountOfWork)
        
        if workSession.hasBeenCompleted {
            self.statusDot.backgroundColor = TaskSchedulerColors.TaskComplete
        } else if task.isDropped {
            self.statusDot.backgroundColor = TaskSchedulerColors.TaskDropped
        } else {
            self.statusDot.backgroundColor = TaskSchedulerColors.TaskInProgess
        }
    }
    
    private func setCommonTextLabelsFromTask(task: Task) {
        self.titleLabel.text = task.title
        self.dueByLabel.text = "Due " + GenericTaskTableViewCell.dateFormatter.stringFromDate(task.dueDate)
        self.priorityLabel.text = "\(try! PriorityPrettifier.priorityNameFromLevel(task.priority)) Priortiy"
    }
    
    private func pluralizeWorkLabelForWork(work: Float) {
        if work != 1.0 {
            self.workLabel.text! += "s"
        }
    }
    
    // These are here as a silly workaround for the dot's background
    // color being reset when the cell is selected/highlighted
    
    override func setSelected(selected: Bool, animated: Bool) {
        let dotColor = self.statusDot.backgroundColor
        super.setSelected(selected, animated: animated)
        
        if selected  {
            self.statusDot.backgroundColor = dotColor
        }
    }
    
    override func setHighlighted(highlighted: Bool, animated: Bool) {
        let dotColor = self.statusDot.backgroundColor
        super.setHighlighted(selected, animated: animated)
        
        if selected  {
            self.statusDot.backgroundColor = dotColor
        }
    }
}
