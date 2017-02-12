//
//  ErrorMessageViewController.swift
//  Finances-Tracker
//
//  Created by Jason Martin on 2017-02-05.
//  Copyright © 2017 Jason Martin. All rights reserved.
//

import Cocoa

class ErrorMessageViewController: NSViewController
{
    @IBOutlet weak var errorMessageTextField: NSTextField!
    @IBOutlet weak var okButton: NSButton!
    @IBOutlet weak var cancelButton: NSButton!
    
    // The text for the error message
    var errorMessageString: String = ""
    
    // Callback function for "OK" button press
    var okCallbackFunction: (() -> Void)?
    
    @IBAction func handleOkButtonPress(_ sender: Any)
    {
        guard let okCallbackFunc = okCallbackFunction else {
            return
        }
        
        // Call callback function
        okCallbackFunc()
        
        // Close the view
        okCallbackFunction = nil
        self.dismissViewController(self)
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
    }
    
    override func viewWillAppear()
    {
        super.viewWillAppear()
        
        // Set error message
        errorMessageTextField.stringValue = errorMessageString
    }
    
    override func viewDidAppear()
    {
        // No resizing
        _ = self.view.window?.styleMask.remove(NSWindowStyleMask.resizable)
    }
    
}
