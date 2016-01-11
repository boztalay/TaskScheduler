//
//  SettingsViewController.swift
//  TaskScheduler
//
//  Created by Ben Oztalay on 10/23/15.
//  Copyright © 2015 Ben Oztalay. All rights reserved.
//

import UIKit

enum SetupError: ErrorType {
    case TextFieldValidationError
}

class SettingsViewController: UITableViewController, UITextFieldDelegate, ScheduleConfirmationDelegate {
    
    @IBOutlet weak var sundayTextField: UITextField!
    @IBOutlet weak var mondayTextField: UITextField!
    @IBOutlet weak var tuesdayTextField: UITextField!
    @IBOutlet weak var wednesdayTextField: UITextField!
    @IBOutlet weak var thursdayTextField: UITextField!
    @IBOutlet weak var fridayTextField: UITextField!
    @IBOutlet weak var saturdayTextField: UITextField!
    
    let persistenceController = PersistenceManager.sharedInstance
    
    var user: User?
    var isSettingUp: Bool?
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if self.isSettingUp == nil {
            self.isSettingUp = false
        }
        
        if self.isSettingUp! {
            self.setUpForSetup()
        } else {
            self.setUpForSettings()
        }
    }
    
    func setUpForSetup() {
        self.title = "Setup"
    }
    
    func setUpForSettings() {
        self.title = "Settings"
        self.user = self.persistenceController.getLatestUserData()
        
        if let user = self.user {
            self.sundayTextField.text = user.sunAvailableWorkTime.stringValue
            self.mondayTextField.text = user.monAvailableWorkTime.stringValue
            self.tuesdayTextField.text = user.tueAvailableWorkTime.stringValue
            self.wednesdayTextField.text = user.wedAvailableWorkTime.stringValue
            self.thursdayTextField.text = user.thuAvailableWorkTime.stringValue
            self.fridayTextField.text = user.friAvailableWorkTime.stringValue
            self.saturdayTextField.text = user.satAvailableWorkTime.stringValue
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField === self.sundayTextField {
            self.mondayTextField.becomeFirstResponder()
        } else if textField === self.mondayTextField {
            self.tuesdayTextField.becomeFirstResponder()
        } else if textField === self.tuesdayTextField {
            self.wednesdayTextField.becomeFirstResponder()
        } else if textField === self.wednesdayTextField {
            self.thursdayTextField.becomeFirstResponder()
        } else if textField === self.thursdayTextField {
            self.fridayTextField.becomeFirstResponder()
        } else if textField === self.fridayTextField {
            self.saturdayTextField.becomeFirstResponder()
        } else if textField === self.saturdayTextField {
            self.saturdayTextField.resignFirstResponder()
            self.saveButtonPressed(self)
        }
        
        return true
    }
    
    @IBAction func saveButtonPressed(sender: AnyObject) {
        self.view.endEditing(true)
        
        // Validate the input and build the work schedule
        
        var workSchedule = AvailableWorkSchedule()
        
        do {
            workSchedule.sundayWork = try self.validateTextField(self.sundayTextField)
            workSchedule.mondayWork = try self.validateTextField(self.mondayTextField)
            workSchedule.tuesdayWork = try self.validateTextField(self.tuesdayTextField)
            workSchedule.wednesdayWork = try self.validateTextField(self.wednesdayTextField)
            workSchedule.thursdayWork = try self.validateTextField(self.thursdayTextField)
            workSchedule.fridayWork = try self.validateTextField(self.fridayTextField)
            workSchedule.saturdayWork = try self.validateTextField(self.saturdayTextField)
        } catch {
            self.showBadInputAlert()
            return
        }
        
        // Make a new user object (if needed) and schedule the work time
        
        if self.isSettingUp! {
            self.user = User(context: self.persistenceController.coreDataStack!.managedObjectContext)
        }
        
        self.user!.scheduleWorkTime(workSchedule)
        
        // See if we need to ask the user if they want to update the
        // available work times on any existing work days to match
        // the new schedule
        
        var shouldAskUserAboutSchedule = false
        
        for workDay in self.user!.workDaysNotInPast {
            let workAvailableInNewSchedule = try! self.user!.totalAvailableWorkOnDate(workDay.date)
            if workDay.totalAvailableWork != workAvailableInNewSchedule {
                shouldAskUserAboutSchedule = true
            }
        }
        
        // If we do need to ask the user about the schedule, show
        // a screen to ask about it. Otherwise, just exit.
        
        if shouldAskUserAboutSchedule {
            self.performSegueWithIdentifier("SettingsToConfirmation", sender: nil)
        } else {
            self.saveAndExit()
        }
    }
    
    func validateTextField(textField: UITextField) throws -> Float {
        if textField.text == nil || textField.text!.isEmpty {
            throw SetupError.TextFieldValidationError
        }
        
        let number = NSNumberFormatter().numberFromString(textField.text!)
        if number == nil || number!.floatValue < 0 {
            throw SetupError.TextFieldValidationError
        }
        
        return number!.floatValue
    }
    
    func showBadInputAlert() {
        let alert = UIAlertController(title: "Bad Input", message: "Hey, all your inputs gotta be positive numbers!", preferredStyle: .Alert)
        let cancelAction = UIAlertAction(title: "Fiiiine", style: .Cancel, handler: nil)
        alert.addAction(cancelAction)
        
        presentViewController(alert, animated: true, completion:nil)
    }
    
    func scheduleConfirmationComplete() {
        self.saveAndExit()
    }
    
    func saveAndExit() {
        if !self.persistenceController.saveDataAndWait() {
            print("Couldn't save the data")
        }
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let navigationController = segue.destinationViewController as? UINavigationController

        if segue.identifier == "SettingsToConfirmation" {
            let confirmationViewController = navigationController!.viewControllers.first as! ScheduleConfirmationViewController
            confirmationViewController.user = self.user
            confirmationViewController.delegate = self
        }
    }
}
