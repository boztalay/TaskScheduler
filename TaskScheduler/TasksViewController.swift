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
    
    var tasks: [Task] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.tableFooterView = UIView(frame: CGRectZero)
        
        let model = CoreDataModel(name: "TaskScheduler", bundle: NSBundle(identifier: "com.boztalay.TaskScheduler")!)
        let stack = CoreDataStack(model: model)
        
        let taskEntity = entity(name: "Task", context: stack.managedObjectContext)
        let taskRequest = FetchRequest<Task>(entity: taskEntity)
        let result = fetch(request: taskRequest, inContext: stack.managedObjectContext)
        
        if result.success && result.objects.count > 0 {
            self.tasks = result.objects
        } else {
            let task1: Task = Task(context: stack.managedObjectContext, title: "388 Homework 2", dueDate: NSDate(), priority: try! Priority.fromLevel(2), type: "Homework")
            let task2: Task = Task(context: stack.managedObjectContext, title: "473 Project Proposal Draft", dueDate: NSDate(), priority: try! Priority.fromLevel(3), type: "Project")
            let task3: Task = Task(context: stack.managedObjectContext, title: "Grocery Shopping", dueDate: NSDate(), priority: try! Priority.fromLevel(1), type: "Chore")
            let task4: Task = Task(context: stack.managedObjectContext, title: "Clean Desk", dueDate: NSDate(), priority: try! Priority.fromLevel(0), type: "Chore")
            let task5: Task = Task(context: stack.managedObjectContext, title: "Cancel Comcast", dueDate: NSDate(), priority: try! Priority.fromLevel(4), type: "Chore")
            
            self.tasks.append(task1)
            self.tasks.append(task2)
            self.tasks.append(task3)
            self.tasks.append(task4)
            self.tasks.append(task5)
            
            let saveResult = saveContextAndWait(stack.managedObjectContext)
            if !saveResult.success {
                print("Shit, couldn't save the context: \(result.error)")
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

