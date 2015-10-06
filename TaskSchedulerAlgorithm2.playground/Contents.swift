//: Playground - noun: a place where people can play

import UIKit

// Things to test:
//      A bunch of tasks due within a few days of each other
//      Splitting long tasks over several days
//      Conforming to when the user says they can work on tasks
//      Many tasks spread out over a long period of time (over a few months)
//      Dropping lower-priority tasks in favor of higher priority ones (if it comes down to that)
//      Not dropping tasks that don't need to be dropped

// Make a date formatter for easy date creation later

let dateFormatter = NSDateFormatter()
dateFormatter.dateFormat = "yyyy-MM-dd"

// Artificial "today", just for testing

let now = dateFormatter.dateFromString("2015-09-28")!

// Data structures
// TODO make a "Schedule" class to handle all the day/date stuff?

class User {
    private var availableWorkTime: [Float]
    var tasks: [Task]
    var workDays: [WorkDay]
    
    init() {
        self.availableWorkTime = []
        self.tasks = []
        self.workDays = []
    }
    
    func scheduleWorkTime(sun sun: Float, mon: Float, tue: Float, wed: Float, thu: Float, fri: Float, sat: Float) {
        self.availableWorkTime = []
        self.availableWorkTime.append(sun);
        self.availableWorkTime.append(mon);
        self.availableWorkTime.append(tue);
        self.availableWorkTime.append(wed);
        self.availableWorkTime.append(thu);
        self.availableWorkTime.append(fri);
        self.availableWorkTime.append(sat);
    }
    
    private func workAvailableOnDate(date: NSDate) -> Float {
        if self.availableWorkTime.count < 7 {
            return 0
        }
        
        let dayOfWeek = NSCalendar.currentCalendar().components(NSCalendarUnit.Weekday, fromDate: date).weekday - 1
        return self.availableWorkTime[dayOfWeek]
    }
    
    func workDayForDate(date: NSDate) -> WorkDay {
        if let workDayIndex = self.workDays.indexOf({ $0.date.compare(date) == .OrderedSame }) {
            return self.workDays[workDayIndex]
        } else {
            let newWorkDay = WorkDay(date: date, totalAvailableWork: self.workAvailableOnDate(date))
            self.workDays.append(newWorkDay)
            self.workDays.sortInPlace({ $0.date.compare($1.date) == .OrderedAscending })
            
            return newWorkDay
        }
    }
    
    func workDayBeforeDay(day: WorkDay) -> WorkDay {
        return self.workDayForDate(day.date.dateByAddingTimeInterval(-24 * 60 * 60))
    }
    
    func workDayAfterDay(day: WorkDay) -> WorkDay {
        return self.workDayForDate(day.date.dateByAddingTimeInterval(24 * 60 * 60))
    }
    
    func availableWorkTimeBetweenNowAnd(date date: NSDate) -> Float {
        var currentDay: NSDate? = now.copy() as? NSDate
        var totalAvailableWorkTime: Float = 0.0
        
        while currentDay!.compare(date) == .OrderedAscending {
            let workDay = self.workDayForDate(currentDay!)
            totalAvailableWorkTime += workDay.totalAvailableWork
            currentDay = currentDay!.dateByAddingTimeInterval(24 * 60 * 60)
        }
        
        return totalAvailableWorkTime
    }
    
    func workToDoBetweenNowAnd(date date: NSDate) -> Float {
        return self.notDroppedTasks.filter({ $0.dueDate.compare(date) != .OrderedDescending }).map({ $0.workLeftToDo }).reduce(0.0, combine: +)
    }
    
    var droppedTasks: [Task] {
        return tasks.filter({ $0.dropped })
    }
    
    var notDroppedTasks: [Task] {
        return tasks.filter({ !$0.dropped })
    }
}

class Task {
    var title: String
    var dueDate: NSDate
    var priority: Int
    var workEstimate: Float
    var workSessions: [TaskWorkSession]
    var dropped: Bool
    
    init(title: String, dueDate: NSDate, priority: Int, workEstimate: Float) {
        self.title = title
        self.dueDate = dueDate
        self.priority = priority
        self.workEstimate = workEstimate
        self.workSessions = []
        self.dropped = false
    }
    
    func addWorkSession(dayScheduledOn: WorkDay, amountOfWork: Float) {
        let workSession = TaskWorkSession(self, dayScheduledOn: dayScheduledOn, amountOfWork: amountOfWork)
        self.workSessions.append(workSession)
        dayScheduledOn.workSessions.append(workSession)
    }
    
    var totalWorkScheduled: Float {
        return self.workSessions.map({ $0.amountOfWork }).reduce(0.0, combine: +)
    }
    
    var workNotScheduled: Float {
        return self.workEstimate - self.totalWorkScheduled
    }
    
    var workCompleted: Float {
        return self.workSessions.filter({ $0.hasBeenCompleted }).map({ $0.amountOfWork }).reduce(0.0, combine: +)
    }
    
    var workLeftToDo: Float {
        return self.workEstimate - self.workCompleted
    }
}

class TaskWorkSession {
    var parentTask: Task
    var dayScheduledOn: WorkDay
    var amountOfWork: Float
    var hasBeenCompleted: Bool
    
    init(_ parentTask: Task, dayScheduledOn: WorkDay, amountOfWork: Float) {
        self.parentTask = parentTask
        self.dayScheduledOn = dayScheduledOn
        self.amountOfWork = amountOfWork
        self.hasBeenCompleted = false
    }
}

class WorkDay {
    var date: NSDate
    var totalAvailableWork: Float
    var workSessions: [TaskWorkSession]
    
    init(date: NSDate, totalAvailableWork: Float) {
        self.date = date
        self.totalAvailableWork = totalAvailableWork
        self.workSessions = []
    }
    
    var workScheduled: Float {
        return self.workSessions.map({ $0.amountOfWork }).reduce(0.0, combine: +)
    }
    
    var workLeftToBeScheduled: Float {
        return (self.totalAvailableWork - self.workScheduled)
    }
}

// Make a user and schedule work time

var user = User()
user.scheduleWorkTime(sun: 4, mon: 9, tue: 7, wed: 9, thu: 4, fri: 5.5, sat: 4)

// Add a bunch of short tasks (mixed priority) to the list

user.tasks.append(Task(title: "Short Task 0", dueDate: dateFormatter.dateFromString("2015-10-01")!, priority: 0, workEstimate: 0.5))
user.tasks.append(Task(title: "Short Task 1", dueDate: dateFormatter.dateFromString("2015-10-01")!, priority: 1, workEstimate: 1.0))
user.tasks.append(Task(title: "Short Task 2", dueDate: dateFormatter.dateFromString("2015-10-01")!, priority: 2, workEstimate: 0.25))
user.tasks.append(Task(title: "Short Task 3", dueDate: dateFormatter.dateFromString("2015-10-02")!, priority: 3, workEstimate: 1.5))
user.tasks.append(Task(title: "Short Task 4", dueDate: dateFormatter.dateFromString("2015-10-02")!, priority: 4, workEstimate: 0.75))
user.tasks.append(Task(title: "Short Task 5", dueDate: dateFormatter.dateFromString("2015-10-03")!, priority: 3, workEstimate: 0.5))
user.tasks.append(Task(title: "Short Task 6", dueDate: dateFormatter.dateFromString("2015-10-03")!, priority: 0, workEstimate: 1.0))
user.tasks.append(Task(title: "Short Task 7", dueDate: dateFormatter.dateFromString("2015-10-05")!, priority: 1, workEstimate: 1.0))
user.tasks.append(Task(title: "Short Task 8", dueDate: dateFormatter.dateFromString("2015-10-06")!, priority: 2, workEstimate: 0.25))
user.tasks.append(Task(title: "Short Task 9", dueDate: dateFormatter.dateFromString("2015-10-06")!, priority: 4, workEstimate: 0.5))

// Add some medium-length tasks (mixed priority) to the list

user.tasks.append(Task(title: "Medium Task 0", dueDate: dateFormatter.dateFromString("2015-10-01")!, priority: 4, workEstimate: 3.0))
user.tasks.append(Task(title: "Medium Task 1", dueDate: dateFormatter.dateFromString("2015-10-01")!, priority: 3, workEstimate: 4.0))
user.tasks.append(Task(title: "Medium Task 2", dueDate: dateFormatter.dateFromString("2015-10-03")!, priority: 2, workEstimate: 2.5))
user.tasks.append(Task(title: "Medium Task 3", dueDate: dateFormatter.dateFromString("2015-10-04")!, priority: 1, workEstimate: 3.5))
user.tasks.append(Task(title: "Medium Task 4", dueDate: dateFormatter.dateFromString("2015-10-06")!, priority: 0, workEstimate: 4.0))

// Add a few long tasks (mixed priority) to the list

user.tasks.append(Task(title: "Long Task 0", dueDate: dateFormatter.dateFromString("2015-10-04")!, priority: 2, workEstimate: 8.0))
user.tasks.append(Task(title: "Long Task 1", dueDate: dateFormatter.dateFromString("2015-10-05")!, priority: 3, workEstimate: 10.0))
user.tasks.append(Task(title: "Long Task 2", dueDate: dateFormatter.dateFromString("2015-10-06")!, priority: 4, workEstimate: 12.0))

// -------------------------- //
// ----- DROPPING TASKS ----- //
// -------------------------- //

// Sort by due date

var tasksSortedByDueDate = user.tasks.sort() { $0.dueDate.compare($1.dueDate) == .OrderedAscending }

// Go through all of the due dates, seeing if all of the tasks due on or before
// the given date is schedulable. If not, drop the longest, low priority tasks
// in that interval until it is schedulable. This maximizes the number of tasks
// that get done.

let lastDueDate = tasksSortedByDueDate.last!.dueDate
var currentDueDate = now.dateByAddingTimeInterval(24 * 60 * 60) // Start with due date tomorrow

while currentDueDate.compare(lastDueDate) != .OrderedDescending {
    let workTimeAvailable = user.availableWorkTimeBetweenNowAnd(date: currentDueDate)
    let estimatedWork = user.workToDoBetweenNowAnd(date: currentDueDate)
    
    if estimatedWork > workTimeAvailable {
        // This due date isn't schedulable, drop tasks
        var workDropped: Float = 0.0
        
        // First get a list of tasks due on or before the current date
        var tasksDue = user.tasks.filter({ $0.dueDate.compare(currentDueDate) != .OrderedDescending })
        tasksDue.count
        
        // Then sort that list of tasks by estimated work, then in reverse by priority
        tasksDue.sortInPlace({ $0.workEstimate > $1.workEstimate })
        tasksDue.sortInPlace({ $0.priority < $1.priority })
        
        // Now go through the tasks and drop them until it's schedulable
        for task in tasksDue {
            workDropped += task.workEstimate
            task.dropped = true
            
            if (estimatedWork - workDropped) <= workTimeAvailable {
                break
            }
        }
    }
    
    currentDueDate = currentDueDate.dateByAddingTimeInterval(24 * 60 * 60)
}

user.droppedTasks

// ---------------------------- //
// ----- SCHEDULING TASKS ----- //
// ---------------------------- //

// Goals/rules of scheduling:
//      Tasks are scheduled to be completed the day before they're due (unless the only day left is its due date)
//      All tasks meet their deadlines (we know there's enough working time once we get here)
//      Tasks are started as late as possible, with low priority tasks scheduled later than high priority tasks
//      Long tasks can be split over several days

// Sort the tasks so that the latest, shortest, lowest-priority tasks are first

var sortedTasks = user.notDroppedTasks.sort({ $0.workEstimate < $1.workEstimate })
sortedTasks.sortInPlace({ $0.priority < $1.priority })
sortedTasks.sortInPlace({ $0.dueDate.compare($1.dueDate) == .OrderedDescending })

// Schedule them tasks

for task in sortedTasks {
    var dayToScheduleOn: WorkDay?
    
    // First try to find the latest day before the task's due date
    // that has available work
    var currentDay = user.workDayBeforeDay(user.workDayForDate(task.dueDate))
    while currentDay.date.compare(now) != .OrderedAscending {
        if currentDay.workLeftToBeScheduled > 0.0 {
            dayToScheduleOn = currentDay
            break
        }
        currentDay = user.workDayBeforeDay(currentDay)
    }
    
    // If that didn't work, check the task's due date
    if dayToScheduleOn == nil {
        let day = user.workDayForDate(task.dueDate)
        if day.workLeftToBeScheduled > 0.0 {
            dayToScheduleOn = day
        }
    }
    
    // If it still can't be scheduled, something is wrong
    var confirmedDayToScheduleOn = dayToScheduleOn!
    
    // Otherwise, schedule the task, splitting it up as needed

    currentDay = confirmedDayToScheduleOn
    while task.workNotScheduled > 0.0 && currentDay.date.compare(now) != .OrderedAscending {
        let workForNewWorkSession = min(currentDay.workLeftToBeScheduled, task.workNotScheduled)
        if workForNewWorkSession > 0.0 {
            task.addWorkSession(currentDay, amountOfWork: workForNewWorkSession)
        }
        
        currentDay = user.workDayBeforeDay(currentDay)
    }
    
    // If we get here and the task still hasn't been totally scheduled, something is wrong
    if task.workNotScheduled > 0.0 {
        // Normally I would just throw something but that's acting funny in a playground
        dateFormatter.dateFromString("garbage")!
    }
}

for day in user.workDays {
    print("\(day.date) - \(day.totalAvailableWork)")
    for workSession in day.workSessions {
        print("\(workSession.parentTask.title) - \(workSession.amountOfWork)")
    }
    print("")
}
