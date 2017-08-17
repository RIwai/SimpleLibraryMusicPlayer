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
        NotificationCenter.removeObserver(observer: self)
    }

    // MARK: Override
    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    
    override func layoutSublayers(of: CALayer) {
        super.layoutSublayers(of: layer)
        
        if layer == self.layer {
            self.layer.frame = self.bounds
        }
    }

    // MARK: Video
    func setPlayer(avplayer: AVPlayer) {
        guard let layer = self.layer as? AVPlayerLayer else {
            return
        }
        layer.videoGravity = AVLayerVideoGravity.resizeAspect
        layer.player = avplayer

        NotificationCenter.addObserver(observer: self, selector: #selector(AVPlayerView.willResignActive), name: NSNotification.Name.UIApplicationWillResignActive.rawValue, object: nil)
        NotificationCenter.addObserver(observer: self, selector: #selector(AVPlayerView.didBecomeActive), name: NSNotification.Name.UIApplicationDidBecomeActive.rawValue, object: nil)
    }

    // MARK: For Background
    @objc func willResignActive(notification: NSNotification) {
        guard let layer = self.layer as? AVPlayerLayer else {
            return
        }
        layer.player = nil
    }

    @objc func didBecomeActive(notification: NSNotification) {
        guard let layer = self.layer as? AVPlayerLayer else {
            return
        }
        layer.player = LocalMusicPlayer.sharedPlayer.currentVideoPlayer()
    }
    
}
