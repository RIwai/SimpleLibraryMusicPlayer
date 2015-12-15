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

    // MARK: Initialize
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!

        self.appendAVPlayerView()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.appendAVPlayerView()
    }
    
    init() {
        super.init(frame: CGRectZero)
        
        self.appendAVPlayerView()
    }

    // MARK: Configuration SubView
    private func appendAVPlayerView() {
        // AVPlayerView
        self.playerView = AVPlayerView(frame: self.bounds)
        self.addAVPlayerView()        
    }

    // MARK: Video
    func setVideoPlayer(player: AVPlayer) {
        if self.playerView == nil {
            self.playerView = AVPlayerView(frame: CGRect(origin: CGPointZero, size: self.frame.size))
        }
        self.playerView?.setPlayer(player)
    }

    // MARK: AVPlayerView
    func removeAVPlayerView() -> AVPlayerView? {
        guard let playerView = self.playerView else {
            return nil
        }
        playerView.removeFromSuperview()
        playerView.autoresizingMask = []
        return playerView
    }

    func addAVPlayerView() {
        guard let playerView = self.playerView else {
            return
        }
        if playerView.superview != nil {
            playerView.removeFromSuperview()
        }
        playerView.backgroundColor = UIColor.clearColor()
        playerView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        self.addSubview(playerView)
    }
}
