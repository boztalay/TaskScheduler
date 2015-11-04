//
//  TaskTableViewCell.swift
//  TaskScheduler
//
//  Created by Ben Oztalay on 9/18/15.
//  Copyright © 2015 Ben Oztalay. All rights reserved.
//

import UIKit

class WorkSessionTableViewCell: UITableViewCell {
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

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func setWorkSession(workSession: TaskWorkSession) {
        let task = workSession.parentTask
        self.titleLabel.text = "\(task.title) for \(workSession.amountOfWork) hours"
        self.dueByLabel.text = "Due " + WorkSessionTableViewCell.dateFormatter.stringFromDate(task.dueDate)
        self.priorityLabel.text = String(task.priority)
        self.typeLabel.text = task.type
    }
}
