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
    @IBOutlet weak var fullScreenButtonContainerView: UIView!
    @IBOutlet weak var videoPlayerView: VideoPlayerView!
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
    private var fullScreenVideoConinerViewController: FullScreenVideoConinerViewController?
    private var fullScreenBaseView: UIView?
    
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

        // Buttons Long press
        self.skipButton.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: "seekForward:"))
        self.prevButton.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: "seekBackward:"))
        
        // Player
        self.playbackStatusDidChange()
        self.playingItemDidChange()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.addNotificationObserver()
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
        
        self.removeNotificationObserver()
    }
    
    // Status bar
    override func prefersStatusBarHidden() -> Bool {
        return self.fullScreenVideoConinerViewController != nil
    }

    override func shouldAutorotate() -> Bool {
        return false
    }
    
    // MARK: - Action methods
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
    
    @IBAction func tapFullScreenButton(sender: AnyObject) {
        self.videoToFullScreen(isLandscapeLeft: true)
    }

    // MARK: - Gesture handler
    func seekForward(longPressGestureRecognizer: UILongPressGestureRecognizer) {
        switch longPressGestureRecognizer.state {
        case .Began:
            LocalMusicPlayer.sharedPlayer.seekForward(begin: true)
        case .Ended:
            LocalMusicPlayer.sharedPlayer.seekForward(begin: false)
        default:
            break
        }
    }
    
    func seekBackward(longPressGestureRecognizer: UILongPressGestureRecognizer) {
        switch longPressGestureRecognizer.state {
        case .Began:
            LocalMusicPlayer.sharedPlayer.seekBackward(begin: true)
        case .Ended:
            LocalMusicPlayer.sharedPlayer.seekBackward(begin: false)
        default:
            break
        }
    }
    
    // MARK: - Player notification handler
    func playbackStatusDidChange() {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.togglePlayButton()
            self.playbackTimeTimer()
        })
    }

    func playingItemDidChange() {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            if let currentMediaItem = LocalMusicPlayer.sharedPlayer.currentTrack() {
                self.setupUIPartsWithMediaItem(currentMediaItem)
            }
        })
    }
    
    func noPlayableTrack() {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            if LocalMusicPlayer.sharedPlayer.currentTrack() == nil {
                self.dismissViewControllerAnimated(true, completion: nil)
            }
        })
    }

    func remoteSeekBegan() {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            if self.timer == nil {
                self.timer = NSTimer.scheduledTimerWithTimeInterval(0.2, target: self, selector: "playbackTimer", userInfo: nil, repeats: true)
            }
        })
    }

    func remoteSeekEnded() {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            if let timer = self.timer {
                timer.invalidate()
                self.timer = nil
                
                self.playbackTimer()
            } else {
                // Do nothing
            }
        })
    }
    
    // MARK: - Video
    func playVideo(notfication: NSNotification) {
        guard let player = notfication.userInfo?["player"] as? AVPlayer else{
            return
        }
        
        self.setUpVideo(player)
    }
    
    // MARK: - Device Roate
    func rotateChanged() {
        if !self.isVideoPlay() {
            return
        }

        switch UIDevice.currentDevice().orientation {
        case .Portrait:
            self.videoToNormalSize()
        case .LandscapeLeft:
            self.videoToFullScreen(isLandscapeLeft: true)
        case .LandscapeRight:
            self.videoToFullScreen(isLandscapeLeft: false)
        default:
            break
        }
    }
    
    // MARK: - Timer method
    func playbackTimer() {
        self.currentTimeLabel.text = Util.timeString(LocalMusicPlayer.sharedPlayer.currentTime())
        self.seekSlider.setValue(Float(LocalMusicPlayer.sharedPlayer.currentTime()), animated: true)
    }

    // MARK: - Private methods
    private func setupUIPartsWithMediaItem(meidaItem: MPMediaItem) {
        if LocalMusicPlayer.sharedPlayer.isCurrentTrackVideo() {
            if let videoPlayer = LocalMusicPlayer.sharedPlayer.currentVideoPlayer() {
                self.setUpVideo(videoPlayer)
            }
        } else {
            self.artworkImageView.hidden = false
            self.videoPlayerView.hidden = true
            self.fullScreenButtonContainerView.hidden = true
            if let artwork = meidaItem.artwork {
                let scale = UIScreen.mainScreen().scale
                self.artworkImageView.image = artwork.imageWithSize(CGSizeMake(200 * scale, 200 * scale))
            } else {
                self.artworkImageView.image = nil
            }
        }
        
        if let trackTitle = meidaItem.title {
            self.trackTitleLabel.text = "[\(meidaItem.albumTrackNumber)] \(trackTitle)"
        } else {
            self.trackTitleLabel.text = "[\(meidaItem.albumTrackNumber)]"
        }
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
    
    private func addNotificationObserver() {
        // Player status
        NSNotificationCenter.addObserver(self, selector: "playbackStatusDidChange", event: .LocalMusicStarted, object: nil)
        NSNotificationCenter.addObserver(self, selector: "playbackStatusDidChange", event: .LocalMusicPaused, object: nil)
        NSNotificationCenter.addObserver(self, selector: "playingItemDidChange", event: .LocalMusicTrackDidChange, object: nil)
        NSNotificationCenter.addObserver(self, selector: "noPlayableTrack", event: .LocalMusicNoPlayableTrack, object: nil)
        NSNotificationCenter.addObserver(self, selector: "remoteSeekBegan", event: .LocalMusicSeekByRemoteBegan, object: nil)
        NSNotificationCenter.addObserver(self, selector: "remoteSeekEnded", event: .LocalMusicSeekByRemoteEnded, object: nil)
        
        // Video
        NSNotificationCenter.addObserver(self, selector: "playVideo:", event: .PlayVideo, object: nil)
        
        // Roate
        UIDevice.currentDevice().beginGeneratingDeviceOrientationNotifications()
        NSNotificationCenter.addObserver(self, selector: "rotateChanged", name: UIDeviceOrientationDidChangeNotification, object: nil)
    }
    
    private func removeNotificationObserver() {
        UIDevice.currentDevice().endGeneratingDeviceOrientationNotifications()
        NSNotificationCenter.removeObserver(self)
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
    
    private func setUpVideo(player: AVPlayer) {
        // Play Video
        self.artworkImageView.hidden = true
        self.videoPlayerView.hidden = false
        self.fullScreenButtonContainerView.hidden = false
        self.videoPlayerView.setVideoPlayer(player)
    }
    
    private func isVideoPlay() -> Bool {
        return !self.videoPlayerView.hidden
    }
    
    private func isVideoFullScreen() -> Bool {
        if self.fullScreenVideoConinerViewController != nil {
            return true
        }
        
        return false
    }
    
    // MARK: Video Full Screen
    private func videoToFullScreen(isLandscapeLeft isLandscapeLeft: Bool) {
        if self.isVideoFullScreen() {
            return
        }

        self.fullScreenBaseView = UIView(frame: UIScreen.mainScreen().bounds)
        guard let fullScreenBaseView = self.fullScreenBaseView else {
            return
        }
        
        self.fullScreenVideoConinerViewController = FullScreenVideoConinerViewController(nibName: "FullScreenVideoConinerViewController", bundle:nil)
        guard let fullScreenVideoConinerViewController = self.fullScreenVideoConinerViewController else {
            self.fullScreenBaseView = nil
            return
        }
        
        guard let avPlayerView = self.videoPlayerView.removeAVPlayerView() else {
            self.fullScreenBaseView = nil
            self.fullScreenVideoConinerViewController = nil
            return
        }
        
        fullScreenBaseView.backgroundColor = UIColor.clearColor()
        self.view.addSubview(fullScreenBaseView)
        
        fullScreenVideoConinerViewController.view.frame = self.videoPlayerView.frame
        fullScreenVideoConinerViewController.modalPresentationCapturesStatusBarAppearance = true
        self.addChildViewController(fullScreenVideoConinerViewController)
        fullScreenBaseView.addSubview(fullScreenVideoConinerViewController.view)
        fullScreenVideoConinerViewController.didMoveToParentViewController(self)
        fullScreenVideoConinerViewController.delegate = self

        fullScreenVideoConinerViewController.setVideoView(avPlayerView)

        self.setNeedsStatusBarAppearanceUpdate()
        UIApplication.sharedApplication().setStatusBarOrientation( isLandscapeLeft ? .LandscapeRight : .LandscapeLeft,
            animated: true)
        
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            fullScreenBaseView.backgroundColor = UIColor.blackColor()
            let rotation = CGFloat((M_PI / 2) * (isLandscapeLeft ? 1 : -1))
            fullScreenVideoConinerViewController.view.transform = CGAffineTransformMakeRotation(rotation)
            fullScreenVideoConinerViewController.view.frame = fullScreenBaseView.frame
            }) { (finish) -> Void in
                fullScreenVideoConinerViewController.tapVideoView()
        }
    }
    
    private func videoToNormalSize() {
        if !self.isVideoFullScreen() {
            return
        }

        guard
            let fullScreenBaseView = self.fullScreenBaseView,
            let fullScreenVideoConinerViewController = self.fullScreenVideoConinerViewController else {
                return
        }

        fullScreenVideoConinerViewController.videoControllerHidden()

        UIApplication.sharedApplication().setStatusBarOrientation( .Portrait, animated: true)
        
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            fullScreenBaseView.backgroundColor = UIColor.clearColor()
            fullScreenVideoConinerViewController.view.transform = CGAffineTransformIdentity
            fullScreenVideoConinerViewController.view.frame = self.videoPlayerView.frame
            
            }) { (finish) -> Void in
                fullScreenVideoConinerViewController.removeVideoPlayerView()
                self.videoPlayerView.addAVPlayerView()
                
                fullScreenVideoConinerViewController.willMoveToParentViewController(nil)
                fullScreenVideoConinerViewController.view.removeFromSuperview()
                fullScreenVideoConinerViewController.removeFromParentViewController()
                
                fullScreenBaseView.removeFromSuperview()
                
                self.fullScreenBaseView = nil
                self.fullScreenVideoConinerViewController = nil

                self.setNeedsStatusBarAppearanceUpdate()
        }
    }
}

// MARK: - FullScreenVideoConinerViewControllerDelegate
extension PlayerViewController: FullScreenVideoConinerViewControllerDelegate {
    
    func closeFullScreen(fullScreenVideoConinerViewController: FullScreenVideoConinerViewController) {
        self.videoToNormalSize()
    }
}

