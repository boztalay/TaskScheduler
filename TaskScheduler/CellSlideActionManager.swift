//
//  CellSlideActionManager.swift
//  TaskScheduler
//
//  Created by Ben Oztalay on 1/4/16.
//  Copyright © 2016 Ben Oztalay. All rights reserved.
//

import UIKit

// A delegate for controllers to conform to to get notified
// when the user triggers an action by sliding a cell over
protocol CellSlideActionManagerDelegate {
    // Called when a cell's mark complete action is triggered
    func cellSlideMarkCompleteActionTriggered(tableView: UITableView, indexPath: NSIndexPath)

    // Called when a cell's mark incomplete action is triggered
    func cellSlideMarkIncompleteActionTriggered(tableView: UITableView, indexPath: NSIndexPath)

    // Called when a cell's delete action is triggered
    func cellSlideDeleteActionTriggered(tableView: UITableView, indexPath: NSIndexPath)
}

// Holds some attributes for the cell slide actions,
// just here for easier configuration
struct CellSlideActionAttributes {
    static let generalFraction: CGFloat = 0.20
    static let generalElasticity: CGFloat = 50.0
    static let generalIconColor = UIColor.whiteColor()
    
    static let markCompleteActiveBackgroundColor = TaskSchedulerColors.TaskComplete
    static let markCompleteInactiveBackgroundColor = TaskSchedulerColors.TaskInProgess
    static let markCompleteIcon = UIImage(named: "check")

    static let markIncompleteActiveBackgroundColor = TaskSchedulerColors.TaskInProgess
    static let markIncompleteInactiveBackgroundColor = TaskSchedulerColors.TaskComplete
    static let markIncompleteIcon = UIImage(named: "uncheck")

    static let deleteActionActiveBackgroundColor = TaskSchedulerColors.TaskDropped
    static let deleteActionInactiveBackgroundColor = TaskSchedulerColors.TaskInProgess
    static let deleteIcon = UIImage(named: "delete")
}

class CellSlideActionManager: NSObject {
    private var markCompleteAction: DRCellSlideAction
    private var markIncompleteAction: DRCellSlideAction
    private var deleteAction: DRCellSlideAction
    private var knownGestureRecognizers: [DRCellSlideGestureRecognizer] = []
    
    var delegate: CellSlideActionManagerDelegate?
    
    override init() {
        // Need to initialize them first, then call super.init
        self.markCompleteAction = DRCellSlideAction(forFraction: CellSlideActionAttributes.generalFraction)
        self.markIncompleteAction = DRCellSlideAction(forFraction: CellSlideActionAttributes.generalFraction)
        self.deleteAction = DRCellSlideAction(forFraction: -CellSlideActionAttributes.generalFraction)
        
        super.init()
        
        // Set up the mark complete action
        self.markCompleteAction.behavior = DRCellSlideActionBehavior.PullBehavior
        self.markCompleteAction.elasticity = CellSlideActionAttributes.generalElasticity
        self.markCompleteAction.activeBackgroundColor = CellSlideActionAttributes.markCompleteActiveBackgroundColor
        self.markCompleteAction.inactiveBackgroundColor = CellSlideActionAttributes.markCompleteInactiveBackgroundColor
        self.markCompleteAction.icon = CellSlideActionAttributes.markCompleteIcon
        self.markCompleteAction.activeColor = CellSlideActionAttributes.generalIconColor
        self.markCompleteAction.inactiveColor = CellSlideActionAttributes.generalIconColor
        self.markCompleteAction.didTriggerBlock = self.markCompleteActionTriggered
        
        // Set up the mark incomplete action
        self.markIncompleteAction.behavior = DRCellSlideActionBehavior.PullBehavior
        self.markIncompleteAction.elasticity = CellSlideActionAttributes.generalElasticity
        self.markIncompleteAction.activeBackgroundColor = CellSlideActionAttributes.markIncompleteActiveBackgroundColor
        self.markIncompleteAction.inactiveBackgroundColor = CellSlideActionAttributes.markIncompleteInactiveBackgroundColor
        self.markIncompleteAction.icon = CellSlideActionAttributes.markIncompleteIcon
        self.markIncompleteAction.activeColor = CellSlideActionAttributes.generalIconColor
        self.markIncompleteAction.inactiveColor = CellSlideActionAttributes.generalIconColor
        self.markIncompleteAction.didTriggerBlock = self.markIncompleteActionTriggered
        
        // Set up the delete action
        self.deleteAction.behavior = DRCellSlideActionBehavior.PushBehavior
        self.deleteAction.elasticity = CellSlideActionAttributes.generalElasticity
        self.deleteAction.activeBackgroundColor = CellSlideActionAttributes.deleteActionActiveBackgroundColor
        self.deleteAction.inactiveBackgroundColor = CellSlideActionAttributes.deleteActionInactiveBackgroundColor
        self.deleteAction.icon = CellSlideActionAttributes.deleteIcon
        self.deleteAction.activeColor = CellSlideActionAttributes.generalIconColor
        self.deleteAction.inactiveColor = CellSlideActionAttributes.generalIconColor
        self.deleteAction.didTriggerBlock = self.deleteActionTriggered
    }
    
    // Called whenever the mark complete action is triggered
    private func markCompleteActionTriggered(tableView: UITableView?, indexPath: NSIndexPath?) {
        dispatch_async(dispatch_get_main_queue()) {
            self.delegate?.cellSlideMarkCompleteActionTriggered(tableView!, indexPath: indexPath!)
        }
    }
    
    // Called whenever the mark incomplete action is triggered
    private func markIncompleteActionTriggered(tableView: UITableView?, indexPath: NSIndexPath?) {
        dispatch_async(dispatch_get_main_queue()) {
            self.delegate?.cellSlideMarkIncompleteActionTriggered(tableView!, indexPath: indexPath!)
        }
    }
    
    // Called whenever the delete action is triggered
    private func deleteActionTriggered(tableView: UITableView?, indexPath: NSIndexPath?) {
        dispatch_async(dispatch_get_main_queue()) {
            self.delegate?.cellSlideDeleteActionTriggered(tableView!, indexPath: indexPath!)
        }
    }
    
    // Configures the given cell to have mark complete and
    // delete cell slide actions
    func addMarkCompleteAndDeleteSlideActionsToCell(cell: UITableViewCell) {
        self.removeKnownGestureRecognizersFromCell(cell)
        
        let gestureRecognizer = DRCellSlideGestureRecognizer()
        gestureRecognizer.addActions([self.markCompleteAction, self.deleteAction])
        
        cell.addGestureRecognizer(gestureRecognizer)
    }
    
    // Configures the given cell to have mark incomplete and
    // delete cell slide actions
    func addMarkIncompleteAndDeleteSlideActionsToCell(cell: UITableViewCell) {
        self.removeKnownGestureRecognizersFromCell(cell)
        
        let gestureRecognizer = DRCellSlideGestureRecognizer()
        gestureRecognizer.addActions([self.markIncompleteAction, self.deleteAction])
        
        cell.addGestureRecognizer(gestureRecognizer)
    }

    // Configures the given cell to have only the
    // mark complete cell slide action
    func addMarkCompleteSlideActionToCell(cell: UITableViewCell) {
        self.removeKnownGestureRecognizersFromCell(cell)
        
        let gestureRecognizer = DRCellSlideGestureRecognizer()
        gestureRecognizer.addActions([self.markCompleteAction])
        
        cell.addGestureRecognizer(gestureRecognizer)
    }
    
    // Configures the given cell to have only the
    // mark incomplete cell slide action
    func addMarkIncompleteSlideActionToCell(cell: UITableViewCell) {
        self.removeKnownGestureRecognizersFromCell(cell)
        
        let gestureRecognizer = DRCellSlideGestureRecognizer()
        gestureRecognizer.addActions([self.markIncompleteAction])

        cell.addGestureRecognizer(gestureRecognizer)
    }
    
    // Removes all DRCellSlideGestureRecognizers from the given cell
    private func removeKnownGestureRecognizersFromCell(cell: UITableViewCell) {
        if let cellGestureRecognizers = cell.gestureRecognizers {
            for gestureRecognizer in cellGestureRecognizers {
                if let gestureRecognizer = gestureRecognizer as? DRCellSlideGestureRecognizer {
                    cell.removeGestureRecognizer(gestureRecognizer)
                }
            }
        }
    }
}
