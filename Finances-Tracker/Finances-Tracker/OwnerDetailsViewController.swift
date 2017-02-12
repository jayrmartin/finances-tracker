//
//  OwnerDetailsViewController.swift
//  Finances-Tracker
//
//  Created by Jason Martin on 2017-02-03.
//  Copyright © 2017 Jason Martin. All rights reserved.
//

import Cocoa

class OwnerDetailsViewController: NSViewController
{
    @IBOutlet weak var ownerTextField: NSTextField!
    @IBOutlet weak var okButton: NSButton!
    @IBOutlet weak var cancelButton: NSButton!
    
    // Callback function for adding a owner
    var addOwnerCallbackFunction: ((String) -> Int)?
    
    @IBAction func handleOkButtonPress(_ sender: Any)
    {
        // Make sure text field has text
        let newOwnerText: String = ownerTextField.stringValue
        
        if newOwnerText == ""
        {
            // TODO: Show error?
            return
        }
        
        guard let addCallbackFunction = addOwnerCallbackFunction else {
            return
        }
        
        // Callback to add it to the list of existing owners
        let addResult: Int = addCallbackFunction(newOwnerText)
        if addResult != 0
        {
            // TODO: Show error
            print("Error adding new owner: \(addResult)")
        }
        else
        {
            // Successful add!
            
            // Close this view
            addOwnerCallbackFunction = nil
            self.dismissViewController(self)
        }
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.title = "New Owner"
    }
    
    override func viewDidAppear()
    {
        // No resizing
        _ = self.view.window?.styleMask.remove(NSWindowStyleMask.resizable)
    }
}
