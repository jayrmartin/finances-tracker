//
//  ViewController.swift
//  Finances-Tracker
//
//  Created by Jason Martin on 2017-01-21.
//  Copyright © 2017 Jason Martin. All rights reserved.
//

import Cocoa

class ViewController: NSViewController
{
    // Save/load keys for UserDefaults
    enum SaveLoadKeys
    {
        static let LastOwner = "lastOwner"
        static let Owners = "owners"
        static let CustomCategories = "customCategories"
    }
    
    // Add owner success or error values
    enum AddOwnerResult
    {
        static let Success = 0
        static let GeneralError = -1
        static let NameAlreadyExistsError = -2
    }
    
    // References to specific UI objects
    @IBOutlet weak var newButton: NSButton!
    @IBOutlet weak var loadButton: NSButton!
    @IBOutlet weak var addButton: NSButton!
    @IBOutlet weak var editButton: NSButton!
    @IBOutlet weak var deleteButton: NSButton!
    @IBOutlet weak var analyzeButton: NSButton!
    @IBOutlet weak var showAllButton: NSButton!
    
    @IBOutlet weak var transactionsTableView: NSTableView!
    @IBOutlet weak var ownersTableView: NSTableView!
    
    @IBOutlet weak var ownerLabel: NSTextField!
    
    // References to UI objects in "filters" view
    @IBOutlet weak var dateFilterOptionsPopUpButton: NSPopUpButton!
    @IBOutlet weak var startDatePicker: NSDatePicker!
    @IBOutlet weak var endDatePicker: NSDatePicker!
    @IBOutlet weak var dateSeparatorLabel: NSTextField!
    @IBOutlet weak var categoryFilterOptionsPopUpButton: NSPopUpButton!
    @IBOutlet weak var categoryFilterTextField: NSTextField!
    @IBOutlet weak var amountFilterOptionsPopUpButton: NSPopUpButton!
    @IBOutlet weak var amountFilterTextField: NSTextField!
    @IBOutlet weak var amountFilterOtherTextField: NSTextField!
    @IBOutlet weak var amountSeparatorLabel: NSTextField!
    @IBOutlet weak var vendorFilterOptionsPopUpButton: NSPopUpButton!
    @IBOutlet weak var vendorFilterTextField: NSTextField!
    @IBOutlet weak var filterButton: NSButton!
    
    // List of existing transactions
    fileprivate var transactions: [NSManagedObject] = []
    
    // Current "owner" of the displayed transactions
    fileprivate var transactionsOwner: String = ""
    {
        didSet
        {
            // Update the label
            ownerLabel.stringValue = transactionsOwner
            
            // Update state of some buttons
            addButton.isEnabled = (transactionsOwner != "")
        }
    }
    
    // List of "owners"
    fileprivate var ownersStrings: [String] = []
    
    // Separate view controller to add or edit transaction details
    fileprivate lazy var transactionDetailsViewController: TransactionDetailsViewController = {
        return self.storyboard!.instantiateController(withIdentifier: "TransactionDetailsViewController") as! TransactionDetailsViewController
    }()
    
    // Separate view controller to add new owners
    fileprivate lazy var ownerDetailsViewController: OwnerDetailsViewController = {
        return self.storyboard!.instantiateController(withIdentifier: "OwnerDetailsViewController") as! OwnerDetailsViewController
    }()
    
    // Separate view controller for error message
    fileprivate lazy var errorMessageViewController: ErrorMessageViewController = {
        return self.storyboard!.instantiateController(withIdentifier: "ErrorMessageViewController") as! ErrorMessageViewController
    }()
    
    // Separate view controller for charts and graphs of the data
    fileprivate lazy var chartsGraphViewController: PieChartViewController = {
        return self.storyboard!.instantiateController(withIdentifier: "PieChartViewController") as! PieChartViewController
    }()
    
    // Managed context for Core Data
    fileprivate var cdManagedContext: NSManagedObjectContext?
    
    // Transaction entity description
    fileprivate var transactionEntityDescription: NSEntityDescription?
    
    // The transaction row that is currently selected for editing
    fileprivate var transactionsTableSelectedRowForEdit: Int = -1
    
    // The transaction rows that are selected for deletion
    fileprivate var transactionsTableSelectedRowsForDelete: IndexSet = []
    
    // Object for managing categories
    var categoryData: CategoryData = CategoryData()
    
    // Whether a filter has been applied to the transactions
    var filterApplied: Bool = false
    {
        didSet
        {
            // Enable/disable the show all transactions button depending on if filter is applied
            showAllButton.isEnabled = filterApplied
        }
    }
    
    @IBAction func handleNewButtonPress(_ sender: Any)
    {
        // Set callback function for adding owners
        ownerDetailsViewController.addOwnerCallbackFunction = addOwner
        
        // Show the view
        self.presentViewControllerAsModalWindow(ownerDetailsViewController)
    }
    
    @IBAction func handleLoadButtonPress(_ sender: Any)
    {
        setOwnerAndLoadTransactions()
    }
    
    @IBAction func handleAddButtonPress(_ sender: Any)
    {
        transactionDetailsViewController.categoryData = categoryData
        
        // Set callback function for adding transactions
        transactionDetailsViewController.addTransactionCallbackFunction = addNewTransaction
        
        // Show the transaction details view controller
        self.presentViewControllerAsModalWindow(transactionDetailsViewController)
    }
    
    @IBAction func handleEditButtonPress(_ sender: Any)
    {
        // This behaviour is the same as double click on table row
        openTransactionDetailsForEdit()
    }
    
    @IBAction func handleDeleteButtonPress(_ sender: Any)
    {
        let selectedRows: IndexSet = transactionsTableView.selectedRowIndexes
        guard selectedRows.count > 0 else {
            return
        }
        
        // Save the selected rows
        transactionsTableSelectedRowsForDelete = selectedRows
        
        // Open confirmation dialog
        var messageStr = "Are you sure you want to delete the selected"
        if transactionsTableSelectedRowsForDelete.count == 1
        {
            messageStr += " transaction?"
        }
        else
        {
            messageStr += " transactions?"
        }
        
        errorMessageViewController.errorMessageString = messageStr
        errorMessageViewController.okCallbackFunction = deleteTransactions
        
        self.presentViewControllerAsSheet(errorMessageViewController)
    }
    
    @IBAction func handleAnalyzeButtonPress(_ sender: Any)
    {
        chartsGraphViewController.transactionsData = TransactionsChartData(transactionData: transactions)
        self.presentViewControllerAsModalWindow(chartsGraphViewController)
    }
    
    @IBAction func handleFilterButtonPress(_ sender: Any)
    {
        // Grab date filter info
        let dateFilterOptionString = dateFilterOptionsPopUpButton.titleOfSelectedItem ?? FilterData.FilterDateOptions.none.rawValue
        let startDate: Date = startDatePicker.dateValue
        let endDate: Date = endDatePicker.dateValue
        
        // Sanity check dates
        if dateFilterOptionString == FilterData.FilterDateOptions.between.rawValue &&
            startDate.compare(endDate) == ComparisonResult.orderedDescending
        {
            // TODO: Show error
            print("Start date is after end date")
            return
        }
        
        // Grab category filter info
        let categoryFilterOptionString = categoryFilterOptionsPopUpButton.titleOfSelectedItem ?? FilterData.FilterStringOptions.none.rawValue
        let categoryText: String = categoryFilterTextField.stringValue
        
        // Sanity check category info
        if categoryFilterOptionString != FilterData.FilterStringOptions.none.rawValue &&
            categoryText.isEmpty
        {
            // TODO: Show error
            print("Category field must contain text")
            return
        }
        
        // Grab amount filter info
        let amountFilterOptionString = amountFilterOptionsPopUpButton.titleOfSelectedItem ?? FilterData.FilterNumberOptions.none.rawValue
        let amount: Double = amountFilterTextField.doubleValue
        let amount2: Double = amountFilterOtherTextField.doubleValue
        
        // Sanity check amount info
        if amountFilterOptionString == FilterData.FilterNumberOptions.between.rawValue &&
            (amountFilterTextField.stringValue.isEmpty || amountFilterOtherTextField.stringValue.isEmpty)
        {
            // TODO: Show error
            print("Amount fields must contain a value")
            return
        }
        
        if amountFilterOptionString == FilterData.FilterNumberOptions.between.rawValue &&
            amount > amount2
        {
            // TODO: Show error
            print("First amount is greater than second amount")
            return
        }
        
        if amountFilterOptionString != FilterData.FilterNumberOptions.none.rawValue &&
            amountFilterTextField.stringValue.isEmpty
        {
            // TODO: Show error
            print("Amount field must contain value")
            return
        }
        
        // Grab vendor filter info
        let vendorFilterOptionString = vendorFilterOptionsPopUpButton.titleOfSelectedItem ?? FilterData.FilterStringOptions.none.rawValue
        let vendorText: String = vendorFilterTextField.stringValue
        
        // Sanity check category info
        if vendorFilterOptionString != FilterData.FilterStringOptions.none.rawValue &&
            vendorText.isEmpty
        {
            // TODO: Show error
            print("Vendor field must contain text")
            return
        }
        
        // Create filter data object that will be used for filtering transactions
        let filterData: FilterData = FilterData(dateFilterOption: dateFilterOptionString, startDate: startDate, endDate: endDate, categoryFilterOption: categoryFilterOptionString, categoryText: categoryText, amountFilterOption: amountFilterOptionString, amount: amount, amountOther: amount2, vendorFilterOption: vendorFilterOptionString, vendorText: vendorText)
        
        if let fetchPredicate = filterData.createPredicateForTransactionsFromFilterOptions(transactionOwner: transactionsOwner)
        {
            // Load transactions with given predicate
            loadTransactions(withPredicate: fetchPredicate, updateView: true)
            filterApplied = true
        }
        else
        {
            // TODO: Show error
            print("Error creating predicate for filtering transactions")
            return
        }
    }
    
    @IBAction func handleDateFilterOptionPopUpChoice(_ sender: Any)
    {
        guard let btn = sender as? NSPopUpButton else
        {
            return
        }
        
        guard let dateFilterOptionString = btn.titleOfSelectedItem else
        {
            return
        }
        
        // Hide or show the other date picker
        let isChoiceBetween: Bool = (dateFilterOptionString == FilterData.FilterDateOptions.between.rawValue)
        endDatePicker.isHidden = !isChoiceBetween
        dateSeparatorLabel.isHidden = !isChoiceBetween
    }
    
    @IBAction func handleAmountFilterOptionPopUpChoice(_ sender: Any)
    {
        guard let btn = sender as? NSPopUpButton else
        {
            return
        }
        
        guard let amountFilterOptionString = btn.titleOfSelectedItem else
        {
            return
        }
        
        // Hide or show the other amount
        let isChoiceBetween: Bool = (amountFilterOptionString == FilterData.FilterNumberOptions.between.rawValue)
        amountFilterOtherTextField.isHidden = !isChoiceBetween
        amountSeparatorLabel.isHidden = !isChoiceBetween
    }
    
    @IBAction func handleShowAllButtonPress(_ sender: Any)
    {
        // Load all transactions
        loadTransactions(updateView: true)
        filterApplied = false
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // Try to grab the managed context for core data
        if let appDelegate = NSApplication.shared().delegate as? AppDelegate
        {
            cdManagedContext = appDelegate.managedObjectContext
        }
        
        if let managedContext = cdManagedContext
        {
            // Create entity description for entities
            transactionEntityDescription = NSEntityDescription.entity(forEntityName: "Transaction", in: managedContext)!
        }
        
        // Load last "owner"
        if let loadedLastOwner = UserDefaults.standard.string(forKey: SaveLoadKeys.LastOwner)
        {
            transactionsOwner = loadedLastOwner
        }
        else
        {
            transactionsOwner = ""
        }
        
        // Load all owners
        if let loadedOwners = UserDefaults.standard.stringArray(forKey: SaveLoadKeys.Owners)
        {
            ownersStrings = loadedOwners
        }
        
        setupTransactionsTableView()
        setupOwnersTableView()
        
        // Load transactions of last owner
        if transactionsOwner != ""
        {
            loadTransactions(updateView: true)
        }
        
        setupFiltersSectionDefaultValues()
        filterApplied = false
    }

    override var representedObject: Any?
    {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    // Helper function to set up the transactions table view
    fileprivate func setupTransactionsTableView()
    {
        // Tell the table view about delegate and data source
        transactionsTableView.delegate = self
        transactionsTableView.dataSource = self
        
        // For handling double clicks in the table view
        transactionsTableView.target = self
        transactionsTableView.doubleAction = #selector(transactionsTableViewDoubleClick(_:))
        
        // Create sort descriptors for the columns in the table view
        let descriptorDate = NSSortDescriptor(key: TransactionData.TransactionAttributes.date.rawValue, ascending: false)
        let descriptorCategory = NSSortDescriptor(key: TransactionData.TransactionAttributes.category.rawValue, ascending: true)
        let descriptorAmount = NSSortDescriptor(key: TransactionData.TransactionAttributes.amount.rawValue, ascending: false)
        let descriptorVendor = NSSortDescriptor(key: TransactionData.TransactionAttributes.vendor.rawValue, ascending: true)
        transactionsTableView.tableColumns[0].sortDescriptorPrototype = descriptorDate
        transactionsTableView.tableColumns[1].sortDescriptorPrototype = descriptorCategory
        transactionsTableView.tableColumns[2].sortDescriptorPrototype = descriptorAmount
        transactionsTableView.tableColumns[3].sortDescriptorPrototype = descriptorVendor
    }
    
    func transactionsTableViewDoubleClick(_ sender:AnyObject)
    {
        openTransactionDetailsForEdit()
    }
    
    // Helper function to open the transaction details view to edit a transaction
    fileprivate func openTransactionDetailsForEdit()
    {
        // Check for selected row
        // NOTE: A double-click on empty area in the table view will set selectedRow to -1
        guard transactionsTableView.selectedRow >= 0 && transactionsTableView.selectedRow < transactions.count else {
            return
        }
        
        // Save the selected row so it can be updated later
        transactionsTableSelectedRowForEdit = transactionsTableView.selectedRow
        
        // Grab transaction from selected row for editing
        let transaction = transactions[transactionsTableSelectedRowForEdit]
        
        // Set view controller with selected transaction details
        let dateToEdit: Date = (transaction.value(forKey: TransactionData.TransactionAttributes.date.rawValue) as? Date)!
        let categoryToEdit: String = (transaction.value(forKey: TransactionData.TransactionAttributes.category.rawValue) as? String)!
        let amountToEdit: Double = (transaction.value(forKey: TransactionData.TransactionAttributes.amount.rawValue) as? Double)!
        let vendorToEdit: String = (transaction.value(forKey: TransactionData.TransactionAttributes.vendor.rawValue) as? String)!
        transactionDetailsViewController.setSpecificDetailValues(transaction: TransactionData(transactionDate: dateToEdit, transactionCategory: categoryToEdit, transactionAmount: amountToEdit, transactionVendor: vendorToEdit))
        
        // Set view controller so it knows the difference between adding and editing
        transactionDetailsViewController.editingExistingTransaction = true
        
        // Set callback function to edit a specific transaction
        transactionDetailsViewController.editTransactionCallbackFunction = editTransaction
        
        transactionDetailsViewController.categoryData = categoryData
        
        // Show view controller for editing
        self.presentViewControllerAsModalWindow(transactionDetailsViewController)
    }
    
    // Helper functions to sort the transactions in array
    fileprivate func sortTransactionByDateAscending(transaction1: NSManagedObject, transaction2: NSManagedObject) -> Bool
    {
        let date1: Date = (transaction1.value(forKey: TransactionData.TransactionAttributes.date.rawValue) as? Date)!
        let date2: Date = (transaction2.value(forKey: TransactionData.TransactionAttributes.date.rawValue) as? Date)!
        return (date1.compare(date2) == ComparisonResult.orderedAscending)
    }
    
    fileprivate func sortTransactionByDateDescending(transaction1: NSManagedObject, transaction2: NSManagedObject) -> Bool
    {
        let date1: Date = (transaction1.value(forKey: TransactionData.TransactionAttributes.date.rawValue) as? Date)!
        let date2: Date = (transaction2.value(forKey: TransactionData.TransactionAttributes.date.rawValue) as? Date)!
        return (date1.compare(date2) == ComparisonResult.orderedDescending)
    }
    
    fileprivate func sortTransactionByCategoryAscending(transaction1: NSManagedObject, transaction2: NSManagedObject) -> Bool
    {
        let category1: String = (transaction1.value(forKey: TransactionData.TransactionAttributes.category.rawValue) as? String)!
        let category2: String = (transaction2.value(forKey: TransactionData.TransactionAttributes.category.rawValue) as? String)!
        return (category1.compare(category2) == ComparisonResult.orderedAscending)
    }
    
    fileprivate func sortTransactionByCategoryDescending(transaction1: NSManagedObject, transaction2: NSManagedObject) -> Bool
    {
        let category1: String = (transaction1.value(forKey: TransactionData.TransactionAttributes.category.rawValue) as? String)!
        let category2: String = (transaction2.value(forKey: TransactionData.TransactionAttributes.category.rawValue) as? String)!
        return (category1.compare(category2) == ComparisonResult.orderedDescending)
    }
    
    fileprivate func sortTransactionByAmountAscending(transaction1: NSManagedObject, transaction2: NSManagedObject) -> Bool
    {
        let amount1: Double = (transaction1.value(forKey: TransactionData.TransactionAttributes.amount.rawValue) as? Double)!
        let amount2: Double = (transaction2.value(forKey: TransactionData.TransactionAttributes.amount.rawValue) as? Double)!
        return (amount1 > amount2)
    }
    
    fileprivate func sortTransactionByAmountDescending(transaction1: NSManagedObject, transaction2: NSManagedObject) -> Bool
    {
        let amount1: Double = (transaction1.value(forKey: TransactionData.TransactionAttributes.amount.rawValue) as? Double)!
        let amount2: Double = (transaction2.value(forKey: TransactionData.TransactionAttributes.amount.rawValue) as? Double)!
        return (amount1 < amount2)
    }
    
    fileprivate func sortTransactionByVendorAscending(transaction1: NSManagedObject, transaction2: NSManagedObject) -> Bool
    {
        let vendor1: String = (transaction1.value(forKey: TransactionData.TransactionAttributes.vendor.rawValue) as? String)!
        let vendor2: String = (transaction2.value(forKey: TransactionData.TransactionAttributes.vendor.rawValue) as? String)!
        return (vendor1.compare(vendor2) == ComparisonResult.orderedAscending)
    }
    
    fileprivate func sortTransactionByVendorDescending(transaction1: NSManagedObject, transaction2: NSManagedObject) -> Bool
    {
        let vendor1: String = (transaction1.value(forKey: TransactionData.TransactionAttributes.vendor.rawValue) as? String)!
        let vendor2: String = (transaction2.value(forKey: TransactionData.TransactionAttributes.vendor.rawValue) as? String)!
        return (vendor1.compare(vendor2) == ComparisonResult.orderedDescending)
    }
    
    func addNewTransaction(transaction: TransactionData, updateView: Bool = true)
    {
        // Sanity check the managed context and entity
        guard let managedContext = cdManagedContext else
        {
            return
        }
        
        guard let transactionEntityDesc = transactionEntityDescription else
        {
            return
        }
        
        let transactionToAdd = NSManagedObject(entity: transactionEntityDesc, insertInto: managedContext)
        
        // Copy over transaction values
        transactionToAdd.setValue(transaction.date, forKey: TransactionData.TransactionAttributes.date.rawValue)
        transactionToAdd.setValue(transaction.category, forKey: TransactionData.TransactionAttributes.category.rawValue)
        transactionToAdd.setValue(transaction.amount, forKey: TransactionData.TransactionAttributes.amount.rawValue)
        transactionToAdd.setValue(transaction.vendor, forKey: TransactionData.TransactionAttributes.vendor.rawValue)
        
        // Set the current owner
        transactionToAdd.setValue(transactionsOwner, forKey: TransactionData.TransactionAttributes.owner.rawValue)
        
        // "Commit" changes to the managed object context by calling save
        do
        {
            try managedContext.save()
            
            // Insert into array
            transactions.append(transactionToAdd)
            
            // Update transactions table view if needed
            if updateView
            {
                transactionsTableView.reloadData()
            }
        }
        catch let error as NSError
        {
            // TODO: Show error to user
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    func loadTransactions(updateView: Bool)
    {
        // Create predicate to load transactions of owner
        let predicate: NSPredicate = NSPredicate(format: "%K == %@", TransactionData.TransactionAttributes.owner.rawValue, transactionsOwner)
        
        loadTransactions(withPredicate: predicate, updateView: updateView)
    }
    
    func loadTransactions(withPredicate predicate: NSPredicate?, updateView: Bool)
    {
        // Sanity check the managed context
        guard let managedContext = cdManagedContext else
        {
            return
        }
        
        // Create a fetch request for the transactions
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Transaction")
        
        // Add predicate if not nil
        if let predicateToAdd = predicate
        {
            fetchRequest.predicate = predicateToAdd
        }
        
        // Pass the fetch request to the managed object context to do the work
        do
        {
            transactions = try managedContext.fetch(fetchRequest)
            
            // Update transactions table view if needed
            if updateView
            {
                transactionsTableView.reloadData()
            }
        }
        catch let error as NSError
        {
            // TODO: Show error to user
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
    
    func editTransaction(transaction: TransactionData, updateView: Bool = true)
    {
        // Sanity check the selected row
        if transactionsTableSelectedRowForEdit < 0
        {
            return
        }
        
        // Sanity check the managed context
        guard let managedContext = cdManagedContext else
        {
            // Reset selected row
            transactionsTableSelectedRowForEdit = -1
            
            return
        }
        
        // Grab transaction from selected row for editing
        let transactionInTable = transactions[transactionsTableSelectedRowForEdit]
        
        // Set view controller with selected transaction details
        let dateInTable: Date = (transactionInTable.value(forKey: TransactionData.TransactionAttributes.date.rawValue) as? Date)!
        let categoryInTable: String = (transactionInTable.value(forKey: TransactionData.TransactionAttributes.category.rawValue) as? String)!
        let amountInTable: Double = (transactionInTable.value(forKey: TransactionData.TransactionAttributes.amount.rawValue) as? Double)!
        let vendorInTable: String = (transactionInTable.value(forKey: TransactionData.TransactionAttributes.vendor.rawValue) as? String)!
        
        var updatedValues: Bool = false
        
        if transaction.date != dateInTable
        {
            transactionInTable.setValue(transaction.date, forKey: TransactionData.TransactionAttributes.date.rawValue)
            updatedValues = true
        }
        if transaction.category != categoryInTable
        {
            transactionInTable.setValue(transaction.category, forKey: TransactionData.TransactionAttributes.category.rawValue)
            updatedValues = true
        }
        if transaction.amount != amountInTable
        {
            transactionInTable.setValue(transaction.amount, forKey: TransactionData.TransactionAttributes.amount.rawValue)
            updatedValues = true
        }
        if transaction.vendor != vendorInTable
        {
            transactionInTable.setValue(transaction.vendor, forKey: TransactionData.TransactionAttributes.vendor.rawValue)
            updatedValues = true
        }
        
        if updatedValues
        {
            // "Commit" changes to the managed object context by calling save
            do
            {
                try managedContext.save()
                
                // Update table view if needed
                if updateView
                {
                    transactionsTableView.reloadData()
                }
            }
            catch let error as NSError
            {
                // TODO: Show error to user
                print("Could not save. \(error), \(error.userInfo)")
            }
        }
        
        // Reset selected row
        transactionsTableSelectedRowForEdit = -1
    }
    
    func deleteTransactions()
    {
        // Sanity check the selected row(s)
        if transactionsTableSelectedRowsForDelete.count < 0
        {
            return
        }
        
        // Sanity check the managed context
        guard let managedContext = cdManagedContext else
        {
            // Reset selected row(s)
            transactionsTableSelectedRowsForDelete.removeAll()
            
            return
        }
        
        // Delete the objects from managed context
        for deleteIdx in transactionsTableSelectedRowsForDelete.reversed()
        {
            managedContext.delete(transactions[deleteIdx])
        }
        
        // "Commit" changes to the managed object context by calling save
        do
        {
            try managedContext.save()
            
            // Delete the rows from the table
            for deleteIdx in transactionsTableSelectedRowsForDelete.reversed()
            {
                transactions.remove(at: deleteIdx)
            }
            
            // Update table view
            transactionsTableView.reloadData()
        }
        catch let error as NSError
        {
            // TODO: Show error to user
            print("Could not save. \(error), \(error.userInfo)")
        }
        
        // Reset selected row(s)
        transactionsTableSelectedRowsForDelete.removeAll()
    }
    
    // Helper function to set up the owners table view
    fileprivate func setupOwnersTableView()
    {
        // Tell the owners view about delegate and data source
        ownersTableView.delegate = self
        ownersTableView.dataSource = self
        
        // For handling double clicks in the table view
        ownersTableView.target = self
        ownersTableView.doubleAction = #selector(ownersTableViewDoubleClick(_:))
    }
    
    func ownersTableViewDoubleClick(_ sender:AnyObject)
    {
        setOwnerAndLoadTransactions()
    }
    
    // Helper function to change the current owner to selected one in the table and load those transactions
    fileprivate func setOwnerAndLoadTransactions()
    {
        // Check for selected row -- a double-click on empty area in the table view will set selectedRow to -1
        guard ownersTableView.selectedRow >= 0 && ownersTableView.selectedRow < ownersStrings.count else {
            return
        }
        
        // Grab string from selected row for editing
        let newOwnerString: String = ownersStrings[ownersTableView.selectedRow]
        
        if newOwnerString != transactionsOwner
        {
            transactionsOwner = newOwnerString
            
            // Save out last owner
            UserDefaults.standard.set(transactionsOwner, forKey: SaveLoadKeys.LastOwner)
            
            // Now load the transactions for the new owner
            loadTransactions(updateView: true)
        }
    }
    
    // Return value of 0 means successful add.
    // Return value < 0 means some sort of error.
    func addOwner(name: String) -> Int
    {
        if name == ""
        {
            return AddOwnerResult.GeneralError
        }
        
        // Check if owner name already exists
        if ownersStrings.contains(name)
        {
            return AddOwnerResult.NameAlreadyExistsError
        }
        
        // Add to the list and save
        ownersStrings.append(name)
        UserDefaults.standard.set(ownersStrings, forKey: SaveLoadKeys.Owners)
        
        // Update the table
        ownersTableView.reloadData()
        
        return AddOwnerResult.Success
    }
    
    // Helper function to set up filters section to default values
    fileprivate func setupFiltersSectionDefaultValues()
    {
        // Date
        dateFilterOptionsPopUpButton.removeAllItems()
        dateFilterOptionsPopUpButton.addItems(withTitles: FilterData.filterDateOptions)
        dateFilterOptionsPopUpButton.selectItem(withTitle: FilterData.FilterDateOptions.none.rawValue)
        startDatePicker.dateValue = Date()
        endDatePicker.dateValue = Date()
        endDatePicker.isHidden = true
        dateSeparatorLabel.isHidden = true
        
        // Category
        categoryFilterOptionsPopUpButton.removeAllItems()
        categoryFilterOptionsPopUpButton.addItems(withTitles: FilterData.filterStringOptions)
        categoryFilterOptionsPopUpButton.selectItem(withTitle: FilterData.FilterStringOptions.none.rawValue)
        categoryFilterTextField.stringValue = ""
        
        // Amount
        amountFilterOptionsPopUpButton.removeAllItems()
        amountFilterOptionsPopUpButton.addItems(withTitles: FilterData.filterNumberOptions)
        amountFilterOptionsPopUpButton.selectItem(withTitle: FilterData.FilterNumberOptions.none.rawValue)
        amountFilterTextField.stringValue = ""
        amountFilterOtherTextField.stringValue = ""
        amountFilterOtherTextField.isHidden = true
        amountSeparatorLabel.isHidden = true
        
        // Vendor
        vendorFilterOptionsPopUpButton.removeAllItems()
        vendorFilterOptionsPopUpButton.addItems(withTitles: FilterData.filterStringOptions)
        vendorFilterOptionsPopUpButton.selectItem(withTitle: FilterData.FilterStringOptions.none.rawValue)
        vendorFilterTextField.stringValue = ""
    }
}

// Extension for the table view data source
extension ViewController: NSTableViewDataSource
{
    // Return the number of rows that should be shown
    func numberOfRows(in tableView: NSTableView) -> Int
    {
        var numRows: Int = -1
        if tableView == transactionsTableView
        {
            numRows = transactions.count
        }
        else if tableView == ownersTableView
        {
            numRows = ownersStrings.count
        }
        
        return numRows
    }
    
    // Sort data based on sort descriptor in column that was changed
    func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor])
    {
        if tableView == transactionsTableView
        {
            // Retrieve the first sort descriptor that corresponds to the column clicked by the user
            guard let sortDescriptor = transactionsTableView.sortDescriptors.first else {
                return
            }
            
            let sortKey = sortDescriptor.key!
            let sortAscending = sortDescriptor.ascending
            
            // print("Need to sort: \(sortKey) in order \(sortAscending)")
            if sortKey == TransactionData.TransactionAttributes.date.rawValue
            {
                transactions.sort(by: sortAscending ? sortTransactionByDateAscending : sortTransactionByDateDescending)
            }
            else if sortKey == TransactionData.TransactionAttributes.category.rawValue
            {
                transactions.sort(by: sortAscending ? sortTransactionByCategoryAscending : sortTransactionByCategoryDescending)
            }
            else if sortKey == TransactionData.TransactionAttributes.amount.rawValue
            {
                transactions.sort(by: sortAscending ? sortTransactionByAmountAscending : sortTransactionByAmountDescending)
            }
            else if sortKey == TransactionData.TransactionAttributes.vendor.rawValue
            {
                transactions.sort(by: sortAscending ? sortTransactionByVendorAscending : sortTransactionByVendorDescending)
            }
            
            // Reload table now that array is sorted
            transactionsTableView.reloadData()
        }
    }
}

// Extension to implement the table view delegate
extension ViewController: NSTableViewDelegate
{
    fileprivate enum CellIdentifiers
    {
        static let DateCell = "DateCellID"
        static let CategoryCell = "CategoryCellID"
        static let AmountCell = "AmountCellID"
        static let VendorCell = "VendorCellID"
        static let OwnersCell = "OwnersCellID"
    }
    
    // Build each cell based on given column and row
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView?
    {
        if tableView == transactionsTableView
        {
            var text: String = ""
            var cellIdentifier: String = ""
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = DateFormatter.Style.short
            dateFormatter.timeStyle = DateFormatter.Style.none
            
            let currencyFormatter = NumberFormatter()
            currencyFormatter.numberStyle = NumberFormatter.Style.currency
            
            // Check for transaction at the given row
            if row >= transactions.count
            {
                return nil
            }
            
            let transaction = transactions[row]
            
            // Check which column and populate the information
            if tableColumn == tableView.tableColumns[0]
            {
                // Date
                text = dateFormatter.string(from: (transaction.value(forKey: TransactionData.TransactionAttributes.date.rawValue) as? Date)!)
                cellIdentifier = CellIdentifiers.DateCell
            }
            else if tableColumn == tableView.tableColumns[1]
            {
                // Category
                text = (transaction.value(forKey: TransactionData.TransactionAttributes.category.rawValue) as? String)!
                cellIdentifier = CellIdentifiers.CategoryCell
            }
            else if tableColumn == tableView.tableColumns[2]
            {
                // Amount
                if let formattedCurrencyString = currencyFormatter.string(from: NSNumber(value: (transaction.value(forKey: TransactionData.TransactionAttributes.amount.rawValue) as? Double)!))
                {
                    text = formattedCurrencyString
                }
                else
                {
                    text = ""
                }
                cellIdentifier = CellIdentifiers.AmountCell
            }
            else if tableColumn == tableView.tableColumns[3]
            {
                // Vendor
                text = (transaction.value(forKey: TransactionData.TransactionAttributes.vendor.rawValue) as? String)!
                cellIdentifier = CellIdentifiers.VendorCell
            }
            
            // Create the cell with the information
            if let cell = tableView.make(withIdentifier: cellIdentifier, owner: nil) as? NSTableCellView
            {
                cell.textField?.stringValue = text
                return cell
            }
        }
        else if tableView == ownersTableView
        {
            var text: String = ""
            var cellIdentifier: String = ""
            
            // Check for transaction at the given row
            if row >= ownersStrings.count
            {
                return nil
            }
            
            // Grab string from selected row for editing
            let ownerString: String = ownersStrings[row]
            text = ownerString
            cellIdentifier = CellIdentifiers.OwnersCell
            
            // Create the cell with the information
            if let cell = tableView.make(withIdentifier: cellIdentifier, owner: nil) as? NSTableCellView
            {
                cell.textField?.stringValue = text
                return cell
            }
        }
        
        return nil
    }
}

