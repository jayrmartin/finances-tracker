//
//  TransactionDetailsViewController.swift
//  Finances-Tracker
//
//  Created by Jason Martin on 2017-01-22.
//  Copyright © 2017 Jason Martin. All rights reserved.
//

import Cocoa

class TransactionDetailsViewController: NSViewController
{
    // Array of base options in the category popup button
    fileprivate var categoryStrings: [String] = [
        "Mortgage",
        "Cable and Internet",
        "Grocery",
        "Dining Out",
        "Alcohol"
    ]
    
    // The currently selected category for the new transaction
    var category: String = ""
    
    // The date entered for the new transaction
    var date: Date = Date()
    
    // The vendor entered for the new transaction
    var vendor: String = ""
    
    // The amount entered for the new transaction
    var amount: Double = 0
    
    // Whether the view controller is being used to edit an existing transaction
    var editingExistingTransaction: Bool = false
    
    // Callback function for adding a transaction
    var addTransactionCallbackFunction: ((TransactionData, Bool) -> Void)?
    
    // Callback function for editing a transaction
    var editTransactionCallbackFunction: ((TransactionData, Bool) -> Void)?

    @IBOutlet weak var categoryPopUpButton: NSPopUpButton!
    @IBOutlet weak var datePicker: NSDatePicker!
    @IBOutlet weak var vendorTextField: NSTextField!
    @IBOutlet weak var amountTextField: NSTextField!
    @IBOutlet weak var addEditButton: NSButton!
    
    @IBAction func handleCategoryPopUpButtonChoice(_ sender: Any)
    {
        let btn = sender as! NSPopUpButton
        category = btn.titleOfSelectedItem!
        print("Selected Item: \(category)")
    }
    
    @IBAction func handleAddOrEditButtonPress(_ sender: Any)
    {
        // Grab entered values and sanity check
        date = datePicker.dateValue
        
        vendor = vendorTextField.stringValue
        if vendor.isEmpty
        {
            // TODO: show error message
            print("Vendor is empty!")
            return
        }
        
        amount = amountTextField.doubleValue
        if amount <= 0
        {
            // TODO: show error message
            print("Amount is less than zero")
            return
        }
        
        if editingExistingTransaction
        {
            print("Edit Transaction! Vendor: \(vendor) Amount: \(amount) Category: \(category)")
            
            // Use callback to update data
            if let editCallbackFunction = editTransactionCallbackFunction
            {
                let editedTransaction: TransactionData = TransactionData(transactionDate: date, transactionCategory: category, transactionAmount: amount, transactionVendor: vendor)
                editCallbackFunction(editedTransaction, true)
            }
        }
        else
        {
            print("New Transaction! Vendor: \(vendor) Amount: \(amount) Category: \(category)")
            
            // Add transaction to data
            if let addCallbackFunction = addTransactionCallbackFunction
            {
                let newTransaction: TransactionData = TransactionData(transactionDate: date, transactionCategory: category, transactionAmount: amount, transactionVendor: vendor)
                addCallbackFunction(newTransaction, true)
            }
        }
        
        // Close the view
        editingExistingTransaction = false
        addTransactionCallbackFunction = nil
        editTransactionCallbackFunction = nil
        self.dismissViewController(self)
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.title = "Transaction Details"
        
        // Add categories to category popup button
        // TODO: Load custom categories and add them too
        categoryPopUpButton.removeAllItems()
        categoryPopUpButton.addItems(withTitles: categoryStrings)
    }
    
    override func viewDidAppear()
    {
        super.viewDidAppear()
    }
    
    override func viewWillAppear()
    {
        super.viewWillAppear()
        
        if editingExistingTransaction
        {
            // Use values that were set
            categoryPopUpButton.selectItem(withTitle: category)
            
            // Set date to current date
            datePicker.dateValue = date
            
            // Set values to default
            vendorTextField.stringValue = vendor
            amountTextField.doubleValue = amount
            
            // Change button text
            addEditButton.title = "OK"
        }
        else
        {
            // Reset to default values for next open
            setDefaultDetailValues()
            
            // Change button text
            addEditButton.title = "Add"
        }
    }
    
    // Helper function to set default values
    func setDefaultDetailValues()
    {
        // Set current category to first item in the list
        category = self.categoryStrings[0]
        categoryPopUpButton.selectItem(withTitle: category)
        
        // Set date to current date
        datePicker.dateValue = Date()
        
        // Set values to default
        vendorTextField.stringValue = ""
        amountTextField.stringValue = ""
    }
    
    // Helper function to set specific values for transaction
    func setSpecificDetailValues(transaction: TransactionData)
    {
        category = transaction.category
        date = transaction.date
        vendor = transaction.vendor
        amount = transaction.amount
    }
}
