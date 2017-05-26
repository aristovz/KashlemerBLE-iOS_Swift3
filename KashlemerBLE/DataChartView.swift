//
//  DataChartView.swift
//  KashlemerBLE
//
//  Created by Pavel Aristov on 03.05.17.
//  Copyright © 2017 aristovz. All rights reserved.
//

import UIKit
import Darwin

class DataChartView: UIView {

    @IBOutlet weak var chartView: MonitoringChartView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dataLabel: UILabel!
    @IBOutlet weak var sliderOutlet: UISlider!
    
    var limit = 20
    var buffer = [Double]()
    var avrg = 0.0
//    var porog: Int {
//        get {
//            return Int(sliderOutlet.value)
//        }
//    }
    var countAvrg: UInt = 0
    
    // MARK: - Initializers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    // MARK: - Private Helper Methods
    
    // Performs the initial setup.
    private func setupView() {
        let view = viewFromNibForClass()
        view.frame = bounds
        
        // Auto-layout stuff.
        view.autoresizingMask = [
            .flexibleWidth,
            .flexibleHeight
        ]
        
        chartView.initChartView()
        
        // Show the view.
        addSubview(view)
    }
    
    // Loads a XIB file into a view and returns this view.
    private func viewFromNibForClass() -> UIView {
        
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: String(describing: type(of: self)), bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil).first as! UIView
        
        return view
    }

    func addEntry(value: Double) {
        dataLabel.text = "\(value)"
        //print("\(tag) - \(avrg)")
        chartView.addEntry(value: value)
        
        buffer.append(value)
        
        if buffer.count > limit - 1 {
            print(Date().timeIntervalSince(timeStart))
            dataLabel.textColor = checkCough() ? .red : .green
            buffer.removeAll()
            timeStart = Date()
        }
    }
    var timeStart = Date()
    private func checkCough() -> Bool {
        var sum = 0.0
        buffer.forEach({ sum += $0})//pow(, 2.0) })
        sum /= Double(limit)

//        avrg = (avrg * Double(countAvrg) + sum) / Double(countAvrg + 1)
//        countAvrg += 1
        
        print("\(tag) - \(buffer.max()!) - \(sum) = \(buffer.max()! - sum)")
        
        //dataLabel.text = "\(sum)"
        //chartView.addEntry(value: sum)
        
        return buffer.max()! - sum > Double(sliderOutlet.value)
    }
    
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        titleLabel.text = "\(Int(sender.value))"
        buffer.removeAll()
    }
    
}
