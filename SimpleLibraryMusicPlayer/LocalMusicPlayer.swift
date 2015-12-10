//
//  LocalMusicPlayer.swift
//  SimpleLibraryMusicPlayer
//
//  Created by Ryota Iwai on 2015/09/14.
//  Copyright (c) 2015年 Ryota Iwai. All rights reserved.
//

import UIKit
import MediaPlayer
import AVFoundation

// MARK: - Local Track Source
enum LocalTrackSouceType {
    case Unkown
    case Playlist
    case Album
    case Artist
    case Track
}

class LocalMusicPlayer: NSObject {
    // MARK: - Singleton instance
    static let sharedPlayer = LocalMusicPlayer()
    
    // MARK: Internal enum
    enum LocalPlayerRepeatStatus {
        case None
        case All
        case One
    }
    
    enum LocalPlayerShuffleMode {
        case Off
        case On
    }
    
    // MARK: Internal property
    var isPlaying: Bool = false
    var repeatStatus: LocalPlayerRepeatStatus = .None
    var shuffleMode: LocalPlayerShuffleMode = .Off {
        didSet {
            if self.shuffleMode == .On {
                if oldValue == .Off {
                    self.currentQueueToShuffle(true)
                }
            } else {
                self.currentQueueToShuffle(false)
            }
        }
    }
    
    // MARK: Private property
    private var currentPlayer: AVPlayer?
    private var remoteSeekTimer: NSTimer? = nil
    private var sourceType: LocalTrackSouceType = .Unkown
    private var currentCollection: MPMediaItemCollection?
    private var currentPlayList: MPMediaPlaylist?
    private var currentQueueIndex: Int = NSNotFound
    private var localTracksQueue: [MPMediaItem] = []
    private var watitingForPlay = false
    private var backgroundTaskIdentifier: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    
    // MARK: - Initalize
    override init() {
        super.init()
        
        // Setup for background
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        } catch {
            // Do nothing
        }
        
        // Add Remote Command
        self.addRemoteCommand()
        
        // For NowPlaying Center
        NSNotificationCenter.addObserver(self, selector: "playbackInfoToNowPlayingInfoCenter", name: UIApplicationDidEnterBackgroundNotification, object: nil)
        
        // For Interruption 
        NSNotificationCenter.addObserver(self, selector: "audioSessionInterruption:", name: AVAudioSessionInterruptionNotification, object: nil)

        // For Audio route change
        NSNotificationCenter.addObserver(self, selector: "audioSessionRouteChange:", name: AVAudioSessionRouteChangeNotification, object: nil)
        
        // For background task
        NSNotificationCenter.addObserver(self, selector: "willResignActive:", name: UIApplicationWillResignActiveNotification, object: nil)
        NSNotificationCenter.addObserver(self, selector: "didBecomeActive:", name: UIApplicationDidBecomeActiveNotification, object: nil)
    }
    
    deinit {
        self.removePlayer()
        
        NSNotificationCenter.removeObserver(self, name: UIApplicationDidEnterBackgroundNotification, object: nil)
        NSNotificationCenter.removeObserver(self, name: AVAudioSessionInterruptionNotification, object: nil)
        NSNotificationCenter.removeObserver(self, name: AVAudioSessionRouteChangeNotification, object: nil)
        NSNotificationCenter.removeObserver(self, name: UIApplicationWillResignActiveNotification, object: nil)
        NSNotificationCenter.removeObserver(self, name: UIApplicationDidBecomeActiveNotification, object: nil)
    }
    
    // MARK: - Internal methods
    // MARK: Play
    func play() {
        if self.canPlay() {
            self.isPlaying = true
            
            do {
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                // Do nothing
            }
            
            self.player().play()
            
            NSNotificationCenter.postNotificationEvent(.LocalMusicStarted, object: self)
            
            self.playbackInfoToNowPlayingInfoCenter()
        } else {
            self.watitingForPlay = true
        }
    }
    
    func playWithPlaylist(playlist: MPMediaPlaylist, selectTrackIndex: Int) -> Bool {
        if self.hasPlayableItem(playlist.items) == false {
            return false
        }
        
        if self.playBackStatusIsPlaying() {
            self.pause()
        }
        
        self.sourceType = .Playlist
        self.currentPlayList = playlist
        self.currentCollection = nil
        self.setItemsToPlayer(playlist.items, index: selectTrackIndex)
        
        return true
    }
    
    func playWithCollection(collection: MPMediaItemCollection, selectTrackIndex: Int, type: LocalTrackSouceType) -> Bool {
        if self.hasPlayableItem(collection.items) == false {
            return false
        }
        if self.playBackStatusIsPlaying() {
            self.pause()
        }
        
        self.sourceType = type
        self.currentCollection = collection
        self.currentPlayList = nil
        self.setItemsToPlayer(collection.items, index: selectTrackIndex)
        
        return true
    }
    
    func playWithTrack(meidaItem: MPMediaItem, type: LocalTrackSouceType) -> Bool {
        if meidaItem.assetURL == nil {
            return false
        }
        if self.playBackStatusIsPlaying() {
            self.pause()
        }
        
        self.sourceType = type
        self.currentCollection = MPMediaItemCollection(items: [meidaItem])
        self.currentPlayList = nil
        self.setItemsToPlayer([meidaItem], index: 0)
        
        return false
    }
    
    // MARK: Pause
    func pause() {
        self.isPlaying = false
        
        self.player().pause()
        
        NSNotificationCenter.postNotificationEvent(.LocalMusicPaused, object: self)
        
        self.playbackInfoToNowPlayingInfoCenter()
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
            do {
                try AVAudioSession.sharedInstance().setActive(false)
            } catch {
                // Do nothing
            }
        })
    }
    
    // MARK: Skip
    func skipToNext() {
        if let nextTrack = self.nextTrack() {
            if self.replaceTrack(nextTrack) {
                self.currentQueueIndex = self.nextIndex()
            } else {
                let playableIndex = self.searchPlayableTrackIndex(true)
                if playableIndex == NSNotFound {
                    return
                }
                if self.replaceTrack(self.localTracksQueue[playableIndex]) {
                    self.currentQueueIndex = playableIndex
                }
            }
        }
    }
    
    func skipToPrevisu() {
        if let previousTrack = self.previousTrack() {
            if self.replaceTrack(previousTrack) {
                self.currentQueueIndex = self.previousIndex()
            } else {
                let playableIndex = self.searchPlayableTrackIndex(false)
                if playableIndex == NSNotFound {
                    return
                }
                if self.replaceTrack(self.localTracksQueue[playableIndex]) {
                    self.currentQueueIndex = playableIndex
                }
            }
        }
    }
    
    // MARK: Info
    func playlistName() -> String? {
        return self.currentPlayList?.name
    }
    
    func albumName() -> String? {
        return self.currentTrack()?.albumTitle
    }
    
    func artistName() -> String? {
        return self.currentCollection?.representativeItem!.artist
    }
    
    // MARK: Seek
    func seekToTime(targetTime: NSTimeInterval, completion: (() -> Void)?) {
        if self.currentTime() == targetTime {
            completion?()
            return
        }
        
        guard let currentItem = self.player().currentItem else { return }
        var seekTime = kCMTimeZero
        if targetTime != 0 {
            seekTime = CMTimeMakeWithSeconds(Float64(targetTime), currentItem.asset.duration.timescale)
        }
        currentItem.seekToTime(seekTime, completionHandler: { (finished) -> Void in
            completion?()
            self.updatePlaybackTimeToNowPlayingInfoCenter()
        })
    }
    
    func seekForward(begin begin :Bool) {
        if self.isPlaying {
            if let player = self.currentPlayer {
                player.rate = begin ? 6 : 1
            }
            self.playbackInfoToNowPlayingInfoCenter()
        } else {
            if begin {
                self.startSeekTimer(forward: true)
            } else {
                self.stopSeekTimer()
            }
        }
    }
    
    func seekBackward(begin begin :Bool) {
        if self.isPlaying {
            if let player = self.currentPlayer {
                player.rate = begin ? -6 : 1
            }
            self.playbackInfoToNowPlayingInfoCenter()
        } else if begin {
            if begin {
                self.startSeekTimer(forward: false)
            } else {
                self.stopSeekTimer()
            }
        }
    }

    func startSeekTimer(forward forward : Bool) {
        if self.remoteSeekTimer == nil {
            self.remoteSeekTimer = NSTimer.scheduledTimerWithTimeInterval(0.2,
                target: self,
                selector: "remoteSeek:",
                userInfo: ["Forward": forward],
                repeats: true)
            
            NSNotificationCenter.postNotificationEvent(.LocalMusicSeekByRemoteBegan, object: nil)
        }
    }
    
    func stopSeekTimer() {
        if self.remoteSeekTimer != nil {
            self.remoteSeekTimer?.invalidate()
            self.remoteSeekTimer = nil
            NSNotificationCenter.postNotificationEvent(.LocalMusicSeekByRemoteEnded, object: nil)
        }
    }
    
    func remoteSeek(timer: NSTimer) {
        if let isForward = timer.userInfo?["Forward"] as? Bool {
            var currentTime = self.currentTime()
            if isForward {
                currentTime += 2
                if currentTime >= self.currentTrackPlaybackDuration() {
                    currentTime = self.currentTrackPlaybackDuration()
                }
            } else {
                currentTime -= 2
                if currentTime <= 0 {
                    currentTime = 0
                }
            }
            self.seekToTime(currentTime, completion: nil)
        }
    }
    
    // MARK: Status
    func playBackStatusIsPlaying() -> Bool {
        if self.player().status == .ReadyToPlay && self.isPlaying == true {
            return true
        }
        return false
    }
    
    func nextIndex() -> Int {
        if self.currentQueueIndex == NSNotFound {
            return NSNotFound
        }
        if self.localTracksQueue.count > (self.currentQueueIndex + 1) {
            return self.currentQueueIndex + 1
        } else if self.repeatStatus == .All {
            return 0
        }
        return NSNotFound
    }
    
    func canSkipToNext() -> Bool {
        return self.nextIndex() != NSNotFound
    }
    
    func previousIndex() -> Int {
        if self.currentQueueIndex == NSNotFound {
            return NSNotFound
        }
        if self.currentQueueIndex == 0 && self.repeatStatus == .All {
            return self.localTracksQueue.count - 1
        }
        if self.localTracksQueue.count > (self.currentQueueIndex - 1) && self.currentQueueIndex != 0 {
            return self.currentQueueIndex - 1
        }
        return NSNotFound
    }
    
    func canSkipToPrevious() -> Bool {
        return self.previousIndex() != NSNotFound
    }
    
    func currentTrack() -> MPMediaItem? {
        if self.currentQueueIndex != NSNotFound && self.localTracksQueue.count > self.currentQueueIndex {
            return self.localTracksQueue[self.currentQueueIndex]
        }
        return nil
    }
    
    func nextTrack() -> MPMediaItem? {
        if !self.canSkipToNext() {
            return nil
        }
        return self.localTracksQueue[self.nextIndex()]
    }
    
    func previousTrack() -> MPMediaItem? {
        if !self.canSkipToPrevious() {
            return nil
        }
        return self.localTracksQueue[self.previousIndex()]
    }
    
    func canPlay() -> Bool {
        guard let currentItem = self.player().currentItem else { return false }
        return (self.player().currentItem != nil) &&
            (currentItem.status == .ReadyToPlay) &&
            (self.player().status == .ReadyToPlay)
    }
    
    func currentTime() -> NSTimeInterval {
        return NSTimeInterval(CMTimeGetSeconds(self.player().currentTime()))
    }
    
    func currentTrackPlaybackDuration() -> NSTimeInterval {
        if let currentTrack = self.currentTrack() {
            return currentTrack.playbackDuration
        }
        return 0
    }
    
    func isCurrentCollection(collection: MPMediaItemCollection) -> Bool {
        if self.sourceType == .Artist {
            if let currentArtist = self.items()?.first?.artist,
                let artist = collection.items.first?.artist{
                    if currentArtist == artist {
                        return true
                    }
            }
        } else {
            if let currentCollection = self.collection() {
                if currentCollection == collection {
                    return true
                }
            }
        }
        return false
    }
    
    func isCurrentTrack(track: MPMediaItem) -> Bool {
        if let currentTrack = self.currentTrack() {
            if currentTrack == track {
                return true
            }
        }
        return false
    }
    
    // MARK: - Private methods
    // MARK: Player
    private func createPlayer(item: AVPlayerItem?) {
        if let unwrapedItem = item {
            self.currentPlayer = AVPlayer(playerItem: unwrapedItem)
        } else {
            self.currentPlayer = AVPlayer()
        }
        
        // AVPlayer proerty
        self.player().allowsExternalPlayback = false
        self.player().actionAtItemEnd = .None
        self.player().rate = 0
        
        // Status KVO
        self.player().addObserver(self, forKeyPath: "status", options: .New, context: nil)
    }
    
    private func removePlayer() {
        if self.currentPlayer == nil {
            return
        }
        if self.isPlaying {
            self.currentPlayer?.pause()
        }
        self.currentPlayer?.removeObserver(self, forKeyPath: "status")
        if let currentPlyaerItem = self.currentPlayer?.currentItem {
            currentPlyaerItem.removeObserver(self, forKeyPath: "status")
            NSNotificationCenter.removeObserver(self, name: AVPlayerItemDidPlayToEndTimeNotification, object: currentPlyaerItem)
            self.currentPlayer?.replaceCurrentItemWithPlayerItem(nil)
        }
        self.currentPlayer = nil
    }
    
    private func player() -> AVPlayer {
        if let unwrapedPlayer = self.currentPlayer {
            return unwrapedPlayer
        }
        self.createPlayer(nil)
        return self.currentPlayer!
    }
    
    // MARK: PlayerItem
    private func playerItem(asset: AVURLAsset) -> AVPlayerItem {
        let playerItem = AVPlayerItem(asset: asset)
        playerItem.addObserver(self, forKeyPath: "status", options: /*.Initial |*/ .New, context: nil)
        NSNotificationCenter.addObserver(self, selector: "didPlayToEndTime", name: AVPlayerItemDidPlayToEndTimeNotification, object: playerItem)
        
        return playerItem
    }
    
    private func setItemsToPlayer(items: [MPMediaItem], index: Int) {
        if index >= 0 && items.count <= index {
            // Error
            return
        }
        
        var selectedIndex = index
        self.localTracksQueue = items
        if selectedIndex < 0 {
            if self.shuffleMode == .On {
                currentQueueToShuffle(true)
            }
            selectedIndex = 0
        }
        if self.replaceTrack(self.localTracksQueue[selectedIndex]) {
            self.currentQueueIndex = selectedIndex
        } else {
            let playableIndex = self.searchPlayableTrackIndex(true)
            if playableIndex == NSNotFound {
                return
            }
            if self.replaceTrack(self.localTracksQueue[playableIndex]) {
                self.currentQueueIndex = playableIndex
            }
        }
        
        if index >= 0 && self.shuffleMode == .On {
            currentQueueToShuffle(true)
        }
    }
    
    private func replaceTrack(item: MPMediaItem) -> Bool {
        if let itemURL = item.assetURL {
            let urlAsset = AVURLAsset(URL: itemURL, options: nil)
            urlAsset.loadValuesAsynchronouslyForKeys(["tracks","duration","playable"], completionHandler: { () -> Void in
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.removePlayer()
                    self.createPlayer(self.playerItem(urlAsset))
                    NSNotificationCenter.postNotificationEvent(.LocalMusicTrackDidChange, object: self)
                    if self.isVideoType(item) {
                        NSNotificationCenter.postNotificationEvent(.PlayVideo, object: nil, userInfo: ["player": self.player()])
                    }
                    if self.player().status == .ReadyToPlay {
                        self.watitingForPlay = false
                        self.play()
                    } else {
                        self.watitingForPlay = true
                    }
                })
            })
            return true
        }
        // Can not playback because this track maybe iCloud or DRM.
        return false
    }
    
    private func isVideoType(item: MPMediaItem) -> Bool {
        if item.mediaType.intersect(.AnyVideo).rawValue != 0 {
            return true
        }
        return false
    }
    
    private func searchPlayableTrackIndex(ascending: Bool) -> Int {
        var startIndex = ascending ? self.nextIndex() : self.previousIndex()
        if startIndex == NSNotFound {
            startIndex = 0
        }
        if ascending {
            for var index = startIndex ; index < self.localTracksQueue.count ; index++ {
                if self.localTracksQueue[index].assetURL != nil {
                    return index
                }
            }
            if self.currentQueueIndex != 0 {
                for var index = 0 ; index < self.currentQueueIndex ; index++ {
                    if self.localTracksQueue[index].assetURL != nil {
                        return index
                    }
                }
            }
        } else {
            for var index = startIndex ; index >= 0 ; index-- {
                if self.localTracksQueue[index].assetURL != nil {
                    return index
                }
            }
            if self.currentQueueIndex != (self.localTracksQueue.count - 1) {
                for var index = self.localTracksQueue.count - 1 ; index > self.currentQueueIndex ; index-- {
                    if self.localTracksQueue[index].assetURL != nil {
                        return index
                    }
                }
            }
        }
        
        NSNotificationCenter.postNotificationEvent(.LocalMusicNoPlayableTrack, object: self)
        
        return NSNotFound
    }
    
    // MARK: MediaItems
    private func hasPlayableItem(items: [MPMediaItem]) -> Bool {
        for mediaItem in items {
            if mediaItem.assetURL != nil {
                return true
            }
        }
        
        return false
    }
    
    private func collection() -> MPMediaItemCollection? {
        return (self.currentCollection != nil) ? self.currentCollection : self.currentPlayList
    }
    
    private func items() -> [MPMediaItem]? {
        if let collection = self.collection() {
            return collection.items
        }
        return nil
    }
    
    private func item(index: Int) -> MPMediaItem? {
        if index == NSNotFound {
            return nil
        }
        
        if let items = self.items() {
            if items.count <= index {
                return nil
            }
            
            return items[index]
        }
        return nil
    }
    
    // MARK: Queue shuffle
    private func currentQueueToShuffle(shuffle: Bool) {
        if shuffle {
            if self.localTracksQueue.count > 1 {
                if let currentTrack = self.currentTrack() {
                    self.localTracksQueue.shuffle()
                    for var newCurrentIndex = 0 ; newCurrentIndex < self.localTracksQueue.count ; newCurrentIndex++ {
                        if currentTrack == self.localTracksQueue[newCurrentIndex] {
                            self.currentQueueIndex = newCurrentIndex
                            break
                        }
                    }
                }
            }
        } else {
            if let items = self.collection()?.items {
                if let currentTrack = self.currentTrack() {
                    for var newCurrentIndex = 0 ; newCurrentIndex < items.count ; newCurrentIndex++ {
                        if currentTrack == items[newCurrentIndex] {
                            self.currentQueueIndex = newCurrentIndex
                            break
                        }
                    }
                }
                self.localTracksQueue = items
            } else {
                self.localTracksQueue = []
            }
        }
    }
    
    // MARK: - Notification Handler
    func didPlayToEndTime() {
        if let player = self.currentPlayer {
            if player.rate != 1 && self.isPlaying {
                self.pause()
                return
            }
        }
        if self.canSkipToNext() {
            // Play next track
            self.skipToNext()
        } else {
            // Stop
            self.seekToTime(0, completion: { () -> Void in
                self.pause()
            })
        }
    }
    
    // MARK: - KVO Handler
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "status" {
            if let playerItem = self.player().currentItem {
                if self.player().status == .ReadyToPlay && playerItem.status == .ReadyToPlay {
                    if self.watitingForPlay {
                        self.play()
                        self.watitingForPlay = false
                    }
                }
            }
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
    // MARK: - For MPNowPlayingInfoCenter
    func playbackInfoToNowPlayingInfoCenter() {
        guard let mediaItem = self.currentTrack() else { return }
        var playingInfo: [String: AnyObject] = [
            MPMediaItemPropertyTitle: mediaItem.title ?? "",
            MPMediaItemPropertyArtist: mediaItem.artist ?? "",
            MPMediaItemPropertyAlbumTitle: mediaItem.albumTitle ?? "",
            MPMediaItemPropertyPlaybackDuration: NSNumber(double: self.currentTrackPlaybackDuration()),
            MPNowPlayingInfoPropertyElapsedPlaybackTime: NSNumber(double: self.currentTime()),
            MPNowPlayingInfoPropertyPlaybackRate: NSNumber(float: self.player().rate)]
        if mediaItem.artwork != nil {
            playingInfo[MPMediaItemPropertyArtwork] = mediaItem.artwork
        }
        MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = playingInfo
    }
    
    private func updatePlaybackTimeToNowPlayingInfoCenter() {
        if self.currentTrack() != nil {
            if var playingInfo = MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo {
                playingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = NSNumber(double: self.currentTime())
                MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = playingInfo
            }
        }
    }

    // MARK: - For AVAudioSessionInterruptionNotification
    func audioSessionInterruption(notification: NSNotification) {
        guard let interruptionType = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? NSNumber else { return }
        guard let type = AVAudioSessionInterruptionType(rawValue: interruptionType.unsignedLongValue) else { return }
        switch type {
        case .Began:
            if self.isPlaying {
                self.pause()
            }
            
        case .Ended:
            guard let interruptionOption = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? NSNumber else { return }
            if interruptionOption.unsignedLongValue == AVAudioSessionInterruptionOptions.ShouldResume.rawValue {
                self.play()
            }            
        }
    }

    // MARK: - For AVAudioSessionRouteChangeNotification
    func audioSessionRouteChange(notification: NSNotification) {
        if let changeReason = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? NSNumber {
            if let reason = AVAudioSessionRouteChangeReason(rawValue: changeReason.unsignedLongValue) {
                switch reason {
                case .OldDeviceUnavailable:
                    if self.isPlaying {
                        self.pause()
                    }

                default:
                    break
                }
            }
        }
    }
    
    // MARK: - RemoteCommand
    private func addRemoteCommand() {
        MPRemoteCommandCenter.sharedCommandCenter().playCommand.addTarget(self, action: "remoteCommandPlay")
        MPRemoteCommandCenter.sharedCommandCenter().pauseCommand.addTarget(self, action: "remoteCommandPause")
        MPRemoteCommandCenter.sharedCommandCenter().togglePlayPauseCommand.addTarget(self, action: "remoteCommandPlayOrPause")
        MPRemoteCommandCenter.sharedCommandCenter().stopCommand.addTarget(self, action: "remoteCommandStop")
        MPRemoteCommandCenter.sharedCommandCenter().nextTrackCommand.addTarget(self, action: "remoteCommandNext")
        MPRemoteCommandCenter.sharedCommandCenter().previousTrackCommand.addTarget(self, action: "remoteCommandPrevious")
        MPRemoteCommandCenter.sharedCommandCenter().seekForwardCommand.addTarget(self, action: "remoteCommandseekForward:")
        MPRemoteCommandCenter.sharedCommandCenter().seekBackwardCommand.addTarget(self, action: "remoteCommandseekBackward:")
    }
    
    // MARK: - Remote Command Handler
    func remoteCommandPlay() {
        self.play()
    }
    
    func remoteCommandPause() {
        self.pause()
    }
    
    func remoteCommandPlayOrPause() {
        if self.isPlaying {
            self.pause()
        } else {
            self.play()
        }
    }
    
    func remoteCommandStop() {
        self.pause()
    }
    
    func remoteCommandNext() {
        self.skipToNext()
    }
    
    func remoteCommandPrevious() {
        self.skipToPrevisu()
    }

    func remoteCommandseekForward(event: MPSeekCommandEvent) {
        self.seekForward(begin: event.type == .BeginSeeking)
    }
    
    func remoteCommandseekBackward(event: MPSeekCommandEvent) {
        self.seekBackward(begin: event.type == .BeginSeeking)
    }
    
    // MARK: - For Background task
    func willResignActive(notification: NSNotification) {
        self.backgroundTaskIdentifier = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler({ () -> Void in
            UIApplication.sharedApplication().endBackgroundTask(self.backgroundTaskIdentifier)
            self.backgroundTaskIdentifier = UIBackgroundTaskInvalid
        })
    }

    func didBecomeActive(notification: NSNotification) {
        UIApplication.sharedApplication().endBackgroundTask(self.backgroundTaskIdentifier)
    }
}
