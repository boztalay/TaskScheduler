//
//  SetupViewController.swift
//  TaskScheduler
//
//  Created by Ben Oztalay on 10/23/15.
//  Copyright © 2015 Ben Oztalay. All rights reserved.
//

import UIKit

enum SetupError: ErrorType {
    case TextFieldValidationError
}

protocol SetupViewControllerDelegate {
    func setupComplete(workSchedule: AvailableWorkSchedule)
}

class SetupViewController: UITableViewController {
    @IBOutlet weak var sundayTextField: UITextField!
    @IBOutlet weak var mondayTextField: UITextField!
    @IBOutlet weak var tuesdayTextField: UITextField!
    @IBOutlet weak var wednesdayTextField: UITextField!
    @IBOutlet weak var thursdayTextField: UITextField!
    @IBOutlet weak var fridayTextField: UITextField!
    @IBOutlet weak var saturdayTextField: UITextField!
    
    var delegate: SetupViewControllerDelegate?
    
    @IBAction func doneButtonPressed(sender: AnyObject) {
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
        
        dispatch_async(dispatch_get_main_queue()) {
            self.delegate!.setupComplete(workSchedule)
        }
        
        self.dismissViewControllerAnimated(true, completion: nil)
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
}