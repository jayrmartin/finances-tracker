//
//  CategoryData.swift
//  Finances-Tracker
//
//  Created by Jason Martin on 2017-02-07.
//  Copyright © 2017 Jason Martin. All rights reserved.
//

import Foundation

/*
 * Class to hold default category names and manage custom category names.
 */

class CategoryData
{
    // Array of base options in the category popup button
    var categoryStrings: [String] = [
        "Mortgage",
        "Rent",
        "Property Tax",
        "Condo/Strata Fees",
        "Insurance - House",
        "Utilities - Hydro",
        "Utilities - Natural Gas",
        "Utilities - Water",
        "Cable and Internet",
        "Maintenance - House",
        "Furniture",
        "Car Payments",
        "Gas",
        "Parking",
        "Maintenance - Car",
        "Insurance - Car",
        "Insurance - Life",
        "Transit",
        "Grocery",
        "Dining Out",
        "Alcohol",
        "Cell Phone",
        "Gym and Fitness",
        "Clothes",
        "Charity",
        "Vacations",
        "Entertainment",
        "Beauty",
        "Medical",
        "Dental"
    ]
    
    // Array of custom categories
    var customCategoryStrings: [String] = []
    
    init()
    {
        // Load custom categories
        loadCustomCategories()
    }
    
    // Load the custom categories
    func loadCustomCategories()
    {
        if let loadedCustomCategory = UserDefaults.standard.stringArray(forKey: ViewController.SaveLoadKeys.CustomCategories)
        {
            customCategoryStrings = loadedCustomCategory
        }
    }
    
    // Save the custom categories
    func saveCustomCategories()
    {
        UserDefaults.standard.set(customCategoryStrings, forKey: ViewController.SaveLoadKeys.CustomCategories)
    }
    
    // Add the given category name
    // Returns true if add was successful, false if given name already exists
    func addCategory(name: String) -> Bool
    {
        if name == ""
        {
            return false
        }
        
        // Check category name already exists
        if categoryStrings.contains(name) || customCategoryStrings.contains(name)
        {
            return false
        }
        
        // Add to the list and save
        customCategoryStrings.append(name)
        saveCustomCategories()
        
        return true
    }
    
    // Delete the category names at the given indices
    func deleteCategories(indices: IndexSet)
    {
        // Sanity check the selected row(s)
        if indices.count < 0
        {
            return
        }
        
        // Delete the objects from managed context
        for deleteIdx in indices.reversed()
        {
            if deleteIdx >= 0 && deleteIdx < customCategoryStrings.count
            {
                customCategoryStrings.remove(at: deleteIdx)
            }
        }
        
        saveCustomCategories()
    }
    
}
