//
//  FullScreenVideoConinerViewController.swift
//  SimpleLibraryMusicPlayer
//
//  Created by Ryota Iwai on 2015/12/14.
//  Copyright © 2015年 Ryota Iwai. All rights reserved.
//

import UIKit

// MARK: - Protocol
protocol FullScreenVideoConinerViewControllerDelegate: class {
    func closeFullScreen(fullScreenVideoConinerViewController: FullScreenVideoConinerViewController)
}

// MARK: -
class FullScreenVideoConinerViewController: UIViewController {

    // MARK: - IBOutlet
    @IBOutlet weak var videoControllerView: UIView!
    
    // MARK: - Internal properties
    weak var delegate: FullScreenVideoConinerViewControllerDelegate?
    var avPlayerView: AVPlayerView?
    
    private var timer: NSTimer?

    // MARK: - Override methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: .Fade)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        self.setVideoControllerHiddenTimer()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        if self.timer != nil {
            self.timer?.invalidate()
            self.timer = nil
        }
    }
    
    // MARK: - Internal method
    func setVideoView(avPlayerView: AVPlayerView) {
        avPlayerView.frame = CGRect(origin: CGPointZero, size: self.view.frame.size)
        avPlayerView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        self.view.addSubview(avPlayerView)
        self.view.bringSubviewToFront(self.videoControllerView)
        
        avPlayerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "tapVideoView"))

        self.avPlayerView = avPlayerView
    }
    
    func removeVideoPlayerView() {
        guard let avPlayerView = self.avPlayerView else {
            return
        }
        
        avPlayerView.removeFromSuperview()
        self.avPlayerView = nil
        
        return
    }

    func tapVideoView() {
        let alpha: CGFloat = self.videoControllerView.alpha == 1 ? 0 : 1
        UIView.animateWithDuration(0.25) { () -> Void in
            self.videoControllerView.alpha = alpha
        }
        if alpha == 1 {
            self.setVideoControllerHiddenTimer()
        }
    }

    func videoControllerHidden() {
        if self.videoControllerView.alpha == 0 {
            return
        }
        UIView.animateWithDuration(0.25) { () -> Void in
            self.videoControllerView.alpha = 0
        }
    }
    
    // MARK: - IBAction
    @IBAction func tapCloseFullScreenView(sender: AnyObject) {
        
        if self.videoControllerView.alpha != 0 {
            self.tapVideoView()
        }
        
        self.delegate?.closeFullScreen(self)
    }
    
    // MARK: - Private
    private func setVideoControllerHiddenTimer() {
        if self.timer != nil {
           self.timer?.invalidate()
        }
        
        self.timer = NSTimer(timeInterval: 5,
            target: self,
            selector: "videoControllerHidden",
            userInfo: nil,
            repeats: false)
        if let timer = self.timer {
            NSRunLoop.mainRunLoop().addTimer(timer, forMode:NSRunLoopCommonModes)
        }
    }
}
