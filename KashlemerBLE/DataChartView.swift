//
//  DataChartView.swift
//  KashlemerBLE
//
//  Created by Pavel Aristov on 03.05.17.
//  Copyright © 2017 aristovz. All rights reserved.
//

import UIKit

class DataChartView: UIView {

    @IBOutlet weak var chartView: MonitoringChartView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dataLabel: UILabel!
    
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
        chartView.addEntry(value: value)
    }
}
