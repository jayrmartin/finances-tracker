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
    // References to specific UI objects
    @IBOutlet weak var newButton: NSButton!
    @IBOutlet weak var loadButton: NSButton!
    @IBOutlet weak var addButton: NSButton!
    @IBOutlet weak var transactionsTableView: NSTableView!
    
    // List of existing transactions
    fileprivate var transactions: [NSManagedObject] = []
    
    // Separate view controller to add or edit transaction details
    fileprivate lazy var transactionDetailsViewController: TransactionDetailsViewController = {
        return self.storyboard!.instantiateController(withIdentifier: "TransactionDetailsViewController") as! TransactionDetailsViewController
    }()
    
    @IBAction func handleNewButtonPress(_ sender: Any)
    {
        print("New Button Pressed!")
    }
    
    @IBAction func handleLoadButtonPress(_ sender: Any)
    {
        print("Load Button Pressed")
    }
    
    @IBAction func handleAddButtonPress(_ sender: Any)
    {
        print("Add Button Pressed")
        
        //self.presentViewControllerAsSheet(transactionDetailsViewController)
        self.presentViewControllerAsModalWindow(transactionDetailsViewController)
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any?
    {
        didSet {
        // Update the view, if already loaded.
        }
    }
}

