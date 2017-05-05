//
//  MusicPlayer.swift
//  KashlemerBLE
//
//  Created by Pavel Aristov on 04.05.17.
//  Copyright © 2017 aristovz. All rights reserved.
//

import Foundation
import AVFoundation
import Alamofire

class MusicPlayer: NSObject {
    
    var player: AVPlayer?
    var tracks = [Audio]()// VKAudios()
    var playerItem: AVPlayerItem?
    //var player: AVQueuePlayer?
    
    var repeatSong = false
    var shuffleSongs = false
    
    var _currentTrackIndex = 0
    var _fromCache = false
    
    init(tracks: [Audio], fromCache: Bool = false) {
        self.tracks = tracks
        _fromCache = fromCache
        super.init()
        
        queueTrack()
    }
    
    private func queueTrack() {
        if (player != nil) { player = nil }
        
        if tracks.count != 0 {
            //Global.setPlayingIndex()
            do {
                try AVAudioSession.sharedInstance().overrideOutputAudioPort(AVAudioSessionPortOverride.speaker)
            } catch let error { print(error.localizedDescription) }
            
            playerItem = AVPlayerItem(url: URL(string: currentTrack.url)!)
            
            player = AVPlayer(playerItem: playerItem!)
        }
    }
    
    func play() {
        if player?.rate == 0 { player?.play() }
    }
    
    func stop() {
        if player?.rate == 1 {
            player?.pause()
            player?.seek(to: kCMTimeZero)
        }
    }
    
    func pause() {
        if player?.rate == 1 {
            player?.pause()
        }
    }
    
    func playPause() {
        if player?.rate == 1 {
            pause()
        }
        else if player?.rate == 0 {
            play()
        }
    }
    
    func nextSong(songFinishedPlaying: Bool = false) {
        var playerWasPlaying = false
        
        if player?.rate == 1 {
            stop()
            playerWasPlaying = true
        }
        
        if repeatSong && songFinishedPlaying {
            player?.play()
            return
        }
        else if shuffleSongs {
            _currentTrackIndex = Int(arc4random_uniform(UInt32(tracks.count)))
        }
        else {
            _currentTrackIndex = nextIndex
        }
        
        queueTrack()
        if playerWasPlaying || songFinishedPlaying {
            player?.play()
        }
    }
    
    func previousSong() {
        var playerWasPlaying = false
        
        if player?.rate == 1 {
            stop()
            playerWasPlaying = true
        }
        
        if shuffleSongs {
            _currentTrackIndex = Int(arc4random_uniform(UInt32(tracks.count)))
        }
        else {
            _currentTrackIndex = previousIndex
        }
        
        queueTrack()
        if playerWasPlaying { player?.play() }
    }
    
    func setVolume(volume: Float) {
        player?.volume = volume
    }
    
    var currentTrack: Audio {
        get { return tracks[_currentTrackIndex] }
    }
    
    var currentTrackIndex: Int {
        get { return _currentTrackIndex }
        set {
            _currentTrackIndex = newValue
            queueTrack()
        }
    }
    
    var nextIndex: Int {
        get {
            var index = _currentTrackIndex + 1
            if index == tracks.count {
                index = 0
            }
            
            return index
        }
    }
    
    var previousIndex: Int {
        get {
            var index = _currentTrackIndex - 1
            if _currentTrackIndex == 0 {
                index = tracks.count - 1
            }
            
            return index
        }
    }
}
