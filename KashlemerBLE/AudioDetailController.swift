//
//  AudioDetailController.swift
//  KashlemerBLE
//
//  Created by Pavel Aristov on 05.05.17.
//  Copyright © 2017 aristovz. All rights reserved.
//

import UIKit

class AudioDetailController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var playButtonOutlet: UIButton!
    
    var player: MusicPlayer!
    
    var audioAmplChartView: DataChartView!
    var pullingChartView: DataChartView!
    var xValueChartView: DataChartView!
    var yValueChartView: DataChartView!
    var zValueChartView: DataChartView!
    
    var tmpChartView: DataChartView!
    
    var GyXValueChartView: DataChartView!
    var GyYValueChartView: DataChartView!
    var GyZValueChartView: DataChartView!
    
    let names = ["Звук амплит.", "Натяжение", "AcX", "AcY", "AcZ", "Tmp", "GyX", "GyY", "GyZ"]
    
    var charts = [DataChartView?]()
    
    var currentAudio: Audio?
    
    var infoButton: UIButton {
        let button = UIButton(frame: CGRect(x: UIScreen.main.bounds.width - 30, y: 0, width: 30, height: 30))
        button.setTitle("<i>", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.addTarget(self, action: #selector(infoButtontapped(sender:)), for: .touchUpInside)
        return button
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        setupScrollView()
    }

    func setupScrollView() {
        if let audio = currentAudio {
            self.player = MusicPlayer(tracks: [audio])
            nameLabel.text = audio.name
            
            let size = CGSize(width: UIScreen.main.bounds.width, height: 130)
            var location = CGPoint(x: 0, y: 0)
            
            let space: CGFloat = 5
            
            charts = [audioAmplChartView, pullingChartView, xValueChartView, yValueChartView, zValueChartView, tmpChartView, GyXValueChartView, GyYValueChartView, GyZValueChartView]
            for k in 0..<charts.count {
                charts[k] = DataChartView(frame: CGRect(origin: location, size: size))
                charts[k]?.titleLabel.text = names[k] + ":"
                let infButton = infoButton
                infButton.tag = k
                
                charts[k]?.addSubview(infButton)
        
                self.scrollView.addSubview(charts[k]!)
                location.y += size.height + space
            }
            
            for value in audio.data {
                for k in 0..<charts.count {
                    switch k {
                    case 0: charts[k]?.addEntry(value: value.audioAmpl)
                    case 0: charts[k]?.addEntry(value: value.pull)
                    case 1: charts[k]?.addEntry(value: value.acx)
                    case 2: charts[k]?.addEntry(value: value.acy)
                    case 3: charts[k]?.addEntry(value: value.acz)
                    case 4: charts[k]?.addEntry(value: value.tmp)
                    case 5: charts[k]?.addEntry(value: value.gyx)
                    case 6: charts[k]?.addEntry(value: value.gyy)
                    case 7: charts[k]?.addEntry(value: value.gyz)
                    default: break;
                    }
                }
            }
            
            self.scrollView.contentSize = CGSize(width: self.view.frame.size.width, height: location.y)
        }
    }
    
    func infoButtontapped(sender: UIButton) {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "chartViewController") as! ChartViewController
        
        vc.currentChart = charts[sender.tag]
        
        self.present(vc, animated: true, completion: nil)
    }
    
    @IBAction func closeButtonAction(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func playButtonAction(_ sender: UIButton) {
        sender.setImage(#imageLiteral(resourceName: "pause"), for: .normal)
        
        player.setVolume(volume: 1)
        
        NotificationCenter.default.addObserver(self, selector: #selector(finishedPlaying(_:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player.player?.currentItem)
        
        player.play()
    }
    
    func finishedPlaying(_ myNotification:NSNotification) {
        playButtonOutlet.setImage(#imageLiteral(resourceName: "play-button"), for: .normal)
    }
}
