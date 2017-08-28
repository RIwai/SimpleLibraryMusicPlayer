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
                    self.currentQueueToShuffle(shuffle: true)
                }
            } else {
                self.currentQueueToShuffle(shuffle: false)
            }
        }
    }
    
    // MARK: Private property
    private var currentPlayer: AVPlayer?
    private var remoteSeekTimer: Timer? = nil
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
            if #available(iOS 11.0, *) {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback,
                                                                mode: AVAudioSessionModeDefault,
                                                                routeSharingPolicy: .longForm)
            }  else {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            }
        } catch let error {
            print("setCategory error = \(error)")
        }
        
        // Add Remote Command
        self.addRemoteCommand()
        
        // For NowPlaying Center
        NotificationCenter.addObserver(observer: self, selector: #selector(LocalMusicPlayer.playbackInfoToNowPlayingInfoCenter), name: NSNotification.Name.UIApplicationDidEnterBackground.rawValue, object: nil)
        
        // For Interruption 
        NotificationCenter.addObserver(observer: self, selector: #selector(LocalMusicPlayer.audioSessionInterruption), name: NSNotification.Name.AVAudioSessionInterruption.rawValue, object: nil)

        // For Audio route change
        NotificationCenter.addObserver(observer: self, selector: #selector(LocalMusicPlayer.audioSessionRouteChange), name: NSNotification.Name.AVAudioSessionRouteChange.rawValue, object: nil)
        
        // For background task
        NotificationCenter.addObserver(observer: self, selector: #selector(LocalMusicPlayer.willResignActive), name: NSNotification.Name.UIApplicationWillResignActive.rawValue, object: nil)
        NotificationCenter.addObserver(observer: self, selector: #selector(LocalMusicPlayer.didBecomeActive), name: NSNotification.Name.UIApplicationDidBecomeActive.rawValue, object: nil)
    }
    
    deinit {
        self.removePlayer()

        NotificationCenter.removeObserver(observer: self, name: NSNotification.Name.UIApplicationDidEnterBackground.rawValue, object: nil)
        NotificationCenter.removeObserver(observer: self, name: NSNotification.Name.AVAudioSessionInterruption.rawValue, object: nil)
        NotificationCenter.removeObserver(observer: self, name: NSNotification.Name.AVAudioSessionRouteChange.rawValue, object: nil)
        NotificationCenter.removeObserver(observer: self, name: NSNotification.Name.UIApplicationWillResignActive.rawValue, object: nil)
        NotificationCenter.removeObserver(observer: self, name: NSNotification.Name.UIApplicationDidBecomeActive.rawValue, object: nil)
    }
    
    // MARK: - Internal methods
    // MARK: Play
    func play() {
        if self.canPlay() {
            self.isPlaying = true
            
            do {
                try AVAudioSession.sharedInstance().setActive(true)
            } catch let error {
                print("setActive error = \(error)")
            }
            
            self.player().play()
            
            NotificationCenter.postNotificationEvent(event: .localMusicStarted, object: self)
            
            self.playbackInfoToNowPlayingInfoCenter()
            MPNowPlayingInfoCenter.default().playbackState = .paused
        } else {
            self.watitingForPlay = true
        }
    }
    
    func playWithPlaylist(playlist: MPMediaPlaylist, selectTrackIndex: Int) -> Bool {
        if self.hasPlayableItem(items: playlist.items) == false {
            return false
        }
        
        if self.playBackStatusIsPlaying() {
            self.pause()
        }
        
        self.sourceType = .Playlist
        self.currentPlayList = playlist
        self.currentCollection = nil
        self.setItemsToPlayer(items: playlist.items, index: selectTrackIndex)
        
        return true
    }
    
    func playWithCollection(collection: MPMediaItemCollection, selectTrackIndex: Int, type: LocalTrackSouceType) -> Bool {
        if self.hasPlayableItem(items: collection.items) == false {
            return false
        }
        if self.playBackStatusIsPlaying() {
            self.pause()
        }
        
        self.sourceType = type
        self.currentCollection = collection
        self.currentPlayList = nil
        self.setItemsToPlayer(items: collection.items, index: selectTrackIndex)
        
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
        self.setItemsToPlayer(items: [meidaItem], index: 0)
        
        return false
    }
    
    // MARK: Pause
    func pause() {
        self.isPlaying = false
        
        self.player().pause()
        
        NotificationCenter.postNotificationEvent(event: .localMusicPaused, object: self)
        
        self.playbackInfoToNowPlayingInfoCenter()
        MPNowPlayingInfoCenter.default().playbackState = .paused
        
        DispatchQueue.global().async {
            do {
                try AVAudioSession.sharedInstance().setActive(false)
            } catch let error {
                print("setActive error = \(error)")
            }
        }
    }
    
    // MARK: Skip
    func skipToNext() {
        if let nextTrack = self.nextTrack() {
            if self.replaceTrack(item: nextTrack) {
                self.currentQueueIndex = self.nextIndex()
            } else {
                let playableIndex = self.searchPlayableTrackIndex(ascending: true)
                if playableIndex == NSNotFound {
                    return
                }
                if self.replaceTrack(item: self.localTracksQueue[playableIndex]) {
                    self.currentQueueIndex = playableIndex
                }
            }
        }
    }
    
    func skipToPrevisu() {
        if let previousTrack = self.previousTrack() {
            if self.replaceTrack(item: previousTrack) {
                self.currentQueueIndex = self.previousIndex()
            } else {
                let playableIndex = self.searchPlayableTrackIndex(ascending: false)
                if playableIndex == NSNotFound {
                    return
                }
                if self.replaceTrack(item: self.localTracksQueue[playableIndex]) {
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
    func seekToTime(targetTime: TimeInterval, completion: (() -> Void)?) {
        if self.currentTime() == targetTime {
            completion?()
            return
        }
        
        guard let currentItem = self.player().currentItem else { return }
        var seekTime = kCMTimeZero
        if targetTime != 0 {
            seekTime = CMTimeMakeWithSeconds(Float64(targetTime), currentItem.asset.duration.timescale)
        }
        currentItem.seek(to: seekTime, completionHandler: { (finished) -> Void in
            completion?()
            self.updatePlaybackTimeToNowPlayingInfoCenter()
        })
    }
    
    func seekForward(begin :Bool) {
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
    
    func seekBackward(begin :Bool) {
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

    func startSeekTimer(forward : Bool) {
        if self.remoteSeekTimer == nil {
            self.remoteSeekTimer = Timer.scheduledTimer(timeInterval: 0.2,
                target: self,
                selector: #selector(LocalMusicPlayer.remoteSeek),
                userInfo: ["Forward": forward],
                repeats: true)
            
            NotificationCenter.postNotificationEvent(event: .localMusicSeekByRemoteBegan, object: nil)
        }
    }
    
    func stopSeekTimer() {
        if self.remoteSeekTimer != nil {
            self.remoteSeekTimer?.invalidate()
            self.remoteSeekTimer = nil
            NotificationCenter.postNotificationEvent(event: .localMusicSeekByRemoteEnded, object: nil)
        }
    }
    
    @objc func remoteSeek(timer: Timer) {
        if let useInfo = timer.userInfo as? [String: Any],
            let isForward = useInfo["Forward"] as? Bool {

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
            self.seekToTime(targetTime: currentTime, completion: nil)
        }
    }
    
    // MARK: Status
    func playBackStatusIsPlaying() -> Bool {
        if self.player().status == .readyToPlay && self.isPlaying == true {
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
            (currentItem.status == .readyToPlay) &&
            (self.player().status == .readyToPlay)
    }
    
    func currentTime() -> TimeInterval {
        return TimeInterval(CMTimeGetSeconds(self.player().currentTime()))
    }
    
    func currentTrackPlaybackDuration() -> TimeInterval {
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
    
    func isCurrentTrackVideo() -> Bool {
        if let currentTrack = self.currentTrack() {
            return self.isVideoType(item: currentTrack)
        }
        return false
    }
    
    func currentVideoPlayer() -> AVPlayer? {
        if !isCurrentTrackVideo() {
            return nil
        }
        return self.currentPlayer
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
        self.player().actionAtItemEnd = .none
        self.player().rate = 0
        
        // Status KVO
        self.player().addObserver(self, forKeyPath: "status", options: .new, context: nil)
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
            NotificationCenter.removeObserver(observer: self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime.rawValue, object: currentPlyaerItem)
            self.currentPlayer?.replaceCurrentItem(with: nil)
        }
        self.currentPlayer = nil
    }
    
    private func player() -> AVPlayer {
        if let unwrapedPlayer = self.currentPlayer {
            return unwrapedPlayer
        }
        self.createPlayer(item: nil)
        return self.currentPlayer!
    }
    
    // MARK: PlayerItem
    private func playerItem(asset: AVURLAsset) -> AVPlayerItem {
        let playerItem = AVPlayerItem(asset: asset)
        playerItem.addObserver(self, forKeyPath: "status", options: /*.Initial |*/ .new, context: nil)
        NotificationCenter.addObserver(observer: self, selector: #selector(LocalMusicPlayer.didPlayToEndTime), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime.rawValue, object: playerItem)
        
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
                currentQueueToShuffle(shuffle: true)
            }
            selectedIndex = 0
        }
        if self.replaceTrack(item: self.localTracksQueue[selectedIndex]) {
            self.currentQueueIndex = selectedIndex
        } else {
            let playableIndex = self.searchPlayableTrackIndex(ascending: true)
            if playableIndex == NSNotFound {
                return
            }
            if self.replaceTrack(item: self.localTracksQueue[playableIndex]) {
                self.currentQueueIndex = playableIndex
            }
        }
        
        if index >= 0 && self.shuffleMode == .On {
            currentQueueToShuffle(shuffle: true)
        }
    }
    
    private func replaceTrack(item: MPMediaItem) -> Bool {
        if let itemURL = item.assetURL {
            let urlAsset = AVURLAsset(url: itemURL)
            urlAsset.loadValuesAsynchronously(forKeys: ["tracks","duration","playable"], completionHandler: {
                DispatchQueue.main.async {
                    self.removePlayer()
                    self.createPlayer(item: self.playerItem(asset: urlAsset))
                    NotificationCenter.postNotificationEvent(event: .localMusicTrackDidChange, object: self)
                    if self.isVideoType(item: item) {
                        NotificationCenter.postNotificationEvent(event: .playVideo, object: nil, userInfo: ["player": self.player()])
                    }
                    if self.player().status == .readyToPlay {
                        self.watitingForPlay = false
                        self.play()
                    } else {
                        self.watitingForPlay = true
                    }
                }
            })
            return true
        }
        // Can not playback because this track maybe iCloud or DRM.
        return false
    }
    
    private func isVideoType(item: MPMediaItem) -> Bool {
        if item.mediaType.intersection(.anyVideo).rawValue != 0 {
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
            for index in startIndex ..< self.localTracksQueue.count {
                if self.localTracksQueue[index].assetURL != nil {
                    return index
                }
            }
            if self.currentQueueIndex != 0 {
                for index in 0 ..< self.currentQueueIndex {
                    if self.localTracksQueue[index].assetURL != nil {
                        return index
                    }
                }
            }
        } else {
            for index in (0 ..< startIndex) .reversed() {
                if self.localTracksQueue[index].assetURL != nil {
                    return index
                }
            }
            if self.currentQueueIndex != (self.localTracksQueue.count - 1) {
                for index in ((self.currentQueueIndex + 1) ..< (self.localTracksQueue.count - 1)).reversed() {
                    if self.localTracksQueue[index].assetURL != nil {
                        return index
                    }
                }
            }
        }
        
        NotificationCenter.postNotificationEvent(event: .localMusicNoPlayableTrack, object: self)
        
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
                    for newCurrentIndex in 0 ..< self.localTracksQueue.count {
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
                    for newCurrentIndex in 0 ..< items.count {
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
    @objc func didPlayToEndTime() {
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
            self.seekToTime(targetTime: 0, completion: { () -> Void in
                self.pause()
            })
        }
    }
    
    // MARK: - KVO Handler
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "status" {
            if let playerItem = self.player().currentItem {
                if self.player().status == .readyToPlay && playerItem.status == .readyToPlay {
                    if self.watitingForPlay {
                        self.play()
                        self.watitingForPlay = false
                    }
                }
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    // MARK: - For MPNowPlayingInfoCenter
    @objc func playbackInfoToNowPlayingInfoCenter() {
        DispatchQueue.main.async {
            guard let mediaItem = self.currentTrack() else { return }
            var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [String: Any]()
            nowPlayingInfo[MPMediaItemPropertyTitle] = mediaItem.title ?? ""
            nowPlayingInfo[MPMediaItemPropertyArtist] = mediaItem.artist ?? ""
            nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = mediaItem.albumTitle ?? ""
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = self.currentTrackPlaybackDuration()
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.currentTime()
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = self.player().rate
            if #available(iOS 10.0, *) {
                nowPlayingInfo[MPNowPlayingInfoPropertyMediaType] = self.isVideoType(item: mediaItem) ? MPNowPlayingInfoMediaType.video.rawValue : MPNowPlayingInfoMediaType.audio.rawValue
            }
            if #available(iOS 10.3, *) {
                nowPlayingInfo[MPNowPlayingInfoPropertyAssetURL] = mediaItem.assetURL
            }
            nowPlayingInfo[MPMediaItemPropertyArtwork] = mediaItem.artwork
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
            
            MPNowPlayingInfoCenter.default().playbackState = self.isPlaying ? .playing : .paused
        }
    }
    
    
    private func updatePlaybackTimeToNowPlayingInfoCenter() {
        if self.currentTrack() == nil {
            return
        }
        DispatchQueue.main.async {
            if var playingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo {
                playingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.currentTime()
                MPNowPlayingInfoCenter.default().nowPlayingInfo = playingInfo
            }
        }
    }

    // MARK: - For AVAudioSessionInterruptionNotification
    @objc func audioSessionInterruption(notification: NSNotification) {
        guard let interruptionType = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? NSNumber else { return }
        guard let type = AVAudioSessionInterruptionType(rawValue: interruptionType.uintValue) else { return }
        switch type {
        case .began:
            if self.isPlaying {
                self.pause()
            }
            
        case .ended:
            guard let interruptionOption = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? NSNumber else { return }
            if interruptionOption.uintValue == AVAudioSessionInterruptionOptions.shouldResume.rawValue {
                self.play()
            }            
        }
    }

    // MARK: - For AVAudioSessionRouteChangeNotification
    @objc func audioSessionRouteChange(notification: NSNotification) {
        if let changeReason = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? NSNumber {
            if let reason = AVAudioSessionRouteChangeReason(rawValue: changeReason.uintValue) {
                switch reason {
                case .oldDeviceUnavailable:
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
        MPRemoteCommandCenter.shared().playCommand.addTarget(self, action: #selector(LocalMusicPlayer.remoteCommandPlay))
        MPRemoteCommandCenter.shared().pauseCommand.addTarget(self, action: #selector(LocalMusicPlayer.remoteCommandPause))
        MPRemoteCommandCenter.shared().togglePlayPauseCommand.addTarget(self, action: #selector(LocalMusicPlayer.remoteCommandPlayOrPause))
        MPRemoteCommandCenter.shared().stopCommand.addTarget(self, action: #selector(LocalMusicPlayer.remoteCommandStop))
        MPRemoteCommandCenter.shared().nextTrackCommand.addTarget(self, action: #selector(LocalMusicPlayer.remoteCommandNext))
        MPRemoteCommandCenter.shared().previousTrackCommand.addTarget(self, action: #selector(LocalMusicPlayer.remoteCommandPrevious))
        MPRemoteCommandCenter.shared().seekForwardCommand.addTarget(self, action: #selector(LocalMusicPlayer.remoteCommandseekForward))
        MPRemoteCommandCenter.shared().seekBackwardCommand.addTarget(self, action: #selector(LocalMusicPlayer.remoteCommandseekBackward))
        
        if #available(iOS 9.1, *) {
            MPRemoteCommandCenter.shared().changePlaybackPositionCommand.addTarget(self, action: #selector(LocalMusicPlayer.remoteCommandChangePlaybackPosition))
        }
    }
    
    // MARK: - Remote Command Handler
    @objc func remoteCommandPlay() {
        self.play()
        self.playbackInfoToNowPlayingInfoCenter()
    }
    
    @objc func remoteCommandPause() {
        self.pause()
        self.playbackInfoToNowPlayingInfoCenter()
    }
    
    @objc func remoteCommandPlayOrPause() {
        if self.isPlaying {
            self.pause()
        } else {
            self.play()
        }
        self.playbackInfoToNowPlayingInfoCenter()
    }
    
    @objc func remoteCommandStop() {
        self.pause()
        self.playbackInfoToNowPlayingInfoCenter()
    }
    
    @objc func remoteCommandNext() {
        self.skipToNext()
        self.playbackInfoToNowPlayingInfoCenter()
    }
    
    @objc func remoteCommandPrevious() {
        self.skipToPrevisu()
        self.playbackInfoToNowPlayingInfoCenter()
    }

    @objc func remoteCommandseekForward(event: MPSeekCommandEvent) {
        self.seekForward(begin: event.type == .beginSeeking)
        self.playbackInfoToNowPlayingInfoCenter()
    }
    
    @objc func remoteCommandseekBackward(event: MPSeekCommandEvent) {
        self.seekBackward(begin: event.type == .beginSeeking)
        self.playbackInfoToNowPlayingInfoCenter()
    }
    
    @available(iOS 9.0, *)
    @objc func remoteCommandChangePlaybackPosition(event: MPChangePlaybackPositionCommandEvent) -> MPRemoteCommandHandlerStatus {
        self.seekToTime(targetTime: event.positionTime) {
            self.playbackInfoToNowPlayingInfoCenter()
        }

        return MPRemoteCommandHandlerStatus.success
    }
    
    // MARK: - For Background task
    @objc func willResignActive(notification: NSNotification) {
        self.backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(expirationHandler: { () -> Void in
            UIApplication.shared.endBackgroundTask(self.backgroundTaskIdentifier)
            self.backgroundTaskIdentifier = UIBackgroundTaskInvalid
        })
    }

    @objc func didBecomeActive(notification: NSNotification) {
        UIApplication.shared.endBackgroundTask(self.backgroundTaskIdentifier)
    }
}
