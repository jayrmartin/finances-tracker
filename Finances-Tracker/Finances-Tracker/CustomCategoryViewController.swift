//
//  CustomCategoryViewController.swift
//  Finances-Tracker
//
//  Created by Jason Martin on 2017-02-07.
//  Copyright © 2017 Jason Martin. All rights reserved.
//

import Cocoa

class CustomCategoryViewController: NSViewController
{
    @IBOutlet weak var addCategoryTextField: NSTextField!
    @IBOutlet weak var addCategoryButton: NSButton!
    @IBOutlet weak var deleteCategoryButton: NSButton!
    @IBOutlet weak var categoriesTableView: NSTableView!
    
    var categoryData: CategoryData?
    
    // The rows that are selected for deletion
    fileprivate var categoriesTableSelectedRowsForDelete: IndexSet = []
    
    // Callback function for updating category data
    var updateCategoryDataCallbackFunction: (() -> Void)?

    @IBAction func handleAddCategoryButtonPress(_ sender: Any)
    {
        guard let cd = categoryData else
        {
            return
        }
        
        let categoryNameText: String = addCategoryTextField.stringValue
        if categoryNameText.isEmpty
        {
            // TODO: show error message
            print("Category name is empty!")
            return
        }
        
        let success: Bool = cd.addCategory(name: categoryNameText)
        if success
        {
            // Use callback to notify of changes to categories
            if let updatedCategoryCallbackFunction = updateCategoryDataCallbackFunction
            {
                updatedCategoryCallbackFunction()
            }
            
            // Reload the table
            categoriesTableView.reloadData()
        }
        else
        {
            // TODO: show error message
            print("Failed to add new category name!")
        }
        
        // Clear the text
        addCategoryTextField.stringValue = ""
    }
    
    @IBAction func handleDeleteCategoriesButtonPress(_ sender: Any)
    {
        guard let cd = categoryData else
        {
            return
        }
        
        let selectedRows: IndexSet = categoriesTableView.selectedRowIndexes
        guard selectedRows.count > 0 else
        {
            return
        }
        
        // Save the selected rows
        categoriesTableSelectedRowsForDelete = selectedRows
        
        // Remove rows from data
        cd.deleteCategories(indices: selectedRows)
        
        // Use callback to notify of changes to categories
        if let updatedCategoryCallbackFunction = updateCategoryDataCallbackFunction
        {
            updatedCategoryCallbackFunction()
        }
        
        // Reload the table
        categoriesTableView.reloadData()
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        // Tell the table view about delegate and data source
        categoriesTableView.delegate = self
        categoriesTableView.dataSource = self
    }
    
    override func viewWillAppear()
    {
        super.viewWillAppear()
        
        addCategoryTextField.stringValue = ""
    }
    
}

// Extension for the table view data source
extension CustomCategoryViewController: NSTableViewDataSource
{
    // Return the number of rows that should be shown
    func numberOfRows(in tableView: NSTableView) -> Int
    {
        if let cd = categoryData
        {
            return cd.customCategoryStrings.count
        }
        
        return -1
    }
}

// Extension to implement the table view delegate
extension CustomCategoryViewController: NSTableViewDelegate
{
    // Build each cell based on given column and row
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView?
    {
        guard let cd = categoryData else
        {
            return nil
        }
        
        // Sanity check the given row
        if row >= cd.customCategoryStrings.count
        {
            return nil
        }
        
        var text: String = ""
        var cellIdentifier: String = ""
        
        // Grab string from selected row for editing
        let categoryString: String = cd.customCategoryStrings[row]
        text = categoryString
        cellIdentifier = "CategoriesCellID"
        
        // Create the cell with the information
        if let cell = tableView.make(withIdentifier: cellIdentifier, owner: nil) as? NSTableCellView
        {
            cell.textField?.stringValue = text
            return cell
        }
        
        return nil
    }
}
