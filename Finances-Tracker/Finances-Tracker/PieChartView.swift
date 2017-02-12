//
//  PieChartView.swift
//  Finances-Tracker
//
//  Created by Jason Martin on 2017-02-09.
//  Copyright © 2017 Jason Martin. All rights reserved.
//

import Cocoa

class PieChartView: NSView
{
    fileprivate static let PieChartWidthPercent: CGFloat = 0.70
    fileprivate static let PieChartMargin: CGFloat = 40.0
    fileprivate static let PieChartMinRadius: CGFloat = 40.0
    fileprivate static let LegendMargin: CGFloat = 20.0
    fileprivate static let LegendTextHSpace: CGFloat = 5
    fileprivate static let LegendTextXSpace: CGFloat = 5
    
    fileprivate static let TotalString: String = "Total: "
    
    fileprivate static let PieChartColors: [NSColor] =
    [
        NSColor.red,
        NSColor.green,
        NSColor.blue,
        NSColor.cyan,
        NSColor.yellow,
        NSColor.magenta,
        NSColor.orange,
        NSColor.purple,
        NSColor.brown
    ]
    
    // Set of transactions to display in pie chart
    var transactionsData: TransactionsChartData?
    {
        didSet
        {
            needsDisplay = true
        }
    }
    
    // Specific function to draw the pie chart
    fileprivate func drawPieChart()
    {
        guard let transactionsData = transactionsData else
        {
            return
        }
        
        let pieChartRect = pieChartRectangle()
        let legendRect = legendRectangle()
        
        // Draw the back circle
        let bgCircle = NSBezierPath(ovalIn: pieChartRect)
        NSColor.white.setFill()
        NSColor.black.setStroke()
        bgCircle.stroke()
        bgCircle.fill()
        
        // For drawing sections of the pie
        let center = CGPoint(x: pieChartRect.midX, y: pieChartRect.midY)
        let radius = pieChartRect.size.width / 2.0
        var startAngle: CGFloat = 90
        var colorIdx: Int = 0
        
        // For drawing legend entries
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = NSLineBreakMode.byTruncatingTail
        paragraphStyle.alignment = NSTextAlignment.left
        let legendTextAttributes = [NSFontAttributeName: NSFont.systemFont(ofSize: 14), NSParagraphStyleAttributeName: paragraphStyle]
        let legendTextSize: NSSize = PieChartView.TotalString.size(withAttributes: legendTextAttributes)
        let legendTextHWithSpace: CGFloat = legendTextSize.height + PieChartView.LegendTextHSpace
        let legendTextTotalSpaceToUse: CGFloat = CGFloat(transactionsData.categoryAmounts.count + 1) * legendTextHWithSpace
        var legendY: CGFloat = legendRect.maxY - legendTextSize.height - ((legendRect.height - legendTextTotalSpaceToUse) / 2)
        let legendX: CGFloat = legendRect.minX + PieChartView.LegendTextXSpace
        let legendSquareSz: CGFloat = legendTextSize.height - 2
        
        //Swift.print("total transactions: \(transactionsData.totalTransactionsAmount)")
        
        // Draw the total
        let currencyFormatter: NumberFormatter = NumberFormatter()
        currencyFormatter.numberStyle = NumberFormatter.Style.currency
        var legendTextRect: CGRect = CGRect(x: legendX, y: legendY, width: legendRect.width, height: legendTextSize.height)
        let totalString: String = PieChartView.TotalString + currencyFormatter.string(from: NSNumber(value: transactionsData.totalTransactionsAmount))!
        totalString.draw(in: legendTextRect, withAttributes: legendTextAttributes)
        legendY -= legendTextHWithSpace
        
        // Draw the sections of the pie and corresponding legend entries
        for categoryData in transactionsData.categoryAmounts
        {
            // Get current colour and increment for next loop
            let fillColor: NSColor = PieChartView.PieChartColors[colorIdx]
            colorIdx = (colorIdx + 1) % PieChartView.PieChartColors.count
            
            //Swift.print("drawing category: \(categoryData.key) with amount: \(categoryData.value)")
            
            // Calculate how much to fill
            let usedPercent = categoryData.value / transactionsData.totalTransactionsAmount
            let endAngle = startAngle + CGFloat(360 * usedPercent)
            
            let path = NSBezierPath()
            path.move(to: center)
            path.appendArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle)
            path.close()
            fillColor.setStroke()
            path.stroke()
            
            // Fill the section
            if let gradient = NSGradient(starting: fillColor, ending: fillColor)
            {
                gradient.draw(in: path, angle: 90.0)
            }
            
            // Move angle for next one
            startAngle = endAngle
            
            // Legend
            // Square
            let legendDrawRect: CGRect = CGRect(x: legendX, y: legendY + 1, width: legendSquareSz, height: legendSquareSz)
            fillColor.setFill()
            NSRectFill(legendDrawRect)
            
            // Text
            let textX = legendDrawRect.maxX + PieChartView.LegendTextXSpace
            legendTextRect = CGRect(x: textX, y: legendY, width: legendRect.width - legendDrawRect.width, height: legendTextSize.height)
            let textString: String = categoryData.key + " - " + currencyFormatter.string(from: NSNumber(value: categoryData.value))!
            textString.draw(in: legendTextRect, withAttributes: legendTextAttributes)
            legendY -= legendTextHWithSpace
        }
    }
    
    // Calculate the rectangle to draw the pie chart in
    fileprivate func pieChartRectangle() -> CGRect
    {
        let width = (bounds.size.width * PieChartView.PieChartWidthPercent) - (2 * PieChartView.PieChartMargin)
        let height = bounds.size.height - (2 * PieChartView.PieChartMargin)
        let diameter = max(min(width, height), PieChartView.PieChartMinRadius)
        let rect = CGRect(x: PieChartView.PieChartMargin, y: bounds.midY - (diameter / 2.0), width: diameter, height: diameter)
        return rect
    }
    
    // Calculate the rectangle to draw the legend for the pie chart sections
    fileprivate func legendRectangle() -> CGRect
    {
        let pieChartRect = pieChartRectangle()
        let width = bounds.size.width - pieChartRect.maxX - (2 * PieChartView.LegendMargin)
        let height = bounds.size.height - (2 * PieChartView.LegendMargin)
        let rect = CGRect(x: pieChartRect.maxX + PieChartView.LegendMargin, y: PieChartView.LegendMargin, width: width, height: height)
        return rect
    }
    
    override func draw(_ dirtyRect: NSRect)
    {
        super.draw(dirtyRect)
        
        drawPieChart()
    }
    
}
