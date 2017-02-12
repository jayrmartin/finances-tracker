//
//  TransactionData.swift
//  Finances-Tracker
//
//  Created by Jason Martin on 2017-01-22.
//  Copyright © 2017 Jason Martin. All rights reserved.
//

import Foundation

/*
 * This will be a simple class that holds transaction details data.
 * This mirrors the Transaction entity in the Core Data model.
 * It exists so transaction data can be more easily passed between classes and functions.
 *
 * NOTE: If the Transaction entity is changed in the Core Data model, this class should be updated to match.
 */

class TransactionData: NSObject
{
    enum TransactionAttributes: String
    {
        case date,
        category,
        amount,
        vendor,
        owner
    }
    
    var date: Date = Date()
    var category: String = ""
    var amount: Double = 0
    var vendor: String = ""
    var owner: String = ""
    
    init(transactionDate: Date, transactionCategory: String, transactionAmount: Double, transactionVendor: String, transactionOwner: String)
    {
        date = transactionDate
        category = transactionCategory
        amount = transactionAmount
        vendor = transactionVendor
        owner = transactionOwner
    }
    
    convenience init(transactionDate: Date, transactionCategory: String, transactionAmount: Double, transactionVendor: String)
    {
        self.init(transactionDate: transactionDate, transactionCategory: transactionCategory, transactionAmount: transactionAmount, transactionVendor: transactionVendor, transactionOwner: "")
    }
}
