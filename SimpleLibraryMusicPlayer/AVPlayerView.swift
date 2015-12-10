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
    
    // MARK: Initialize
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
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

    // MARK: Play Video
    func setPlayer(avplayer: AVPlayer) {
        let layer = self.layer as! AVPlayerLayer
        layer.videoGravity = AVLayerVideoGravityResizeAspect
        layer.player = avplayer
    }
}
