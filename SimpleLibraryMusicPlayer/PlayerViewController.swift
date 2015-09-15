//
//  PlayerViewController.swift
//  SimpleLibraryMusicPlayer
//
//  Created by Ryota Iwai on 2015/08/17.
//  Copyright (c) 2015年 Ryota Iwai. All rights reserved.
//

import UIKit
import MediaPlayer
import AVFoundation

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
    
    // MARK: Private property
    private var timer: NSTimer? = nil
    private var sliderTracking: Bool = false
    
    // MARK: - Override methods
    override func viewDidLoad() {
        super.viewDidLoad()

        // User interface
        self.artworkImageView.layer.borderWidth = 0.5
        self.artworkImageView.layer.borderColor = UIColor.lightGrayColor().CGColor
        self.artworkImageView.layer.cornerRadius = 2.0
        self.artworkImageView.clipsToBounds = true
        
        self.playButton.layer.borderWidth = 0.5
        self.playButton.layer.borderColor = UIColor.darkGrayColor().CGColor
        self.playButton.layer.cornerRadius = self.playButton.frame.height / 2
        self.playButton.clipsToBounds = true

        self.skipButton.layer.borderWidth = 0.5
        self.skipButton.layer.borderColor = UIColor.darkGrayColor().CGColor
        self.skipButton.layer.cornerRadius = self.skipButton.frame.height / 2
        self.skipButton.clipsToBounds = true
        
        self.prevButton.layer.borderWidth = 0.5
        self.prevButton.layer.borderColor = UIColor.darkGrayColor().CGColor
        self.prevButton.layer.cornerRadius = self.prevButton.frame.height / 2
        self.prevButton.clipsToBounds = true

        self.lylicsTextView.layer.borderWidth = 0.5
        self.lylicsTextView.layer.borderColor = UIColor.lightGrayColor().CGColor
        
        self.updateSkipButtons()

        // Mode
        self.repeatSwitch.on = LocalMusicPlayer.sharedPlayer.repeatStatus == .All
        self.shuffleSwitch.on = LocalMusicPlayer.sharedPlayer.shuffleMode == .On

        // Player
        self.addPlayerObserver()
        self.playbackStatusDidChange()
        self.playingItemDidChange()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if let currentMediaItem = LocalMusicPlayer.sharedPlayer.currentTrack() {
            self.setupUIPartsWithMediaItem(currentMediaItem)
        } else {
            // Close if no track in player
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.removePlayerObserver()
    }
    
    // MARK: Action methods
    @IBAction func tapCloseButton(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func tapPlayButton(sender: AnyObject) {
        if LocalMusicPlayer.sharedPlayer.isPlaying {
           LocalMusicPlayer.sharedPlayer.pause()
        } else {
            LocalMusicPlayer.sharedPlayer.play()
        }
    }

    @IBAction func tapSkipButton(sender: AnyObject) {
        LocalMusicPlayer.sharedPlayer.skipToNext()
    }

    @IBAction func tapPrevButton(sender: AnyObject) {
        LocalMusicPlayer.sharedPlayer.skipToPrevisu()
    }
    
    @IBAction func seekSliderValueChange(sender: AnyObject) {
        if self.seekSlider.tracking {
            // Stop Timer
            if let timer = self.timer {
                timer.invalidate()
                self.timer = nil
            }
        } else {
            if self.sliderTracking {
                // Start Timer
                self.playbackTimeTimer()
                // Seek
                LocalMusicPlayer.sharedPlayer.seekToTime(NSTimeInterval(self.seekSlider.value), completion: nil)
                
                self.sliderTracking = false
            } else {
                self.sliderTracking = true
            }
        }
        // Label update
        self.currentTimeLabel.text = Util.timeString(NSTimeInterval(self.seekSlider.value))
    }

    @IBAction func repatSwitchValueChange(sender: AnyObject) {
        LocalMusicPlayer.sharedPlayer.repeatStatus = self.repeatSwitch.on ? .All : .None
        self.updateSkipButtons()
    }

    @IBAction func suffleSwitchValueChange(sender: AnyObject) {
        LocalMusicPlayer.sharedPlayer.shuffleMode = self.shuffleSwitch.on ? .On : .Off
    }
    
    // MARK: Player notification handler
    func playbackStatusDidChange() {
        self.togglePlayButton()
        self.playbackTimeTimer()
    }

    func playingItemDidChange() {
        if let currentMediaItem = LocalMusicPlayer.sharedPlayer.currentTrack() {
            self.setupUIPartsWithMediaItem(currentMediaItem)
        }
    }
    
    func noPlayableTrack() {
        if LocalMusicPlayer.sharedPlayer.currentTrack() == nil {
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }

    // MARK: Timer method
    func playbackTimer() {
        self.currentTimeLabel.text = Util.timeString(LocalMusicPlayer.sharedPlayer.currentTime())
        self.seekSlider.setValue(Float(LocalMusicPlayer.sharedPlayer.currentTime()), animated: true)
    }

    // MARK: Private methods
    private func setupUIPartsWithMediaItem(meidaItem: MPMediaItem) {
        if let artwork = meidaItem.artwork {
            let scale = UIScreen.mainScreen().scale
            self.artworkImageView.image = artwork.imageWithSize(CGSizeMake(200 * scale, 200 * scale))
        } else {
            self.artworkImageView.image = nil
        }
        
        self.trackTitleLabel.text = "[\(meidaItem.albumTrackNumber)]  \(meidaItem.title)"
        self.artistNameLabel.text = meidaItem.artist ?? "-"
        self.albumTitleLabel.text = meidaItem.albumTitle ?? "-"
        self.lylicsTextView.hidden = true
        self.lylicsTextView.text = ""
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

        self.playbackTimer()
        self.updateSkipButtons()
    }
    
    private func addPlayerObserver() {
        NSNotificationCenter.addObserver(self, selector: "playbackStatusDidChange", event: .LocalMusicStarted, object: nil)
        NSNotificationCenter.addObserver(self, selector: "playbackStatusDidChange", event: .LocalMusicPaused, object: nil)
        NSNotificationCenter.addObserver(self, selector: "playingItemDidChange", event: .LocalMusicTrackDidChange, object: nil)
        NSNotificationCenter.addObserver(self, selector: "noPlayableTrack", event: .LocalMusicNoPlayableTrack, object: nil)
    }
    
    private func removePlayerObserver() {
        NSNotificationCenter.removeObserver(self, event: .LocalMusicStarted, object: nil)
        NSNotificationCenter.removeObserver(self, event: .LocalMusicPaused, object: nil)
        NSNotificationCenter.removeObserver(self, event: .LocalMusicTrackDidChange, object: nil)
        NSNotificationCenter.removeObserver(self, event: .LocalMusicNoPlayableTrack, object: nil)
    }

    private func togglePlayButton() {
        if LocalMusicPlayer.sharedPlayer.isPlaying {
            self.playButton.setTitle("Stop", forState: UIControlState.Normal)
        } else {
            self.playButton.setTitle("Play", forState: UIControlState.Normal)
        }
    }

    private func updateSkipButtons() {
        self.skipButton.enabled = LocalMusicPlayer.sharedPlayer.canSkipToNext()
        self.prevButton.enabled = LocalMusicPlayer.sharedPlayer.canSkipToPrevious()
    }
    
    private func playbackTimeTimer() {
        if LocalMusicPlayer.sharedPlayer.isPlaying {
            if self.timer == nil {
                self.timer = NSTimer.scheduledTimerWithTimeInterval(0.2, target: self, selector: "playbackTimer", userInfo: nil, repeats: true)
            }
        } else {
            if let timer = self.timer {
                timer.invalidate()
                self.timer = nil
                
                self.playbackTimer()
            } else {
                // Do nothing
            }
        }
    }
    
}
