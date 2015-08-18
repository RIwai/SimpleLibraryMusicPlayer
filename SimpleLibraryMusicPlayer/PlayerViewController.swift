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
    
    // MARK: Internal property
    var mediaItem: MPMediaItem? = nil
    
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

        self.setupUIPartsWithMediaItem()
        
        // Set notifications
        self.addPlayerObserver()

        // Player
        if let item = self.mediaItem {
            self.player.setQueueWithItemCollection(MPMediaItemCollection(items: [item]))
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

    // MARK: Player notification handler
    func playbackStatusDidChange(notification: NSNotification) {
        self.togglePlayButton()
        self.playbackTimeTimer()
    }

    func playingItemDidChange(notification: NSNotification) {
        if let currentMediaItem = self.player.nowPlayingItem {
            self.mediaItem = currentMediaItem
            self.setupUIPartsWithMediaItem()
        }
    }

    // MARK: Timer method
    func playbackTimer() {
        self.currentTimeLabel.text = Util.timeString(self.player.currentPlaybackTime)
    }

    // MARK: Private methods
    private func setupUIPartsWithMediaItem() {
        if let artwork = self.mediaItem?.artwork {
            let scale = UIScreen.mainScreen().scale
            self.artworkImageView.image = artwork.imageWithSize(CGSizeMake(200 * scale, 200 * scale))
        } else {
            self.artworkImageView.image = nil
        }
        
        self.trackTitleLabel.text = self.mediaItem?.title ?? "-"
        self.artistNameLabel.text = self.mediaItem?.artist ?? "-"
        self.albumTitleLabel.text = self.mediaItem?.albumTitle ?? "-"
        
        self.currentTimeLabel.text = "00:00"
        self.playbackDurationTimeLabel.text = Util.timeString(self.mediaItem?.playbackDuration ?? 0)
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
