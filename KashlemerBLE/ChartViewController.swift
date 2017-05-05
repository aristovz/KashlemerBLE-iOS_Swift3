//
//  ChartViewController.swift
//  KashlemerBLE
//
//  Created by Pavel Aristov on 05.05.17.
//  Copyright © 2017 aristovz. All rights reserved.
//

import Charts
import UIKit

class ChartViewController: UIViewController, ChartViewDelegate {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var chartView: LineChartView!
    
    var currentChart: DataChartView?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let chart = currentChart {
            self.nameLabel.text = chart.titleLabel.text
            chartView.data = chart.chartView.data
            chartView.delegate = self
        }
    }
    
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        self.nameLabel.text = "\(currentChart!.titleLabel!.text!) (x: \(highlight.x), y: \(highlight.y))"
    }
    
    @IBAction func closeButtonAction(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func saveButtonAction(_ sender: UIButton) {
        UIGraphicsBeginImageContextWithOptions(chartView!.bounds.size, false, UIScreen.main.scale)
        chartView!.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        UIImageWriteToSavedPhotosAlbum(image!, nil, nil, nil)
        
        let str = self.nameLabel.text
        self.nameLabel.text = "Сохранено!"
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            self.nameLabel.text = str
        }
    }
}
