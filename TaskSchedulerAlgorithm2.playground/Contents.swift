//: Playground - noun: a place where people can play

import UIKit

// Things to test:
//      A bunch of tasks due within a few days of each other
//      Splitting long tasks over several days
//      Conforming to when the user says they can work on tasks
//      Many tasks spread out over a long period of time (over a few months)
//      Dropping lower-priority tasks in favor of higher priority ones (if it comes down to that)
//      Not dropping tasks that don't need to be dropped

// Schedule working time

let workTime: [Float] = [
    4.0,    // Hours available on Sunday
    9.0,    // Hours available on Monday
    7.0,    // Hours available on Tuesday
    9.0,    // Hours available on Wednesday
    4.0,    // Hours available on Thursday
    5.5,    // Hours available on Friday
    4.0,    // Hours available on Saturday
]

// Task classes

class Task {
    var title: String
    var dueDate: NSDate
    var priority: Int
    var workEstimate: Float
    var subTasks: [SubTask]
    
    init(title: String, dueDate: NSDate, priority: Int, workEstimate: Float) {
        self.title = title
        self.dueDate = dueDate
        self.priority = priority
        self.workEstimate = workEstimate
        self.subTasks = []
    }
    
    func addSubtaskWithWork(workEstimate: Float) -> SubTask {
        let subTask = SubTask(self, workEstimate: workEstimate)
        self.subTasks.append(subTask)
        return subTask
    }
    
    var totalSubtaskWork: Float {
        return self.subTasks.map({ $0.workEstimate }).reduce(0.0, combine: +)
    }
    
    var workNotInSubtasks: Float {
        return self.workEstimate - self.totalSubtaskWork
    }
}

class SubTask: Task {
    var parentTask: Task
    
    init(_ parentTask: Task, workEstimate: Float) {
        self.parentTask = parentTask
        
        let title = self.parentTask.title + " - \(workEstimate) hours"
        super.init(title: title, dueDate: self.parentTask.dueDate, priority: self.parentTask.priority, workEstimate: workEstimate)
    }
}

// Class to keep track of tasks scheduled on certain days

class DayTasks {
    var date: NSDate
    var tasks: [Task]
    
    var estimatedWork: Float {
        return self.tasks.map({ $0.workEstimate }).reduce(0.0, combine: +)
    }
    
    var availableWork: Float {
        return (self.totalAvailableWork - estimatedWork)
    }
    
    var totalAvailableWork: Float {
        let dayOfWeek = NSCalendar.currentCalendar().components(NSCalendarUnit.Weekday, fromDate: self.date).weekday - 1
        return workTime[dayOfWeek]
    }
    
    init(date: NSDate) {
        self.date = date
        self.tasks = []
    }
    
    func addTask(task: Task) {
        self.tasks.append(task)
    }
    
    func getTasks() -> [Task] {
        return self.tasks
    }
}

// Global list of tasks

var tasks: [Task] = []

// Make a date formatter for easy date creation

let dateFormatter = NSDateFormatter()
dateFormatter.dateFormat = "yyyy-MM-dd"

// Add a bunch of short tasks (mixed priority) to the list

tasks.append(Task(title: "Short Task 0", dueDate: dateFormatter.dateFromString("2015-10-01")!, priority: 0, workEstimate: 0.5))
tasks.append(Task(title: "Short Task 1", dueDate: dateFormatter.dateFromString("2015-10-01")!, priority: 1, workEstimate: 1.0))
tasks.append(Task(title: "Short Task 2", dueDate: dateFormatter.dateFromString("2015-10-01")!, priority: 2, workEstimate: 0.25))
tasks.append(Task(title: "Short Task 3", dueDate: dateFormatter.dateFromString("2015-10-02")!, priority: 3, workEstimate: 1.5))
tasks.append(Task(title: "Short Task 4", dueDate: dateFormatter.dateFromString("2015-10-02")!, priority: 4, workEstimate: 0.75))
tasks.append(Task(title: "Short Task 5", dueDate: dateFormatter.dateFromString("2015-10-03")!, priority: 3, workEstimate: 0.5))
tasks.append(Task(title: "Short Task 6", dueDate: dateFormatter.dateFromString("2015-10-03")!, priority: 0, workEstimate: 1.0))
tasks.append(Task(title: "Short Task 7", dueDate: dateFormatter.dateFromString("2015-10-05")!, priority: 1, workEstimate: 1.0))
tasks.append(Task(title: "Short Task 8", dueDate: dateFormatter.dateFromString("2015-10-06")!, priority: 2, workEstimate: 0.25))
tasks.append(Task(title: "Short Task 9", dueDate: dateFormatter.dateFromString("2015-10-06")!, priority: 4, workEstimate: 0.5))

// Add some medium-length tasks (mixed priority) to the list

tasks.append(Task(title: "Medium Task 0", dueDate: dateFormatter.dateFromString("2015-10-01")!, priority: 4, workEstimate: 3.0))
tasks.append(Task(title: "Medium Task 1", dueDate: dateFormatter.dateFromString("2015-10-01")!, priority: 3, workEstimate: 4.0))
tasks.append(Task(title: "Medium Task 2", dueDate: dateFormatter.dateFromString("2015-10-03")!, priority: 2, workEstimate: 2.5))
tasks.append(Task(title: "Medium Task 3", dueDate: dateFormatter.dateFromString("2015-10-04")!, priority: 1, workEstimate: 3.5))
tasks.append(Task(title: "Medium Task 4", dueDate: dateFormatter.dateFromString("2015-10-06")!, priority: 0, workEstimate: 4.0))

// Add a few long tasks (mixed priority) to the list

tasks.append(Task(title: "Long Task 0", dueDate: dateFormatter.dateFromString("2015-10-04")!, priority: 2, workEstimate: 8.0))
tasks.append(Task(title: "Long Task 1", dueDate: dateFormatter.dateFromString("2015-10-05")!, priority: 3, workEstimate: 10.0))
tasks.append(Task(title: "Long Task 2", dueDate: dateFormatter.dateFromString("2015-10-06")!, priority: 4, workEstimate: 12.0))

// -------------------------- //
// ----- DROPPING TASKS ----- //
// -------------------------- //

// Artificial now

let now = dateFormatter.dateFromString("2015-09-28")!

// Some functions that will be helpful

func workTimeBetweenNowAndDate(date: NSDate) -> Float {
    // This calculates the work time available between today and the
    // given date, exclusive.
    
    var currentDay: NSDate? = now.copy() as? NSDate
    var totalAvailableWorkTime: Float = 0.0
    
    while currentDay!.compare(date) == .OrderedAscending {
        let dayOfWeek = NSCalendar.currentCalendar().components(NSCalendarUnit.Weekday, fromDate: currentDay!).weekday - 1
        totalAvailableWorkTime += workTime[dayOfWeek]
        currentDay = currentDay!.dateByAddingTimeInterval(24 * 60 * 60)
    }
    
    return totalAvailableWorkTime
}

func estimatedWorkBetweenNowAndDate(date: NSDate) -> Float {
    // This calculates the amount of estimated work there is between
    // now and the given date. In other words, how much work there
    // is to do among all tasks due on or before that date.
    
    return tasks.filter({ $0.dueDate.compare(date) != .OrderedDescending }).map({ $0.workEstimate }).reduce(0.0, combine: +)
}

// Sort by due date

tasks.sortInPlace() { $0.dueDate.compare($1.dueDate) == .OrderedAscending }

// Go through all of the due dates, seeing if all of the tasks due on or before
// the given date is schedulable. If not, drop the longest, low priority tasks
// in that interval until it is schedulable. This maximizes the number of tasks
// that get done.

let lastDueDate = tasks.last!.dueDate
var currentDueDate = now.dateByAddingTimeInterval(24 * 60 * 60) // Start with due date tomorrow

var droppedTasks: [Task] = []

while currentDueDate.compare(lastDueDate) != .OrderedDescending {
    let workTimeAvailable = workTimeBetweenNowAndDate(currentDueDate)
    let estimatedWork = estimatedWorkBetweenNowAndDate(currentDueDate)
    
    if estimatedWork > workTimeAvailable {
        // This due date isn't schedulable, drop tasks
        var workDropped: Float = 0.0
        
        // First get a list of tasks due on or before the current date
        var tasksDue = tasks.filter({ $0.dueDate.compare(currentDueDate) != .OrderedDescending })
        tasksDue.count
        
        // Then sort that list of tasks by estimated work, then in reverse by priority
        tasksDue.sortInPlace({ $0.workEstimate > $1.workEstimate })
        tasksDue.sortInPlace({ $0.priority < $1.priority })
        
        // Now go through the tasks and drop them until it's schedulable
        for task in tasksDue {
            workDropped += task.workEstimate
            droppedTasks.append(task)
            tasks.removeAtIndex(tasks.indexOf({ $0 === task })!)
            
            if (estimatedWork - workDropped) <= workTimeAvailable {
                break
            }
        }
    }
    
    currentDueDate = currentDueDate.dateByAddingTimeInterval(24 * 60 * 60)
}

// ---------------------------- //
// ----- SCHEDULING TASKS ----- //
// ---------------------------- //

// Goals/rules of scheduling:
//      Tasks are scheduled to be completed the day before they're due (unless the only day left is its due date)
//      All tasks meet their deadlines (we know there's enough working time once we get here)
//      Tasks are started as late as possible, with low priority tasks scheduled later than high priority tasks
//      Long tasks can be split over several days

// Start by making an array of days for each day between now and the last due date

var days: [DayTasks] = []
currentDueDate = now.copy() as! NSDate

while currentDueDate.compare(lastDueDate) == .OrderedAscending {
    days.append(DayTasks(date: currentDueDate))
    currentDueDate = currentDueDate.dateByAddingTimeInterval(24 * 60 * 60)
}

// Sort the tasks so that the latest, shortest, lowest-priority tasks are first

tasks.sortInPlace({ $0.workEstimate < $1.workEstimate })
tasks.sortInPlace({ $0.priority < $1.priority })
tasks.sortInPlace({ $0.dueDate.compare($1.dueDate) == .OrderedDescending })

// Schedule them tasks

for task in tasks {
    var dayToScheduleOn: DayTasks?
    
    // First try to find the latest day before the task's due date
    // that has available work
    for day in days.reverse() {
        if day.date.compare(task.dueDate) == .OrderedAscending {
            if day.availableWork > 0.0 {
                dayToScheduleOn = day
                break
            }
        }
    }
    
    // If that didn't work, check the task's due date
    if dayToScheduleOn == nil {
        let dueDayIndex = days.indexOf({ $0.date.compare(task.dueDate) == .OrderedSame })!
        let dueDay = days[dueDayIndex]
        if dueDay.availableWork > 0.0 {
            dayToScheduleOn = dueDay
        }
    }
    
    // If it still can't be scheduled, something is wrong
    var confirmedDayToScheduleOn = dayToScheduleOn!
    
    // Otherwise, schedule the task, splitting it up as needed
    
    if confirmedDayToScheduleOn.availableWork >= task.workEstimate {
        // If there's enough work to cover the whole task, we're good
        confirmedDayToScheduleOn.addTask(task)
    } else {
        // If not, get to splitting the task across days
        
        // While this task's subtasks don't cover it
        var currentDayIndex = days.indexOf({ $0 === confirmedDayToScheduleOn })!
        while task.workNotInSubtasks > 0.0 && currentDayIndex >= 0 {
            let currentDay = days[currentDayIndex]
            let newSubtask = task.addSubtaskWithWork(min(currentDay.availableWork, task.workNotInSubtasks))
            currentDay.addTask(newSubtask)
            
            currentDayIndex -= 1
        }
        
        // If we get here and the task still hasn't been totally scheduled, something is wrong
        if task.workNotInSubtasks > 0.0 {
            // Normally I would just throw something but that's acting funny in a playground
            dateFormatter.dateFromString("garbage")!
        }
    }
}

for day in days {
    print("\(day.date) - \(day.totalAvailableWork)")
    for task in day.tasks {
        print(task.title)
    }
    print("")
}
