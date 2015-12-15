//
//  AVPlayerView.swift
//  SimpleLibraryMusicPlayer
//
//  Created by Ryota Iwai on 2015/04/02.
//  Copyright (c) 2015年 Ryota Iwai. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer

class AVPlayerView: UIView {
    
    // MARK: deinit
    deinit {
        NSNotificationCenter.removeObserver(self)
    }

    // MARK: Override
    override class func layerClass() -> AnyClass {
        return AVPlayerLayer.self
    }
    
    override func layoutSublayersOfLayer(layer: CALayer) {
        super.layoutSublayersOfLayer(layer)
        
        if layer == self.layer {
            self.layer.frame = self.bounds
        }
    }

    // MARK: Video
    func setPlayer(avplayer: AVPlayer) {
        guard let layer = self.layer as? AVPlayerLayer else {
            return
        }
        layer.videoGravity = AVLayerVideoGravityResizeAspect
        layer.player = avplayer

        NSNotificationCenter.addObserver(self, selector: "willResignActive:", name: UIApplicationWillResignActiveNotification, object: nil)
        NSNotificationCenter.addObserver(self, selector: "didBecomeActive:", name: UIApplicationDidBecomeActiveNotification, object: nil)
    }

    // MARK: For Background
    func willResignActive(notification: NSNotification) {
        guard let layer = self.layer as? AVPlayerLayer else {
            return
        }
        layer.player = nil
    }

    func didBecomeActive(notification: NSNotification) {
        guard let layer = self.layer as? AVPlayerLayer else {
            return
        }
        layer.player = LocalMusicPlayer.sharedPlayer.currentVideoPlayer()
    }
    
}
