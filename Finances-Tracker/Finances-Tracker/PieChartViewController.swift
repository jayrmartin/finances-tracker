//
//  PieChartViewController.swift
//  Finances-Tracker
//
//  Created by Jason Martin on 2017-02-09.
//  Copyright © 2017 Jason Martin. All rights reserved.
//

import Cocoa

class PieChartViewController: NSViewController
{
    // Transaction data
    var transactionsData: TransactionsChartData?
    
    @IBOutlet weak var pieChartView: PieChartView!
    @IBOutlet weak var noDataTextField: NSTextField!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
    }
    
    override func viewWillAppear()
    {
        super.viewWillAppear()
        
        // Set data that view needs
        if transactionsData != nil
        {
            pieChartView.transactionsData = transactionsData
            
            // Hide the no data text
            noDataTextField.isHidden = true
        }
        else
        {
            noDataTextField.isHidden = false
        }
    }
    
}
