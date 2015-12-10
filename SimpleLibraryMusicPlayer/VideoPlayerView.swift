//
//  VideoPlayerView.swift
//  SimpleLibraryMusicPlayer
//
//  Created by Ryota Iwai on 2015/12/10.
//  Copyright © 2015年 Ryota Iwai. All rights reserved.
//

import UIKit
import AVFoundation

class VideoPlayerView: UIView {

    private var playerView : AVPlayerView?
    private var indicator: UIActivityIndicatorView!

    // MARK: Initialize
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!

        self.appendSubViews()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.appendSubViews()
    }
    
    init() {
        super.init(frame: CGRectZero)
        
        self.appendSubViews()
    }

    // MARK: Configuration SubViews
    func appendSubViews() {
        // AVPlayerView
        self.playerView = AVPlayerView(frame: self.bounds)
        if let playerView = self.playerView {
            playerView.backgroundColor = UIColor.clearColor()
            playerView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
            self.addSubview(playerView)
        }
        
        // Indicator
        self.indicator = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
        self.indicator.frame.origin = CGPointMake(CGRectGetWidth(self.bounds) / 2.0 - CGRectGetWidth(self.indicator.bounds) / 2.0,
            CGRectGetHeight(self.bounds) / 2.0 - CGRectGetHeight(self.indicator.bounds) / 2.0)
        self.indicator.autoresizingMask = [.FlexibleTopMargin, .FlexibleBottomMargin, .FlexibleRightMargin, .FlexibleLeftMargin]
        self.indicator.hidesWhenStopped = true
        self.addSubview(self.indicator)
        self.indicator.hidden = true
    }

    // MARK: Video
    func setVideoPlayer(player: AVPlayer) {
        if self.playerView == nil {
            self.playerView = AVPlayerView(frame: CGRectMake(0.0, 0.0, self.frame.width, self.frame.height))
        }
        self.playerView?.setPlayer(player)
    }
}
