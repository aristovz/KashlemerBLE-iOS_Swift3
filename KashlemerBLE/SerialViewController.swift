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
import Darwin
import AudioKit
import UserNotifications

class SerialViewController: UIViewController, UITextFieldDelegate, DataChartDelegate {
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var statusIndicator: UIActivityIndicatorView!
    @IBOutlet weak var statusLabel: UILabel!
    
    @IBOutlet weak var networkStatusLabel: UILabel!
    
    @IBOutlet weak var rightBarButtonOutlet: UIBarButtonItem!
    
    @IBOutlet weak var recordButtonOutlet: UIButton!
    
    //MARK: Variables
    var micTracker = AKMicrophoneTracker()
    var micChartView: DataChartView!
    
    var pullingChartView: DataChartView!
    var xValueChartView: DataChartView!
    var yValueChartView: DataChartView!
    var zValueChartView: DataChartView!
    
    var tmpChartView: DataChartView!
    
    var GyXValueChartView: DataChartView!
    var GyYValueChartView: DataChartView!
    var GyZValueChartView: DataChartView!
    
    let names = ["Ampl", "Натяжение", "AcY", "AcZ"] //"AcX", "Tmp", "GyX", "GyY", "GyZ"
    
    var charts = [DataChartView?]()
    var data = [[Double](), [Double](), [Double](), [Double]()]//, [Double](), [Double](), [Double](), [Double](), [Double]()]
    var oldData = [[Double](), [Double](), [Double](), [Double]()]
    var timer: Timer?
    var seconds = 0
    
    fileprivate var tempString = ""
    
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    
    var isRecordStarted = false

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
        
        micTracker.start()
        //init recorder
        recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { allowed in
                DispatchQueue.main.async {
                    if allowed {
                        self.startRecording()
                    } else {
                        // failed to record!
                    }
                }
            }
        } catch { }
        
        // init serial
        serial = BluetoothSerial(delegate: self)
        
        //init charts
        setupScrollView()
    }
    
    func setupScrollView() {
        let size = CGSize(width: UIScreen.main.bounds.width, height: 150)
        var location = CGPoint(x: 0, y: 0)
        
        let space: CGFloat = 5
        
        charts = [micChartView, pullingChartView, xValueChartView, yValueChartView]//, zValueChartView, tmpChartView, GyXValueChartView, GyYValueChartView, GyZValueChartView]
        for k in 0..<charts.count {
            charts[k] = DataChartView(frame: CGRect(origin: location, size: size))
            charts[k]?.tag = k
            charts[k]?.titleLabel.text = names[k] + ":"
            charts[k]?.delegate = self
            
            if k == 0 {
                charts[k]?.sliderOutlet.minimumValue = 0
                charts[k]?.sliderOutlet.maximumValue = 1
                
                charts[k]?.sliderOutlet.value = 0.3
                charts[k]?.porogLabel.text = "\(0.3)"
            }
            else if k == 1 {
                charts[k]?.sliderOutlet.minimumValue = 10
                charts[k]?.sliderOutlet.maximumValue = 2000
                
                charts[k]?.sliderOutlet.value = 65
                charts[k]?.porogLabel.text = "\(65)"
            }
            else if k == 2 {
                charts[k]?.sliderOutlet.value = 365
                charts[k]?.porogLabel.text = "\(365)"
            }
            else if k == 3 {
                charts[k]?.sliderOutlet.value = 1630
                charts[k]?.porogLabel.text = "\(1630)"
            }
            
//            self.data[k] = [Double]
            
            self.scrollView.addSubview(charts[k]!)
            location.y += size.height + space
        }
        
        self.scrollView.contentSize = CGSize(width: self.view.frame.size.width, height: location.y)
    }
    
    var masBool = [false, false, false, false]
    func didChangeCough(index: Int, value: Bool) {
        masBool[index] = value
        
        if (masBool[0] && masBool[1] && (masBool[2] || masBool[3])) {
            detected = true
            self.networkStatusLabel.text = "Обнаружен кашель! Отправка..."
            sendNotification(title: "\(Date())", text: "Обнаружен кашель!")
        }
    }
    
    func startRecording() {
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatAppleLossless),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: currentAudioURL, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.record()
        } catch {
            finishRecording(success: false)
        }
        oldData = data
        
        for ind in 0..<data.count {
            self.data[ind].removeAll()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(timeLapse)) {
            self.finishRecording(success: true)
//            print("3 sec")
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    func start() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.runTimedCode), userInfo: nil, repeats: true)
        
        startRecording()
    }
    
    func stop() {
        guard timer != nil else { return }
        timer?.invalidate()
        timer = nil
        
        finishRecording(success: true)
    }
    
    func runTimedCode() {
        seconds += 1
        let minutes = Int(seconds / 60)
        let sec = seconds % 60
        
        networkStatusLabel.text = "\(minutes < 10 ? "0" : "")\(minutes):\(sec < 10 ? "0" : "")\(sec) Идет запись..."
    }
    
    //MARK: Actions
    
    @IBAction func rightBarButtonAction(_ sender: UIBarButtonItem) {
        if serial.isReady {
            serial.disconnect()
        }
        else {
            serial.startScan()
        }
        
//        detected = true
//        self.networkStatusLabel.text = "Обнаружен кашель! Отправка..."
    }
    
    @IBAction func recordButtonAction(_ sender: UIButton) {
        if !isRecordStarted {
            isRecordStarted = true
            recordButtonOutlet.setImage(#imageLiteral(resourceName: "stop"), for: .normal)
            start()
            networkStatusLabel.text = "00:00 Идет запись..."

        }
        else {
            isRecordStarted = false
            recordButtonOutlet.setImage(#imageLiteral(resourceName: "record"), for: .normal)
            stop()
            seconds = 0
        }
    }
    
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        networkStatusLabel.text = "\(Int(sender.value))"
        charts.forEach({ $0?.limit = Int(sender.value) })
    }
    
    func sendNotification(title: String, text: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = text
        content.sound = UNNotificationSound.default()
        let request = UNNotificationRequest(identifier: "\(Date())", content: content, trigger: nil)
        //UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().add(request) {(error) in
            if let error = error {
                print("Uh oh! We had an error: \(error)")
            }
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
                        
                        var dataArr = [String: [Double]]()
                        let nam = ["audioAmpl", "pull", "acy", "acz"]
        
                        var currData = self.oldData
                        
                        for ind in 0..<self.data.count {
                            currData[ind] += self.data[ind]
                        }
                        
                        for k in 0..<currData.count {
                            dataArr[nam[k]] = currData[k]
                        }
        
                        API.uploadAudioWithData(from: url, with: dataArr, requestEnd: { (success) in
                            self.networkStatusLabel.text = "Загрузка на сервер завершена!"
        
                            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3), execute: {
                                self.networkStatusLabel.text = "Сканирование"
                            })
                            
                            for k in 0..<self.data.count {
                                self.data[k].removeAll()
                            }
//
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
            var values = row.components(separatedBy: " ")
            if values.count == 8 {//charts.count {
                values.insert("\(micTracker.amplitude)", at: 0)
                for k in 0..<charts.count {
                    if let value = Double(values[k]), charts[k] != nil {
//                        if k != 0 {
//                            value /= 1700.0
//                        }
                        
                        self.charts[k]!.addEntry(value: value)
                        
                        //if timer != nil {
                            self.data[k].append(value)
                        //}
                    }	
                }
            }
        }
    }
    
    func serialDidDisconnect(_ peripheral: CBPeripheral, error: NSError?) {
        self.statusLabel.text = "Соединение прервано!"
        self.statusLabel.textColor = .red
        sendNotification(title: "\(Date())", text: "Соединение прервано! Перезапустите программу")
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
