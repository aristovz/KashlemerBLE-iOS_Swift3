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
import AVFoundation

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
    
    @IBOutlet weak var networkStatusLabel: UILabel!
    
    @IBOutlet weak var rightBarButtonOutlet: UIBarButtonItem!
    
    //MARK: Variables
    
    fileprivate var tempString = ""
    
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    
    var detected = false
    
    var prevAudioURL: URL {
        get {
            return getDocumentsDirectory().appendingPathComponent("prev.m4a")
        }
    }
    
    var currentAudioURL: URL {
        get {
            return getDocumentsDirectory().appendingPathComponent("current.m4a")
        }
    }
    
    // Duration of audio tracks in seconds
    let timeLapse = 3
    
    //MARK: Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //init recorder
        recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { [unowned self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        self.startRecording()
                    } else {
                        // failed to record!
                    }
                }
            }
        } catch {
            // failed to record!
        }
        
        // init serial
        serial = BluetoothSerial(delegate: self)
        
        //init charts
        pullingChart.initChartView()
        xValueChart.initChartView(.purple)
        yValueChart.initChartView(.black)
    }
    
    func startRecording() {
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: currentAudioURL, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.record()
        } catch {
            finishRecording(success: false)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(timeLapse)) {
            self.finishRecording(success: true)
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    //MARK: Actions
    
    @IBAction func rightBarButtonAction(_ sender: UIBarButtonItem) {
        if serial.isReady {
            serial.disconnect()
        }
        else {
            serial.startScan()
        }
    }
}

//MARK: AVAudioRecorderDelegate
extension SerialViewController: AVAudioRecorderDelegate {
    
    func merge(audioFiles: [URL], completion: @escaping (URL?) -> ()) {
        guard audioFiles.count > 0 else {
            completion(nil)
            return
        }
        
        if audioFiles.count == 1 {
            completion(audioFiles.first)
            return
        }
        
        // Concatenate audio files into one file
        var nextClipStartTime = kCMTimeZero
        let composition = AVMutableComposition()
        let track = composition.addMutableTrack(withMediaType: AVMediaTypeAudio, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        // Add each track
        for recording in audioFiles {
            let asset = AVURLAsset(url: recording)
            if let assetTrack = asset.tracks(withMediaType: AVMediaTypeAudio).first {
                let timeRange = CMTimeRange(start: kCMTimeZero, duration: asset.duration)
                do {
                    try track.insertTimeRange(timeRange, of: assetTrack, at: nextClipStartTime)
                    nextClipStartTime = CMTimeAdd(nextClipStartTime, timeRange.duration)
                } catch {
                    print("Error concatenating file - \(error)")
                    completion(nil)
                    return
                }
            }
        }
        
        // Export the new file
        if let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A) {
            
            // Configure export session output
            let fileURL = getDocumentsDirectory().appendingPathComponent("\(Int(Date().timeIntervalSince1970)).m4a")
            exportSession.outputURL = fileURL
            exportSession.outputFileType = AVFileTypeAppleM4A
            
            // Perform the export
            exportSession.exportAsynchronously() { handler -> Void in
                if exportSession.status == .completed {
                    print("Export complete")
                    
                    DispatchQueue.main.async {
                        completion(fileURL)
                    }
                    
                    return
                } else if exportSession.status == .failed {
                    print("Export failed - \(exportSession.error!)")
                }
                
                completion(nil)
                return
            }
        }
    }
    
    func replaceAudio() {
        let fileManager = FileManager.default
        
        if !fileManager.fileExists(atPath: prevAudioURL.path) {
            do {
                try fileManager.moveItem(at: currentAudioURL, to: prevAudioURL)
            }
            catch { }
        }
        else {
            do {
                try fileManager.removeItem(atPath: prevAudioURL.path)
                try fileManager.moveItem(at: currentAudioURL, to: prevAudioURL)
            }
            catch { }
        }
    }
    
    func finishRecording(success: Bool) {
        audioRecorder.stop()
        audioRecorder = nil
        
        if success {
            if detected {
        
                merge(audioFiles: [prevAudioURL, currentAudioURL], completion: { (fileURL) in
                    if let url = fileURL {
                        print(url)
                        self.detected = false
                        
                        API.uploadAudio(from: url, requestEnd: { (success) in
                            self.networkStatusLabel.text = "Загрузка на сервер завершена!"
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3), execute: {
                                self.networkStatusLabel.text = "Сканирование"
                            })
                            
                            let fileManager = FileManager.default
                            if fileManager.fileExists(atPath: url.path) {
                                do {
                                    try fileManager.removeItem(atPath: url.path)
                                }
                                catch { }
                            }
                        })
                    }
                })
            }
            
            replaceAudio()
            startRecording()
        }
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(success: false)
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
            let values = row.components(separatedBy: " ")
            
            if values.count == 8 {
                pullingLabel.text = values[0]
                if let value = Double(values[0]) {
                    if value > 1000 && detected == false {
                        detected = true
                        self.networkStatusLabel.text = "Обнаружен кашель! Отправка..."
                    }
                    
                    pullingChart.addEntry(value: value)
                }
                
                xLabel.text = values[1]
                if let value = Double(values[1]) { xValueChart.addEntry(value: value) }
                
                yLabel.text = values[2]
                if let value = Double(values[2]) { yValueChart.addEntry(value: value) }
            }
        }
    }
    
    func serialDidDisconnect(_ peripheral: CBPeripheral, error: NSError?) {
        self.statusLabel.text = "Соединение прервано!"
        self.statusLabel.textColor = .red
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
        statusLabel.text = "Поиск устройства"
        statusIndicator.startAnimating()
    }
    
    func serialDidDiscoverPeripheral(_ peripheral: CBPeripheral, RSSI: NSNumber?) {
        // check whether it is a duplicate
        if peripheral.identifier.uuidString != deviceIdentifier { return }
        
        serial.stopScan()
        serial.connectToPeripheral(peripheral)
    }
}
