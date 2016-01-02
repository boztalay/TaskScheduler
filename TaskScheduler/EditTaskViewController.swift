//
//  EditTaskViewController.swift
//  TaskScheduler
//
//  Created by Ben Oztalay on 9/28/15.
//  Copyright © 2015 Ben Oztalay. All rights reserved.
//

import UIKit
import JSQCoreDataKit

class EditTaskViewController: UITableViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    
    let persistenceController = PersistenceController.sharedInstance

    var user: User?
    var task: Task?
    var isEditingTask: Bool = false
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var workEstimateTextField: UITextField!
    @IBOutlet weak var dueDatePicker: UIDatePicker!
    @IBOutlet weak var priorityPicker: UIPickerView!
    @IBOutlet weak var typePicker: UIPickerView!
    
    let taskTypes: [String] = ["Chore", "Homework", "Project", "Exercise"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let _ = self.task {
            self.isEditingTask = true
        }

        self.doCommonSetup()
        
        if self.isEditingTask {
            self.setUpForExistingTask()
        } else {
            self.setUpForNewTask()
        }
    }
    
    func doCommonSetup() {
        self.priorityPicker!.dataSource = self
        self.priorityPicker!.delegate = self
        self.typePicker!.dataSource = self
        self.typePicker!.delegate = self
    }
    
    func setUpForNewTask() {
        self.title = "New Task"
    }
    
    func setUpForExistingTask() {
        self.title = "Edit Task"
        self.navigationItem.leftBarButtonItem = nil
        
        self.titleTextField.text = task!.title
        self.workEstimateTextField.text = String(task!.workEstimate)
        self.dueDatePicker.date = task!.dueDate
        self.priorityPicker!.selectRow(Int(task!.priority), inComponent: 0, animated: false)
        self.typePicker!.selectRow(self.taskTypes.indexOf(self.task!.type)!, inComponent: 0, animated: false)
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == self.priorityPicker! {
            return PriorityLevel.count
        } else if pickerView == self.typePicker {
            return TaskType.count
        } else {
            return 0
        }
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == self.priorityPicker! {
            return String(row)
        } else if pickerView == self.typePicker {
            return self.taskTypes[row]
        } else {
            return ""
        }
    }

    @IBAction func cancelButtonPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func doneButtonPressed(sender: AnyObject) {
        // Validate everything
        
        if self.titleTextField!.text == nil || self.titleTextField!.text!.isEmpty {
            let alert = UIAlertController(title: "Empty Title", message: "Hey! Enter a title for this task!", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Fine.", style: .Cancel, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
            return
        }
        
        if self.workEstimateTextField!.text == nil || self.workEstimateTextField!.text!.isEmpty {
            let alert = UIAlertController(title: "Empty Estimate", message: "Hey! Enter a work estimate for this task!", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Ugh ok", style: .Cancel, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
            return
        }
        
        let workEstimate = Float(self.workEstimateTextField!.text!)
        if workEstimate == nil {
            let alert = UIAlertController(title: "Bad Estimate", message: "Hey! That work estimate doesn't look like a number!", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Ugh ok", style: .Cancel, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
            return
        }
        
        let date = DateUtils.removeTimeFromDate(self.dueDatePicker!.date)
        if date.compare(DateUtils.todayDay()) == NSComparisonResult.OrderedAscending {
            let alert = UIAlertController(title: "Past Date", message: "Hey! This date is in the past!", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Sorry", style: .Cancel, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
            return
        }
        
        let priority = self.priorityPicker!.selectedRowInComponent(0)
        let type = self.taskTypes[self.typePicker!.selectedRowInComponent(0)]
        
        // Make or set the task accordingly
        
        if !self.isEditingTask {
            self.task = Task(context: self.persistenceController.coreDataStack!.managedObjectContext, title: self.titleTextField!.text!, dueDate: date, priority: priority, type: type, workEstimate: workEstimate!)
        } else {
            self.task!.title = self.titleTextField!.text!
            self.task!.dueDate = date
            self.task!.priority = priority
            self.task!.workEstimate = workEstimate!
            self.task!.type = type
        }
        
        self.user!.addTask(self.task!)
        
        // Save the context
        
        if !self.persistenceController.saveDataAndWait() {
            print("Couldn't save the data")
        }
        
        // Peace out (in two different ways)
        
        self.dismissViewControllerAnimated(true, completion: nil)
        self.navigationController!.popViewControllerAnimated(true)
    }
}
