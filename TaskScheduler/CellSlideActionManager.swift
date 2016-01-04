//
//  CellSlideActionManager.swift
//  TaskScheduler
//
//  Created by Ben Oztalay on 1/4/16.
//  Copyright © 2016 Ben Oztalay. All rights reserved.
//

import UIKit

protocol CellSlideActionManagerDelegate {
    func cellSlideMarkCompleteActionTriggered(tableView: UITableView, indexPath: NSIndexPath)
    func cellSlideMarkIncompleteActionTriggered(tableView: UITableView, indexPath: NSIndexPath)
    func cellSlideDeleteActionTriggered(tableView: UITableView, indexPath: NSIndexPath)
}

struct CellSlideActionAttributes {
    static let generalFraction: CGFloat = 0.25
    static let generalElasticity: CGFloat = 50.0
    
    static let markCompleteActiveBackgroundColor = UIColor.blueColor()
    static let markCompleteInactiveBackgroundColor = UIColor.lightGrayColor()
    static let markIncompleteActiveBackgroundColor = UIColor.lightGrayColor()
    static let markIncompleteInactiveBackgroundColor = UIColor.blueColor()
    static let deleteActionActiveBackgroundColor = UIColor.redColor()
    static let deleteActionInactiveBackgroundColor = UIColor.lightGrayColor()
}

class CellSlideActionManager: NSObject {
    
    private var markCompleteAction: DRCellSlideAction
    private var markIncompleteAction: DRCellSlideAction
    private var deleteAction: DRCellSlideAction
    private var knownGestureRecognizers: [DRCellSlideGestureRecognizer] = []
    
    var delegate: CellSlideActionManagerDelegate?
    
    override init() {
        self.markCompleteAction = DRCellSlideAction(forFraction: CellSlideActionAttributes.generalFraction)
        self.markIncompleteAction = DRCellSlideAction(forFraction: CellSlideActionAttributes.generalFraction)
        self.deleteAction = DRCellSlideAction(forFraction: -CellSlideActionAttributes.generalFraction)
        
        super.init()
        
        self.markCompleteAction.behavior = DRCellSlideActionBehavior.PullBehavior
        self.markCompleteAction.elasticity = CellSlideActionAttributes.generalElasticity
        self.markCompleteAction.activeBackgroundColor = CellSlideActionAttributes.markCompleteActiveBackgroundColor
        self.markCompleteAction.inactiveBackgroundColor = CellSlideActionAttributes.markCompleteInactiveBackgroundColor
        self.markCompleteAction.didTriggerBlock = self.markCompleteActionTriggered
        
        self.markIncompleteAction.behavior = DRCellSlideActionBehavior.PullBehavior
        self.markIncompleteAction.elasticity = CellSlideActionAttributes.generalElasticity
        self.markIncompleteAction.activeBackgroundColor = CellSlideActionAttributes.markIncompleteActiveBackgroundColor
        self.markIncompleteAction.inactiveBackgroundColor = CellSlideActionAttributes.markIncompleteInactiveBackgroundColor
        self.markIncompleteAction.didTriggerBlock = self.markIncompleteActionTriggered
        
        self.deleteAction.behavior = DRCellSlideActionBehavior.PushBehavior
        self.deleteAction.elasticity = CellSlideActionAttributes.generalElasticity
        self.deleteAction.activeBackgroundColor = CellSlideActionAttributes.deleteActionActiveBackgroundColor
        self.deleteAction.inactiveBackgroundColor = CellSlideActionAttributes.deleteActionInactiveBackgroundColor
        self.deleteAction.didTriggerBlock = self.deleteActionTriggered
    }
    
    private func markCompleteActionTriggered(tableView: UITableView?, indexPath: NSIndexPath?) {
        dispatch_async(dispatch_get_main_queue()) {
            self.delegate?.cellSlideMarkCompleteActionTriggered(tableView!, indexPath: indexPath!)
        }
    }
    
    private func markIncompleteActionTriggered(tableView: UITableView?, indexPath: NSIndexPath?) {
        dispatch_async(dispatch_get_main_queue()) {
            self.delegate?.cellSlideMarkIncompleteActionTriggered(tableView!, indexPath: indexPath!)
        }
    }
    
    private func deleteActionTriggered(tableView: UITableView?, indexPath: NSIndexPath?) {
        dispatch_async(dispatch_get_main_queue()) {
            self.delegate?.cellSlideDeleteActionTriggered(tableView!, indexPath: indexPath!)
        }
    }
    
    func addMarkCompleteAndDeleteSlideActionsToCell(cell: UITableViewCell) {
        self.removeKnownGestureRecognizersFromCell(cell)
        
        let gestureRecognizer = DRCellSlideGestureRecognizer()
        gestureRecognizer.addActions([self.markCompleteAction, self.deleteAction])
        
        self.addGestureRecognizerToCell(cell, gestureRecognizer: gestureRecognizer)
    }
    
    func addMarkIncompleteAndDeleteSlideActionsToCell(cell: UITableViewCell) {
        self.removeKnownGestureRecognizersFromCell(cell)
        
        let gestureRecognizer = DRCellSlideGestureRecognizer()
        gestureRecognizer.addActions([self.markIncompleteAction, self.deleteAction])
        
        self.addGestureRecognizerToCell(cell, gestureRecognizer: gestureRecognizer)
    }
    
    func addMarkCompleteSlideActionToCell(cell: UITableViewCell) {
        self.removeKnownGestureRecognizersFromCell(cell)
        
        let gestureRecognizer = DRCellSlideGestureRecognizer()
        gestureRecognizer.addActions([self.markCompleteAction])
        
        self.addGestureRecognizerToCell(cell, gestureRecognizer: gestureRecognizer)
    }
    
    func addMarkIncompleteSlideActionToCell(cell: UITableViewCell) {
        self.removeKnownGestureRecognizersFromCell(cell)
        
        let gestureRecognizer = DRCellSlideGestureRecognizer()
        gestureRecognizer.addActions([self.markIncompleteAction])
        
        self.addGestureRecognizerToCell(cell, gestureRecognizer: gestureRecognizer)
    }
    
    private func removeKnownGestureRecognizersFromCell(cell: UITableViewCell) {
        if let cellGestureRecognizers = cell.gestureRecognizers {
            for gestureRecognizer in cellGestureRecognizers {
                if let gestureRecognizer = gestureRecognizer as? DRCellSlideGestureRecognizer {
                    cell.removeGestureRecognizer(gestureRecognizer)
                    self.knownGestureRecognizers.removeAtIndex(self.knownGestureRecognizers.indexOf(gestureRecognizer)!)
                }
            }
        }
    }
    
    private func addGestureRecognizerToCell(cell: UITableViewCell, gestureRecognizer: DRCellSlideGestureRecognizer) {
        self.knownGestureRecognizers.append(gestureRecognizer)
        cell.addGestureRecognizer(gestureRecognizer)
    }
}
