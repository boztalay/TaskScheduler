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

    var coreDataStack: CoreDataStack?
    var task: Task?
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var dueDatePicker: UIDatePicker!
    @IBOutlet weak var priorityPicker: UIPickerView!
    @IBOutlet weak var typePicker: UIPickerView!
    
    var taskTypes: [TaskType] = [] // This is a silly hack
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.doCommonSetup()
        
        if let _ = self.task {
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
        
        self.taskTypes.append(.Chore)
        self.taskTypes.append(.Homework)
        self.taskTypes.append(.Project)
        self.taskTypes.append(.Exercise)
    }
    
    func setUpForNewTask() {
        self.title = "New Task"
    }
    
    func setUpForExistingTask() {
        self.title = "Edit Task"
        self.navigationItem.leftBarButtonItem = nil
        
        self.titleTextField.text = task!.title
        self.dueDatePicker.date = task!.dueDate
        self.priorityPicker!.selectRow(Int(task!.priority.level.rawValue), inComponent: 0, animated: false)
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
            return try! Priority.fromLevel(PriorityLevel(rawValue: Int16(row))!).name
        } else if pickerView == self.typePicker {
            return self.taskTypes[row].rawValue
        } else {
            return ""
        }
    }

    @IBAction func cancelButtonPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func doneButtonPressed(sender: AnyObject) {
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
