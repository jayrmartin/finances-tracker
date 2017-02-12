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
    // The currently selected category for the transaction
    var category: String = ""
    
    // The date entered for the transaction
    var date: Date = Date()
    
    // The vendor entered for the transaction
    var vendor: String = ""
    
    // The amount entered for the transaction
    var amount: Double = 0
    
    // Whether the view controller is being used to edit an existing transaction
    var editingExistingTransaction: Bool = false
    
    // Callback function for adding a transaction
    var addTransactionCallbackFunction: ((TransactionData, Bool) -> Void)?
    
    // Callback function for editing a transaction
    var editTransactionCallbackFunction: ((TransactionData, Bool) -> Void)?
    
    // Separate view controller for custom categories
    fileprivate lazy var customCategoriesViewController: CustomCategoryViewController = {
        return self.storyboard!.instantiateController(withIdentifier: "CustomCategoryViewController") as! CustomCategoryViewController
    }()
    
    var categoryData: CategoryData?

    @IBOutlet weak var categoryPopUpButton: NSPopUpButton!
    @IBOutlet weak var datePicker: NSDatePicker!
    @IBOutlet weak var vendorTextField: NSTextField!
    @IBOutlet weak var amountTextField: NSTextField!
    @IBOutlet weak var addEditButton: NSButton!
    @IBOutlet weak var editCategoriesButton: NSButton!
    
    @IBAction func handleCategoryPopUpButtonChoice(_ sender: Any)
    {
        let btn = sender as! NSPopUpButton
        category = btn.titleOfSelectedItem!
        //print("Selected Item: \(category)")
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
            //print("Edit Transaction! Vendor: \(vendor) Amount: \(amount) Category: \(category)")
            
            // Use callback to update data
            if let editCallbackFunction = editTransactionCallbackFunction
            {
                let editedTransaction: TransactionData = TransactionData(transactionDate: date, transactionCategory: category, transactionAmount: amount, transactionVendor: vendor)
                editCallbackFunction(editedTransaction, true)
            }
        }
        else
        {
            //print("New Transaction! Vendor: \(vendor) Amount: \(amount) Category: \(category)")
            
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
    
    @IBAction func handleEditCategoriesButtonPress(_ sender: Any)
    {
        // Set the category data object
        customCategoriesViewController.categoryData = categoryData
        customCategoriesViewController.updateCategoryDataCallbackFunction = updateCategories
        
        // Show the view for custom categories
        self.presentViewControllerAsModalWindow(customCategoriesViewController)
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.title = "Transaction Details"
    }
    
    override func viewDidAppear()
    {
        super.viewDidAppear()
        
        // No resizing
        _ = self.view.window?.styleMask.remove(NSWindowStyleMask.resizable)
    }
    
    override func viewWillAppear()
    {
        super.viewWillAppear()
        
        updateCategories()
        
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
        if let cd = categoryData
        {
            category = cd.categoryStrings[0]
        }
        else
        {
            category = ""
        }
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
    
    // Update the categories in the pop up button
    func updateCategories()
    {
        categoryPopUpButton.removeAllItems()
        
        if let cd = categoryData
        {
            // Add categories to category popup button
            categoryPopUpButton.addItems(withTitles: cd.categoryStrings)
        
            // Add the custom categories too
            categoryPopUpButton.addItems(withTitles: cd.customCategoryStrings)
        }
    }
}
