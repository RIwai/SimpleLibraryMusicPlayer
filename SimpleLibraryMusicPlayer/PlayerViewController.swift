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
    private var timer: Timer? = nil
    private var sliderTracking: Bool = false
    private var fullScreenVideoConinerViewController: FullScreenVideoConinerViewController?
    private var fullScreenBaseView: UIView?
    
    // Status bar
    override var prefersStatusBarHidden: Bool {
        return self.fullScreenVideoConinerViewController != nil
    }
    override var shouldAutorotate: Bool {
        return false
    }
    
    // MARK: - Action methods
    // MARK: - Override methods
    override func viewDidLoad() {
        super.viewDidLoad()

        // User interface
        self.artworkImageView.layer.borderWidth = 0.5
        self.artworkImageView.layer.borderColor = UIColor.lightGray.cgColor
        self.artworkImageView.layer.cornerRadius = 2.0
        self.artworkImageView.clipsToBounds = true
        
        self.playButton.layer.borderWidth = 0.5
        self.playButton.layer.borderColor = UIColor.darkGray.cgColor
        self.playButton.layer.cornerRadius = self.playButton.frame.height / 2
        self.playButton.clipsToBounds = true

        self.skipButton.layer.borderWidth = 0.5
        self.skipButton.layer.borderColor = UIColor.darkGray.cgColor
        self.skipButton.layer.cornerRadius = self.skipButton.frame.height / 2
        self.skipButton.clipsToBounds = true
        
        self.prevButton.layer.borderWidth = 0.5
        self.prevButton.layer.borderColor = UIColor.darkGray.cgColor
        self.prevButton.layer.cornerRadius = self.prevButton.frame.height / 2
        self.prevButton.clipsToBounds = true

        self.lylicsTextView.layer.borderWidth = 0.5
        self.lylicsTextView.layer.borderColor = UIColor.lightGray.cgColor
        
        self.updateSkipButtons()

        // Mode
        self.repeatSwitch.isOn = LocalMusicPlayer.sharedPlayer.repeatStatus == .All
        self.shuffleSwitch.isOn = LocalMusicPlayer.sharedPlayer.shuffleMode == .On

        // Buttons Long press
        self.skipButton.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: Selector(("seekForward:"))))
        self.prevButton.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: Selector(("seekBackward:"))))
        
        // Player
        self.playbackStatusDidChange()
        self.playingItemDidChange()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.addNotificationObserver()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let currentMediaItem = LocalMusicPlayer.sharedPlayer.currentTrack() {
            self.setupUIPartsWithMediaItem(meidaItem: currentMediaItem)
        } else {
            // Close if no track in player
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.removeNotificationObserver()
    }
    
    @IBAction func tapCloseButton(sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
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
        if self.seekSlider.isTracking {
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
                LocalMusicPlayer.sharedPlayer.seekToTime(targetTime: TimeInterval(self.seekSlider.value), completion: nil)
                
                self.sliderTracking = false
            } else {
                self.sliderTracking = true
            }
        }
        // Label update
        self.currentTimeLabel.text = Util.timeString(secondTimes: TimeInterval(self.seekSlider.value))
    }

    @IBAction func repatSwitchValueChange(sender: AnyObject) {
        LocalMusicPlayer.sharedPlayer.repeatStatus = self.repeatSwitch.isOn ? .All : .None
        self.updateSkipButtons()
    }

    @IBAction func suffleSwitchValueChange(sender: AnyObject) {
        LocalMusicPlayer.sharedPlayer.shuffleMode = self.shuffleSwitch.isOn ? .On : .Off
    }
    
    @IBAction func tapFullScreenButton(sender: AnyObject) {
        self.videoToFullScreen(isLandscapeLeft: true)
    }

    // MARK: - Gesture handler
    func seekForward(longPressGestureRecognizer: UILongPressGestureRecognizer) {
        switch longPressGestureRecognizer.state {
        case .began:
            LocalMusicPlayer.sharedPlayer.seekForward(begin: true)
        case .ended:
            LocalMusicPlayer.sharedPlayer.seekForward(begin: false)
        default:
            break
        }
    }
    
    func seekBackward(longPressGestureRecognizer: UILongPressGestureRecognizer) {
        switch longPressGestureRecognizer.state {
        case .began:
            LocalMusicPlayer.sharedPlayer.seekBackward(begin: true)
        case .ended:
            LocalMusicPlayer.sharedPlayer.seekBackward(begin: false)
        default:
            break
        }
    }
    
    // MARK: - Player notification handler
    dynamic func playbackStatusDidChange() {
        DispatchQueue.main.async {
            self.togglePlayButton()
            self.playbackTimeTimer()
        }
    }

    dynamic func playingItemDidChange() {
        DispatchQueue.main.async {
            if let currentMediaItem = LocalMusicPlayer.sharedPlayer.currentTrack() {
                self.setupUIPartsWithMediaItem(meidaItem: currentMediaItem)
            }
        }
    }
    
    dynamic func noPlayableTrack() {
        DispatchQueue.main.async {
            if LocalMusicPlayer.sharedPlayer.currentTrack() == nil {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }

    dynamic func remoteSeekBegan() {
        DispatchQueue.main.async {
            if self.timer == nil {
                self.timer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(PlayerViewController.playbackTimer), userInfo: nil, repeats: true)
            }
        }
    }

    dynamic func remoteSeekEnded() {
        DispatchQueue.main.async {
            if let timer = self.timer {
                timer.invalidate()
                self.timer = nil
                
                self.playbackTimer()
            } else {
                // Do nothing
            }
        }
    }
    
    // MARK: - Video
    dynamic func playVideo(notfication: NSNotification) {
        guard let player = notfication.userInfo?["player"] as? AVPlayer else{
            return
        }
        
        self.setUpVideo(player: player)
    }
    
    // MARK: - Device Roate
    dynamic func rotateChanged() {
        if !self.isVideoPlay() {
            return
        }

        switch UIDevice.current.orientation {
        case .portrait:
            self.videoToNormalSize()
        case .landscapeLeft:
            self.videoToFullScreen(isLandscapeLeft: true)
        case .landscapeRight:
            self.videoToFullScreen(isLandscapeLeft: false)
        default:
            break
        }
    }
    
    // MARK: - Timer method
    func playbackTimer() {
        self.currentTimeLabel.text = Util.timeString(secondTimes: LocalMusicPlayer.sharedPlayer.currentTime())
        self.seekSlider.setValue(Float(LocalMusicPlayer.sharedPlayer.currentTime()), animated: true)
    }

    // MARK: - Private methods
    private func setupUIPartsWithMediaItem(meidaItem: MPMediaItem) {
        if LocalMusicPlayer.sharedPlayer.isCurrentTrackVideo() {
            if let videoPlayer = LocalMusicPlayer.sharedPlayer.currentVideoPlayer() {
                self.setUpVideo(player: videoPlayer)
            }
        } else {
            self.artworkImageView.isHidden = false
            self.videoPlayerView.isHidden = true
            self.fullScreenButtonContainerView.isHidden = true
            if let artwork = meidaItem.artwork {
                let scale = UIScreen.main.scale
                self.artworkImageView.image = artwork.image(at: CGSize(width: 200 * scale, height: 200 * scale))
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
        self.lylicsTextView.isHidden = true
        self.lylicsTextView.text = ""
        if let lyrics = meidaItem.lyrics {
            if !lyrics.isEmpty {
                self.lylicsTextView.isHidden = false
                self.lylicsTextView.text = lyrics
            }
        }
        
        self.currentTimeLabel.text = "00:00"
        self.playbackDurationTimeLabel.text = Util.timeString(secondTimes: meidaItem.playbackDuration )
        
        if meidaItem.playbackDuration != 0 && !meidaItem.playbackDuration.isNaN {
            // Set seek bar
            self.seekSlider.maximumValue = Float(meidaItem.playbackDuration)
            self.seekSlider.setValue(0, animated: true)
        }

        self.playbackTimer()
        self.updateSkipButtons()
    }
    
    private func addNotificationObserver() {
        // Player status
        NotificationCenter.addObserver(observer: self, selector: #selector(PlayerViewController.playbackStatusDidChange), event: .localMusicStarted, object: nil)
        NotificationCenter.addObserver(observer: self, selector: #selector(PlayerViewController.playbackStatusDidChange), event: .localMusicPaused, object: nil)
        NotificationCenter.addObserver(observer: self, selector: #selector(PlayerViewController.playingItemDidChange), event: .localMusicTrackDidChange, object: nil)
        NotificationCenter.addObserver(observer: self, selector: #selector(PlayerViewController.noPlayableTrack), event: .localMusicNoPlayableTrack, object: nil)
        NotificationCenter.addObserver(observer: self, selector: #selector(PlayerViewController.remoteSeekBegan), event: .localMusicSeekByRemoteBegan, object: nil)
        NotificationCenter.addObserver(observer: self, selector: #selector(PlayerViewController.remoteSeekEnded), event: .localMusicSeekByRemoteEnded, object: nil)
        
        // Video
        NotificationCenter.addObserver(observer: self, selector: #selector(PlayerViewController.playVideo), event: .playVideo, object: nil)
        
        // Roate
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.addObserver(observer: self, selector: #selector(PlayerViewController.rotateChanged), name: NSNotification.Name.UIDeviceOrientationDidChange.rawValue, object: nil)
    }
    
    private func removeNotificationObserver() {
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
        NotificationCenter.removeObserver(observer: self)
    }

    private func togglePlayButton() {
        if LocalMusicPlayer.sharedPlayer.isPlaying {
            self.playButton.setTitle("Stop", for: .normal)
        } else {
            self.playButton.setTitle("Play", for: .normal)
        }
    }

    private func updateSkipButtons() {
        self.skipButton.isEnabled = LocalMusicPlayer.sharedPlayer.canSkipToNext()
        self.prevButton.isEnabled = LocalMusicPlayer.sharedPlayer.canSkipToPrevious()
    }
    
    private func playbackTimeTimer() {
        if LocalMusicPlayer.sharedPlayer.isPlaying {
            if self.timer == nil {
                self.timer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(PlayerViewController.playbackTimer), userInfo: nil, repeats: true)
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
        self.artworkImageView.isHidden = true
        self.videoPlayerView.isHidden = false
        self.fullScreenButtonContainerView.isHidden = false
        self.videoPlayerView.setVideoPlayer(player: player)
    }
    
    private func isVideoPlay() -> Bool {
        return !self.videoPlayerView.isHidden
    }
    
    private func isVideoFullScreen() -> Bool {
        if self.fullScreenVideoConinerViewController != nil {
            return true
        }
        
        return false
    }
    
    // MARK: Video Full Screen
    private func videoToFullScreen(isLandscapeLeft: Bool) {
        if self.isVideoFullScreen() {
            return
        }

        self.fullScreenBaseView = UIView(frame: UIScreen.main.bounds)
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
        
        fullScreenBaseView.backgroundColor = UIColor.clear
        self.view.addSubview(fullScreenBaseView)
        
        fullScreenVideoConinerViewController.view.frame = self.videoPlayerView.frame
        fullScreenVideoConinerViewController.modalPresentationCapturesStatusBarAppearance = true
        self.addChildViewController(fullScreenVideoConinerViewController)
        fullScreenBaseView.addSubview(fullScreenVideoConinerViewController.view)
        fullScreenVideoConinerViewController.didMove(toParentViewController: self)
        fullScreenVideoConinerViewController.delegate = self

        fullScreenVideoConinerViewController.setVideoView(avPlayerView: avPlayerView)

        self.setNeedsStatusBarAppearanceUpdate()
        UIApplication.shared.setStatusBarOrientation( isLandscapeLeft ? .landscapeRight : .landscapeLeft,
            animated: true)
        
        UIView.animate(withDuration: 0.3, animations: { () -> Void in
            fullScreenBaseView.backgroundColor = UIColor.black
            let rotation = CGFloat((Double.pi / 2) * (isLandscapeLeft ? 1 : -1))
            fullScreenVideoConinerViewController.view.transform = CGAffineTransform(rotationAngle: rotation)
            fullScreenVideoConinerViewController.view.frame = fullScreenBaseView.frame
            }) { (finish) -> Void in
                fullScreenVideoConinerViewController.tapVideoView()
        }
    }
    
    fileprivate func videoToNormalSize() {
        if !self.isVideoFullScreen() {
            return
        }

        guard
            let fullScreenBaseView = self.fullScreenBaseView,
            let fullScreenVideoConinerViewController = self.fullScreenVideoConinerViewController else {
                return
        }

        fullScreenVideoConinerViewController.videoControllerHidden()

        UIApplication.shared.setStatusBarOrientation( .portrait, animated: true)
        
        UIView.animate(withDuration: 0.3, animations: { () -> Void in
            fullScreenBaseView.backgroundColor = UIColor.clear
            fullScreenVideoConinerViewController.view.transform = CGAffineTransform.identity
            fullScreenVideoConinerViewController.view.frame = self.videoPlayerView.frame
            
            }) { (finish) -> Void in
                fullScreenVideoConinerViewController.removeVideoPlayerView()
                self.videoPlayerView.addAVPlayerView()
                
                fullScreenVideoConinerViewController.willMove(toParentViewController: nil)
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

