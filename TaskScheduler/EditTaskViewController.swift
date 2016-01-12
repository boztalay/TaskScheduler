//
//  EditTaskViewController.swift
//  TaskScheduler
//
//  Created by Ben Oztalay on 9/28/15.
//  Copyright © 2015 Ben Oztalay. All rights reserved.
//

import UIKit
import JSQCoreDataKit

class EditTaskViewController: UITableViewController, UITextFieldDelegate {
    
    let persistenceController = PersistenceManager.sharedInstance

    var user: User?
    var task: Task?
    var isEditingTask: Bool = false
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var workEstimateTextField: UITextField!
    @IBOutlet weak var prioritySlider: UISlider!
    @IBOutlet weak var dueDatePicker: UIDatePicker!

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
        self.dueDatePicker.minimumDate = DateUtils.tomorrowDay()
    }
    
    func setUpForNewTask() {
        self.title = "New Task"
    }
    
    func setUpForExistingTask() {
        self.title = "Edit Task"
        self.navigationItem.leftBarButtonItem = nil
        
        self.titleTextField.text = task!.title
        self.workEstimateTextField.text = String(task!.workEstimate)
        self.prioritySlider.value = Float(task!.priority)
        self.dueDatePicker.date = task!.dueDate
    }

    @IBAction func prioritySliderValueChanged(sender: AnyObject) {
        self.prioritySlider!.value = round(self.prioritySlider!.value)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField === self.titleTextField {
            self.workEstimateTextField.becomeFirstResponder()
        } else if textField === self.workEstimateTextField {
            self.workEstimateTextField.resignFirstResponder()
        }
        
        return true
    }

    @IBAction func cancelButtonPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func doneButtonPressed(sender: AnyObject) {
        self.view.endEditing(true)
        
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
        if date.compare(DateUtils.tomorrowDay()) == NSComparisonResult.OrderedAscending {
            let alert = UIAlertController(title: "Past Date", message: "Hey! The due date needs to be in the future!", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Sorry", style: .Cancel, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
            return
        }
        
        let priority = Int(round(self.prioritySlider.value))
        
        // Make or set the task accordingly
        
        if !self.isEditingTask {
            self.task = Task(context: self.persistenceController.coreDataStack!.managedObjectContext, title: self.titleTextField!.text!, dueDate: date, priority: priority, workEstimate: workEstimate!)
        } else {
            self.task!.title = self.titleTextField!.text!
            self.task!.dueDate = date
            self.task!.priority = priority
            self.task!.workEstimate = workEstimate!
        }
        
        self.user!.addTask(self.task!)
        
        // Save the context
        
        try! self.persistenceController.saveDataAndWait()
        
        // Peace out (in two different ways)
        
        self.dismissViewControllerAnimated(true, completion: nil)
        self.navigationController!.popViewControllerAnimated(true)
    }
}
