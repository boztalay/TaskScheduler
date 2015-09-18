//
//  TasksViewController.swift
//  TaskScheduler
//
//  Created by Ben Oztalay on 9/18/15.
//  Copyright © 2015 Ben Oztalay. All rights reserved.
//

import UIKit

class TasksViewController: UITableViewController {
    
    var tasks: [Task] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.tableFooterView = UIView(frame: CGRectZero)

        let task1: Task = Task(title: "388 Homework 2", dueDate: NSDate(), priority: Priority(name: "Medium", level: 3)!, type: "Homework")!
        let task2: Task = Task(title: "473 Project Proposal Draft", dueDate: NSDate(), priority: Priority(name: "High", level: 4)!, type: "Project")!
        let task3: Task = Task(title: "Grocery Shopping", dueDate: NSDate(), priority: Priority(name: "Low", level: 2)!, type: "Chore")!
        let task4: Task = Task(title: "Clean Desk", dueDate: NSDate(), priority: Priority(name: "Lowest", level: 1)!, type: "Chore")!
        let task5: Task = Task(title: "Cancel Comcast", dueDate: NSDate(), priority: Priority(name: "Highest", level: 5)!, type: "Chore")!
        
        self.tasks.append(task1)
        self.tasks.append(task2)
        self.tasks.append(task3)
        self.tasks.append(task4)
        self.tasks.append(task5)
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

