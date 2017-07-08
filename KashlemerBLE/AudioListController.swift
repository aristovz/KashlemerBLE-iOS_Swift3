//
//  AudioListController.swift
//  KashlemerBLE
//
//  Created by Pavel Aristov on 04.05.17.
//  Copyright © 2017 aristovz. All rights reserved.
//

import UIKit
import AVFoundation

class AudioListController: UITableViewController {

    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!

    var player: MusicPlayer!
    
    var audioList = [Audio]()
    
    var playingAudioIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        refresh()
    }
    
    func refresh() {
        self.audioList.removeAll()
        self.audioList.append(contentsOf: realm.objects(Audio.self))
        self.player = MusicPlayer(tracks: self.audioList)
        self.tableView.reloadData()
        
        loadingIndicator.startAnimating()
        API.getAllAudio(needData: true) { (audioList, error) in
            guard error == nil else {
                print(error!)
                return
            }
            
            self.audioList.append(contentsOf: audioList!)
            self.audioList = self.audioList.sorted(by: { $0.date > $1.date })
            
            self.player = MusicPlayer(tracks: self.audioList)
            self.tableView.reloadData()
            self.loadingIndicator.stopAnimating()
        }
    }
    
    @IBAction func closeButtonAction(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func playButtonAction(_ sender: UIButton) {
        sender.setImage(#imageLiteral(resourceName: "pause"), for: .normal)
        
        player.currentTrackIndex = sender.tag
        player.setVolume(volume: 1)
        
        NotificationCenter.default.addObserver(self, selector: #selector(finishedPlaying(_:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player.player?.currentItem)
        
        player.play()
    }
    
    @IBAction func sendButtonAction(_ sender: UIButton) {
        var dataArr = [String: [Double]]()
        let name = ["audioAmpl", "pull", "acy", "acz"]
        
        for n in name {
            dataArr[n] = [Double]()
        }
        
        let currentAudio = audioList[sender.tag]
        for data in currentAudio.data {
            dataArr["audioAmpl"]?.append(data.audioAmpl)
            dataArr["pull"]?.append(data.pull)
            dataArr["acy"]?.append(data.acy)
            dataArr["acz"]?.append(data.acz)
        }
        
        let url = URL(string: currentAudio.url)!
        
        sender.setTitle("Отправка!", for: .normal)
        API.uploadAudioWithData(from: url, at: currentAudio.date, with: dataArr, requestEnd: { (success) in
            if success {
                sender.setTitle("Успешно", for: .normal)
                
                let fileManager = FileManager.default
                if fileManager.fileExists(atPath: url.path) {
                    do {
                        try fileManager.removeItem(atPath: url.path)
                    }
                    catch { }
                }
                
                try! realm.write {
                    realm.delete(currentAudio)
                }
                
                self.refresh()
            }
            else {
                print("error")
                sender.setTitle("Ошибка!", for: .normal)

                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3), execute: {
                    sender.setTitle("Повторить", for: .normal)
                })
//
//                for k in 0..<self.data.count {
//                    self.data[k].removeAll()
//                }
            }
        })
    }
    
    func finishedPlaying(_ myNotification:NSNotification) {
        let cell = self.tableView.cellForRow(at: IndexPath(row: player.currentTrackIndex, section: 0)) as! AudioCell
        cell.playButtonOutlet.setImage(#imageLiteral(resourceName: "play-button"), for: .normal)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return audioList.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "audioCell", for: indexPath) as! AudioCell
        
        let currentAudio = audioList[indexPath.row]
        
        cell.nameLabel.text = currentAudio.name
        cell.playButtonOutlet.tag = indexPath.row
        cell.sendButton.tag = indexPath.row
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy HH:mm"
        
        cell.dateLabel.text = dateFormatter.string(from: currentAudio.date)
        
        cell.sendButton.isHidden = !currentAudio.isCached
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .destructive, title: "Удалить") { (acition, indexPath) in
            let currentAudio = self.audioList[indexPath.row]
            
            if currentAudio.isCached {
                try! realm.write {
                    realm.delete(currentAudio)
                    self.audioList.remove(at: indexPath.row)
                    self.tableView.reloadData()
                }
            }
            else {
                API.delete(id: self.audioList[indexPath.row].id, requestEnd: { (result, error) in
                    guard error == nil else {
                        print(error!)
                        return
                    }
                    
                    if result! {
                        self.audioList.remove(at: indexPath.row)
                        self.tableView.reloadData()
                    }
                })
            }
        }
        
        return [delete]
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toAudioDetail" {
            if let index = self.tableView.indexPathForSelectedRow?.row {
                let vc = segue.destination as! AudioDetailController
                vc.currentAudio = audioList[index]
            }
        }
    }
}

class AudioCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    @IBOutlet weak var playButtonOutlet: UIButton!
    
    @IBOutlet weak var sendButton: UIButton!
    
    //var currentAudio: Audio?
}
