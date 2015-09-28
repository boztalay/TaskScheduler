//
//  TasksViewController.swift
//  TaskScheduler
//
//  Created by Ben Oztalay on 9/18/15.
//  Copyright © 2015 Ben Oztalay. All rights reserved.
//

import UIKit
import JSQCoreDataKit

class TasksViewController: UITableViewController {
    
    var coreDataStack: CoreDataStack?
    var tasks: [Task] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.tableFooterView = UIView(frame: CGRectZero)
        
        let model = CoreDataModel(name: "TaskScheduler", bundle: NSBundle(identifier: "com.boztalay.TaskScheduler")!)
        self.coreDataStack = CoreDataStack(model: model)
        
        if let context = self.coreDataStack?.managedObjectContext {
            let taskEntity = entity(name: "Task", context: context)
            let taskRequest = FetchRequest<Task>(entity: taskEntity)
            let result = fetch(request: taskRequest, inContext: context)
            
            if result.success && result.objects.count > 0 {
                self.tasks = result.objects
            } else {
                let task1: Task = Task(context: context, title: "388 Homework 2", dueDate: NSDate(), priority: try! Priority.fromLevel(.Medium), type: .Homework)
                let task2: Task = Task(context: context, title: "473 Project Proposal Draft", dueDate: NSDate(), priority: try! Priority.fromLevel(.Highest), type: .Project)
                let task3: Task = Task(context: context, title: "Grocery Shopping", dueDate: NSDate(), priority: try! Priority.fromLevel(.Low), type: .Chore)
                let task4: Task = Task(context: context, title: "Clean Desk", dueDate: NSDate(), priority: try! Priority.fromLevel(.Lowest), type: .Chore)
                let task5: Task = Task(context: context, title: "Cancel Comcast", dueDate: NSDate(), priority: try! Priority.fromLevel(.High), type: .Chore)
                
                self.tasks.append(task1)
                self.tasks.append(task2)
                self.tasks.append(task3)
                self.tasks.append(task4)
                self.tasks.append(task5)
                
                let saveResult = saveContextAndWait(context)
                if !saveResult.success {
                    print("Couldn't save the context: \(result.error)")
                }
        }
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tasks.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("Task Cell", forIndexPath: indexPath) as! TaskTableViewCell
        
        let task = self.tasks[indexPath.row]
        cell.setTask(task)
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.performSegueWithIdentifier("TasksToEditTask", sender: self.tasks[indexPath.row])
    }

    @IBAction func addButtonPressed(sender: AnyObject) {
        self.performSegueWithIdentifier("TasksToNewTask", sender: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let navigationController = segue.destinationViewController as? UINavigationController
        let editTaskViewController: EditTaskViewController
        
        if let navigationController = navigationController {
            editTaskViewController = navigationController.viewControllers.first as! EditTaskViewController
        } else {
            editTaskViewController = segue.destinationViewController as! EditTaskViewController
        }
        
        if segue.identifier == "TasksToEditTask" {
            editTaskViewController.task = sender as? Task!
        }
        
        editTaskViewController.coreDataStack = coreDataStack
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

