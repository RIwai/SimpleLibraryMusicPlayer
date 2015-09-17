//
//  PlayerButtonView.swift
//  SimpleLibraryMusicPlayer
//
//  Created by Ryota Iwai on 2015/09/15.
//  Copyright (c) 2015年 Ryota Iwai. All rights reserved.
//

import UIKit

class PlayerButtonView: UIView {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var button: UIButton!
    
    private var onImagesArray: [UIImage] = []

    // MARK: - Class method
    class func loadFromNib() -> PlayerButtonView {
        return UINib(nibName: "PlayerButtonView", bundle: nil).instantiateWithOwner(nil, options: nil).first as! PlayerButtonView
    }

    // MARK: - deinit
    deinit {
        NSNotificationCenter.removeObserver(self, event: .LocalMusicStarted, object: nil)
        NSNotificationCenter.removeObserver(self, event: .LocalMusicPaused, object: nil)
    }
    
    // MARK: - Override method
    override func awakeFromNib() {
        super.awakeFromNib()
        
        NSNotificationCenter.addObserver(self, selector: "playbackStatusDidChange", event: .LocalMusicStarted, object: nil)
        NSNotificationCenter.addObserver(self, selector: "playbackStatusDidChange", event: .LocalMusicPaused, object: nil)

        self.onImagesArray.append(UIImage(named: "on1")!)
        self.onImagesArray.append(UIImage(named: "on2")!)
        self.onImagesArray.append(UIImage(named: "on3")!)
        self.onImagesArray.append(UIImage(named: "on4")!)
        
        self.toggleButtonImage()
    }

    // MARK: - Notification handler
    func playbackStatusDidChange() {
        self.toggleButtonImage()
    }
    
    // MARK: - Private method
    private func toggleButtonImage() {
        if LocalMusicPlayer.sharedPlayer.isPlaying {
            if !self.imageView.isAnimating() {
                self.imageView.image = nil
                self.imageView.animationImages = self.onImagesArray
                self.imageView.animationDuration = 2
                self.imageView.startAnimating()
            }
        } else {
            if self.imageView.isAnimating() {
                self.imageView.stopAnimating()
            }
            self.imageView.image = UIImage(named: "off")
        }
    }
    
    // MARK: - Action method
    @IBAction func tapButton(sender: AnyObject) {
        NSNotificationCenter.postNotificationEvent(.ShowPlayer, object: nil)
    }
}
