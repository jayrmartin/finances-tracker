//
//  TransactionsChartData.swift
//  Finances-Tracker
//
//  Created by Jason Martin on 2017-02-10.
//  Copyright © 2017 Jason Martin. All rights reserved.
//

import Foundation
import Cocoa

/*
 * Class to help organize transactions data for use in charts and graphs.
 */

class TransactionsChartData
{
    // The list of transactions
    var transactions: [TransactionData] = []
    
    // Total amount of transactions
    var totalTransactionsAmount: Double = 0
    
    // Dictionary of transactions based on category.
    // The key is the category name and the value is the amount of transactions for that category.
    var categoryAmounts: [String: Double] = [:]
    
    init( transactionData: [NSManagedObject] )
    {
        convertTransactions(transactionData: transactionData)
        calculateCategoryAmounts(calculateTotal: true)
    }
    
    // Helper function to convert NSManagedObject transactions into TransactionData
    fileprivate func convertTransactions( transactionData: [NSManagedObject] )
    {
        for transaction in transactionData
        {
            let date: Date = (transaction.value(forKey: TransactionData.TransactionAttributes.date.rawValue) as? Date)!
            let category: String = (transaction.value(forKey: TransactionData.TransactionAttributes.category.rawValue) as? String)!
            let amount: Double = (transaction.value(forKey: TransactionData.TransactionAttributes.amount.rawValue) as? Double)!
            let vendor: String = (transaction.value(forKey: TransactionData.TransactionAttributes.vendor.rawValue) as? String)!
            
            let newTransaction: TransactionData = TransactionData(transactionDate: date, transactionCategory: category, transactionAmount: amount, transactionVendor: vendor)
            transactions.append(newTransaction)
        }
    }
    
    // Helper function to calculate the total amount of transactions
    fileprivate func calculateTotalTransactionsAmount()
    {
        totalTransactionsAmount = 0
        for transaction in transactions
        {
            totalTransactionsAmount += transaction.amount
        }
    }
    
    // Helper function to calculate the total amount of transactions for each category.
    // Param: calculateTotal - If true, calculate the total amount of transactions at the same time
    fileprivate func calculateCategoryAmounts( calculateTotal: Bool )
    {
        if calculateTotal
        {
            totalTransactionsAmount = 0
        }
        
        for transaction in transactions
        {
            categoryAmounts[transaction.category] = (categoryAmounts[transaction.category] ?? 0) + transaction.amount
            
            if calculateTotal
            {
                totalTransactionsAmount += transaction.amount
            }
        }
    }
    
}
