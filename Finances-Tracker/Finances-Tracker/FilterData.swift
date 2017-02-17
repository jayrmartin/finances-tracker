//
//  FilterData.swift
//  Finances-Tracker
//
//  Created by Jason Martin on 2017-02-16.
//  Copyright © 2017 Jason Martin. All rights reserved.
//

import Foundation

/*
 * A class to represent information about filtering information about transactions.
 */

class FilterData: NSObject
{
    // Options for filtering dates
    enum FilterDateOptions: String
    {
        case none,
        before,
        after,
        between
    }
    static let filterDateOptions: [String] = [
        FilterDateOptions.none.rawValue,
        FilterDateOptions.before.rawValue,
        FilterDateOptions.after.rawValue,
        FilterDateOptions.between.rawValue
    ]
    
    // Options for filtering dollar amounts
    enum FilterNumberOptions: String
    {
        case none,
        equals,
        greater = "greater than",
        less = "less than",
        between
    }
    static let filterNumberOptions: [String] = [
        FilterNumberOptions.none.rawValue,
        FilterNumberOptions.equals.rawValue,
        FilterNumberOptions.greater.rawValue,
        FilterNumberOptions.less.rawValue,
        FilterNumberOptions.between.rawValue
    ]
    
    // Options for filtering strings
    enum FilterStringOptions: String
    {
        case none,
        equals,
        contains
    }
    static let filterStringOptions: [String] = [
        FilterStringOptions.none.rawValue,
        FilterStringOptions.equals.rawValue,
        FilterStringOptions.contains.rawValue
    ]
    
    // Date filter info
    var dateFilterOption: String = FilterDateOptions.none.rawValue
    var startDate: Date = Date()
    var endDate: Date = Date()
    
    // Category filter info
    var categoryFilterOption: String = FilterStringOptions.none.rawValue
    var categoryText: String = ""
    
    // Amount filter info
    var amountFilterOption: String = FilterNumberOptions.none.rawValue
    var amount: Double = 0
    var amountOther: Double = 0
    
    // Vendor filter info
    var vendorFilterOption: String = FilterStringOptions.none.rawValue
    var vendorText: String = ""
    
    override init()
    {
    }
    
    init(dateFilterOption: String, startDate: Date, endDate: Date, categoryFilterOption: String, categoryText: String, amountFilterOption: String, amount: Double, amountOther: Double, vendorFilterOption: String, vendorText: String)
    {
        self.dateFilterOption = dateFilterOption
        self.startDate = startDate
        self.endDate = endDate
        self.categoryFilterOption = categoryFilterOption
        self.categoryText = categoryText
        self.amountFilterOption = amountFilterOption
        self.amount = amount
        self.amountOther = amountOther
        self.vendorFilterOption = vendorFilterOption
        self.vendorText = vendorText
    }
    
    // Return a NSPredicate that can be used to fetch transactions based on this object's filter options
    // NOTE: Returns nil if no predicate could be created
    // param transactionOwner - The string to add to the predicate for the owner of the transactions
    func createPredicateForTransactionsFromFilterOptions(transactionOwner: String) -> NSPredicate?
    {
        var predicateString: String = ""
        var predicateArguments: [Any] = []
        
        // Add to predicate for date
        switch dateFilterOption
        {
        case FilterDateOptions.none.rawValue:
            // Nothing
            break
            
        case FilterDateOptions.before.rawValue:
            predicateString += (!predicateString.isEmpty) ? " AND " : ""
            predicateString += "%K <= %@"
            predicateArguments.append(TransactionData.TransactionAttributes.date.rawValue)
            predicateArguments.append(startDate)
            break
            
        case FilterDateOptions.after.rawValue:
            predicateString += (!predicateString.isEmpty) ? " AND " : ""
            predicateString += "%K >= %@"
            predicateArguments.append(TransactionData.TransactionAttributes.date.rawValue)
            predicateArguments.append(startDate)
            break
            
        case FilterDateOptions.between.rawValue:
            predicateString += (!predicateString.isEmpty) ? " AND " : ""
            predicateString += "%K >= %@ AND %K <= %@"
            predicateArguments.append(TransactionData.TransactionAttributes.date.rawValue)
            predicateArguments.append(startDate)
            predicateArguments.append(TransactionData.TransactionAttributes.date.rawValue)
            predicateArguments.append(endDate)
            break
            
        default:
            // Nothing
            break
        }
        
        // Add to predicate for category
        switch categoryFilterOption
        {
        case FilterStringOptions.none.rawValue:
            // Nothing
            break
            
        case FilterStringOptions.equals.rawValue:
            predicateString += (!predicateString.isEmpty) ? " AND " : ""
            predicateString += "%K == %@"
            predicateArguments.append(TransactionData.TransactionAttributes.category.rawValue)
            predicateArguments.append(categoryText)
            break
            
        case FilterStringOptions.contains.rawValue:
            predicateString += (!predicateString.isEmpty) ? " AND " : ""
            predicateString += "%K CONTAINS[cd] %@"
            predicateArguments.append(TransactionData.TransactionAttributes.category.rawValue)
            predicateArguments.append(categoryText)
            break
            
        default:
            // Nothing
            break
        }
        
        // Add to predicate for amount
        switch amountFilterOption
        {
        case FilterNumberOptions.none.rawValue:
            // Nothing
            break
            
        case FilterNumberOptions.equals.rawValue:
            predicateString += (!predicateString.isEmpty) ? " AND " : ""
            predicateString += "%K == %@"
            predicateArguments.append(TransactionData.TransactionAttributes.amount.rawValue)
            predicateArguments.append(amount)
            break
            
        case FilterNumberOptions.greater.rawValue:
            predicateString += (!predicateString.isEmpty) ? " AND " : ""
            predicateString += "%K > %@"
            predicateArguments.append(TransactionData.TransactionAttributes.amount.rawValue)
            predicateArguments.append(amount)
            break
            
        case FilterNumberOptions.less.rawValue:
            predicateString += (!predicateString.isEmpty) ? " AND " : ""
            predicateString += "%K < %@"
            predicateArguments.append(TransactionData.TransactionAttributes.amount.rawValue)
            predicateArguments.append(amount)
            break
            
        case FilterNumberOptions.between.rawValue:
            predicateString += (!predicateString.isEmpty) ? " AND " : ""
            predicateString += "%K BETWEEN {%@, %@}"
            predicateArguments.append(TransactionData.TransactionAttributes.amount.rawValue)
            predicateArguments.append(amount)
            predicateArguments.append(amountOther)
            break
            
        default:
            // Nothing
            break
        }
        
        // Add to predicate for vendor
        switch vendorFilterOption
        {
        case FilterStringOptions.none.rawValue:
            // Nothing
            break
            
        case FilterStringOptions.equals.rawValue:
            predicateString += (!predicateString.isEmpty) ? " AND " : ""
            predicateString += "%K == %@"
            predicateArguments.append(TransactionData.TransactionAttributes.vendor.rawValue)
            predicateArguments.append(vendorText)
            break
            
        case FilterStringOptions.contains.rawValue:
            predicateString += (!predicateString.isEmpty) ? " AND " : ""
            predicateString += "%K CONTAINS[cd] %@"
            predicateArguments.append(TransactionData.TransactionAttributes.vendor.rawValue)
            predicateArguments.append(vendorText)
            break
            
        default:
            // Nothing
            break
        }
        
        if predicateString.isEmpty
        {
            // Nothing to search
            return nil
        }
        
        // Add the transaction owner to the predicate
        if !transactionOwner.isEmpty
        {
            predicateString += (!predicateString.isEmpty) ? " AND " : ""
            predicateString += "%K == %@"
            predicateArguments.append(TransactionData.TransactionAttributes.owner.rawValue)
            predicateArguments.append(transactionOwner)
        }
        
        // Attempt to create the predicate
        do
        {
            let finalPredicate: NSPredicate = try NSPredicate(format: predicateString, argumentArray: predicateArguments)
            return finalPredicate
        }
        catch
        {
            // Problem creating the predicate
            return nil
        }
        
        return nil
    }
}
