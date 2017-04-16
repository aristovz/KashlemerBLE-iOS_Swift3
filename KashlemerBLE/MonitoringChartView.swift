//
//  MonitoringChartView.swift
//  KashlemerBLE
//
//  Created by Pavel Aristov on 16.04.17.
//  Copyright © 2017 aristovz. All rights reserved.
//

import UIKit
import Charts

class MonitoringChartView: LineChartView {
    private var _setColor: UIColor = .blue
    
    var maxEntryCount = 1000
    
    func initChartView(_ setColor: UIColor = .blue) {
        self.data = LineChartData()
        self._setColor = setColor
        
        self.noDataText = ""
        self.chartDescription?.text = ""
        self.legend.enabled = false
        self.leftAxis.enabled = false
        
        self.rightAxis.labelFont = UIFont(name: "HelveticaNeue-Light", size: 9)!
        self.rightAxis.granularity = 100

        self.xAxis.labelFont = UIFont(name: "HelveticaNeue-Light", size: 9)!
        
        self.doubleTapToZoomEnabled = false
    }
    
    var dataSet: LineChartDataSet? {
        get {
            if let data = self.data {
                if let dataSet = data.getDataSetByIndex(0) {
                    return dataSet as? LineChartDataSet
                }
                else {
                    let set = createSet()
                    data.addDataSet(set)
                    return set
                }
            }
            else {
                return nil
            }
        }
    }
    
    private func createSet() -> LineChartDataSet {
        let set = LineChartDataSet(values: nil, label: "Dynamic Data")
        set.axisDependency = .left
        set.setColor(_setColor)
        set.drawCirclesEnabled = false
        set.drawValuesEnabled = false
        return set
    }
    
    func addEntry(value: Double) {
        if let data = self.data, let set = self.dataSet {
            let lastEntry = set.entryForIndex(set.entryCount - 1)
            let x = lastEntry?.x ?? 0
            
            data.addEntry(ChartDataEntry(x: x + 1, y: value), dataSetIndex: 0)
            data.notifyDataChanged()
            
            self.notifyDataSetChanged()
            self.setVisibleXRangeMaximum(150)
            
            self.moveViewToX(Double(x + 1))
            
            if set.entryCount >= maxEntryCount { self.removeFirstEntry() }
        }
    }
    
    private func removeFirstEntry() {
        if let data = self.data, let set = self.dataSet {
            if let entry = set.entryForIndex(0) {
            
                data.removeEntry(entry, dataSetIndex: 0)
                
                data.notifyDataChanged()
                self.notifyDataSetChanged()
                self.setNeedsLayout()
                //self.invalidateIntrinsicContentSize()
            }
        }
    }
}
