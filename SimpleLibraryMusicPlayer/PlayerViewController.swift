//
//  PlayerViewController.swift
//  SimpleLibraryMusicPlayer
//
//  Created by Ryota Iwai on 2015/08/17.
//  Copyright (c) 2015年 Ryota Iwai. All rights reserved.
//

import UIKit
import MediaPlayer

class PlayerViewController: UIViewController {

    // MARK: - Outlet property
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var artworkImageView: UIImageView!
    @IBOutlet weak var trackTitleLabel: UILabel!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var albumTitleLabel: UILabel!
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var playbackDurationTimeLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var skipButton: UIButton!
    @IBOutlet weak var prevButton: UIButton!
    @IBOutlet weak var shuffleSwitch: UISwitch!
    @IBOutlet weak var repeatSwitch: UISwitch!
    @IBOutlet weak var seekSlider: UISlider!
    @IBOutlet weak var lylicsTextView: UITextView!
    
    // MARK: Internal property
    var mediaItems: [MPMediaItem]? = nil
    
    // MARK: Private property
    private let player: MPMusicPlayerController = MPMusicPlayerController.applicationMusicPlayer()
    private var timer: NSTimer? = nil
    
    // MARK: - Override methods
    override func viewDidLoad() {
        super.viewDidLoad()

        // User interface
        self.artworkImageView.layer.borderWidth = 0.5
        self.artworkImageView.layer.borderColor = UIColor.lightGrayColor().CGColor
        self.artworkImageView.layer.cornerRadius = 2.0
        self.artworkImageView.clipsToBounds = true

        // Set notifications
        self.addPlayerObserver()

        // Mode
        self.repeatSwitch.on = true
        self.player.repeatMode = MPMusicRepeatMode.All
        self.shuffleSwitch.on = false
        self.player.shuffleMode = MPMusicShuffleMode.Off
        
        // Player
        if let items = self.mediaItems {
            self.player.setQueueWithItemCollection(MPMediaItemCollection(items: items))
            self.player.play()
        }
        
    }
    
    // MARK: Action methods
    @IBAction func tapCloseButton(sender: AnyObject) {
        self.player.pause()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func tapPlayButton(sender: AnyObject) {
        if self.player.playbackState == .Playing {
            self.player.pause()
        } else {
            self.player.play()
        }
    }

    @IBAction func tapSkipButton(sender: AnyObject) {
        self.player.skipToNextItem()
    }

    @IBAction func tapPrevButton(sender: AnyObject) {
        self.player.skipToPreviousItem()
    }
    
    @IBAction func seekSliderValueChange(sender: AnyObject) {
        self.player.currentPlaybackTime = NSTimeInterval(self.seekSlider.value)
    }

    @IBAction func repatSwitchValueChange(sender: AnyObject) {
        self.player.repeatMode = self.repeatSwitch.on ? MPMusicRepeatMode.All : MPMusicRepeatMode.None
    }

    @IBAction func suffleSwitchValueChange(sender: AnyObject) {
        self.player.shuffleMode = self.shuffleSwitch.on ? MPMusicShuffleMode.Songs : MPMusicShuffleMode.Off
    }
    
    // MARK: Player notification handler
    func playbackStatusDidChange(notification: NSNotification) {
        self.togglePlayButton()
        self.playbackTimeTimer()
    }

    func playingItemDidChange(notification: NSNotification) {
        if let currentMediaItem = self.player.nowPlayingItem {
            self.setupUIPartsWithMediaItem(currentMediaItem)
        }
    }

    // MARK: Timer method
    func playbackTimer() {
        self.currentTimeLabel.text = Util.timeString(self.player.currentPlaybackTime)
        self.seekSlider.setValue(Float(self.player.currentPlaybackTime), animated: true)
    }

    // MARK: Private methods
    private func setupUIPartsWithMediaItem(meidaItem: MPMediaItem) {
        if let artwork = meidaItem.artwork {
            let scale = UIScreen.mainScreen().scale
            self.artworkImageView.image = artwork.imageWithSize(CGSizeMake(200 * scale, 200 * scale))
        } else {
            self.artworkImageView.image = nil
        }
        
        self.trackTitleLabel.text = meidaItem.title ?? "-"
        self.artistNameLabel.text = meidaItem.artist ?? "-"
        self.albumTitleLabel.text = meidaItem.albumTitle ?? "-"
        if let lyrics = meidaItem.lyrics {
            if !lyrics.isEmpty {
                self.lylicsTextView.hidden = false
                self.lylicsTextView.text = lyrics
            }
        }
        
        self.currentTimeLabel.text = "00:00"
        self.playbackDurationTimeLabel.text = Util.timeString(meidaItem.playbackDuration ?? 0)
        
        if meidaItem.playbackDuration != 0 && isnan(meidaItem.playbackDuration) == false {
            // Set seek bar
            self.seekSlider.maximumValue = Float(meidaItem.playbackDuration)
            self.seekSlider.setValue(0, animated: true)
        }
    }
    
    private func addPlayerObserver() {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        
        notificationCenter.addObserver(self,
            selector: "playbackStatusDidChange:",
            name: MPMusicPlayerControllerPlaybackStateDidChangeNotification,
            object: nil)

        notificationCenter.addObserver(self,
            selector: "playingItemDidChange:",
            name: MPMusicPlayerControllerNowPlayingItemDidChangeNotification,
            object: nil)

        self.player.beginGeneratingPlaybackNotifications()
    }

    private func togglePlayButton() {
        if self.player.playbackState == .Playing {
            self.playButton.setTitle("Stop", forState: UIControlState.Normal)
        } else {
            self.playButton.setTitle("Play", forState: UIControlState.Normal)
        }
    }

    private func playbackTimeTimer() {
        if self.player.playbackState == .Playing {
            if self.timer == nil {
                self.timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "playbackTimer", userInfo: nil, repeats: true)
            }
        } else {
            if let timer = self.timer {
                timer.invalidate()
                self.timer = nil
            } else {
                // Do nothing
            }
        }
    }
}
