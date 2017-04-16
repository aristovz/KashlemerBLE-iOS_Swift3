//
//  SerialViewController.swift
//  KashlemerBLE
//
//  Created by Pavel Aristov on 16.04.17.
//  Copyright © 2017 aristovz. All rights reserved.
//

import UIKit
import CoreBluetooth
import Charts

final class SerialViewController: UIViewController, UITextFieldDelegate {
    
    //MARK: IBOutlets
    @IBOutlet weak var pullingChart: MonitoringChartView!
    @IBOutlet weak var xValueChart: MonitoringChartView!
    @IBOutlet weak var yValueChart: MonitoringChartView!

    @IBOutlet weak var statusIndicator: UIActivityIndicatorView!
    @IBOutlet weak var statusLabel: UILabel!
    
    @IBOutlet weak var pullingLabel: UILabel!
    @IBOutlet weak var xLabel: UILabel!
    @IBOutlet weak var yLabel: UILabel!
    
    @IBOutlet weak var rightBarButtonOutlet: UIBarButtonItem!
    
    //MARK: Variables
    
    fileprivate var tempString = ""
    
    //MARK: Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // init serial
        serial = BluetoothSerial(delegate: self)
        
        //init charts
        pullingChart.initChartView()
        xValueChart.initChartView(.purple)
        yValueChart.initChartView(.black)
    }
    
    //MARK: Actions
    
    @IBAction func rightBarButtonAction(_ sender: UIBarButtonItem) {
        if serial.isReady {
            serial.disconnect()
            statusLabel.text = "Сканирование приостановлено"
            statusLabel.textColor = .yellow
        }
        else {
            serial.startScan()
        }
    }
}

//MARK: BluetoothSerialDelegate

extension SerialViewController: BluetoothSerialDelegate {
    
    func serialDidReceiveString(_ message: String) {
        tempString.append(message)
        var dataArray = tempString.components(separatedBy: "\r\n")
        tempString = dataArray.last ?? ""
        dataArray.removeLast()
        
        for row in dataArray {
            let values = row.components(separatedBy: "|")
            
            if values.count == 3 {
                pullingLabel.text = values[0]
                if let value = Double(values[0]) { pullingChart.addEntry(value: value) }
                
                xLabel.text = values[1]
                if let value = Double(values[1]) { xValueChart.addEntry(value: value) }
                
                yLabel.text = values[2]
                if let value = Double(values[2]) { yValueChart.addEntry(value: value) }
            }
        }
    }
    
    func serialDidDisconnect(_ peripheral: CBPeripheral, error: NSError?) {
//        let hud = MBProgressHUD.showAdded(to: view, animated: true)
//        hud?.mode = MBProgressHUDMode.text
//        hud?.labelText = "Disconnected"
//        hud?.hide(true, afterDelay: 1.0)
    }
    
    func serialDidConnect(_ peripheral: CBPeripheral) {
        statusLabel.text = peripheral.name
        statusLabel.textColor = .green
        statusIndicator.stopAnimating()
    }
    
    func serialDidChangeState() {
        if serial.centralManager.state != .poweredOn {
            self.statusLabel.text = "Bluetooth not turned on"
            self.statusLabel.textColor = .red
            self.statusIndicator.stopAnimating()
            return
        }
        
        // start scanning and schedule the time out
        serial.startScan()
        statusIndicator.startAnimating()
    }
    
    func serialDidDiscoverPeripheral(_ peripheral: CBPeripheral, RSSI: NSNumber?) {
        // check whether it is a duplicate
        if peripheral.identifier.uuidString != deviceIdentifier { return }
        
        serial.stopScan()
        serial.connectToPeripheral(peripheral)
    }
}
