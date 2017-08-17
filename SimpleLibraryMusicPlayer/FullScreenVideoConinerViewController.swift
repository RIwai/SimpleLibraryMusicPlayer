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
    
    private var timer: Timer?

    // MARK: - Override methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UIApplication.shared.setStatusBarHidden(true, with: .fade)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.setVideoControllerHiddenTimer()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if self.timer != nil {
            self.timer?.invalidate()
            self.timer = nil
        }
    }
    
    // MARK: - Internal method
    func setVideoView(avPlayerView: AVPlayerView) {
        avPlayerView.frame = CGRect(origin: CGPoint.zero, size: self.view.frame.size)
        avPlayerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.addSubview(avPlayerView)
        self.view.bringSubview(toFront: self.videoControllerView)
        
        avPlayerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(FullScreenVideoConinerViewController.tapVideoView)))

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

    @objc func tapVideoView() {
        let alpha: CGFloat = self.videoControllerView.alpha == 1 ? 0 : 1
        UIView.animate(withDuration: 0.25) { () -> Void in
            self.videoControllerView.alpha = alpha
        }
        if alpha == 1 {
            self.setVideoControllerHiddenTimer()
        }
    }

    @objc func videoControllerHidden() {
        if self.videoControllerView.alpha == 0 {
            return
        }
        UIView.animate(withDuration: 0.25) { () -> Void in
            self.videoControllerView.alpha = 0
        }
    }
    
    // MARK: - IBAction
    @IBAction func tapCloseFullScreenView(sender: AnyObject) {
        
        if self.videoControllerView.alpha != 0 {
            self.tapVideoView()
        }
        
        self.delegate?.closeFullScreen(fullScreenVideoConinerViewController: self)
    }
    
    // MARK: - Private
    private func setVideoControllerHiddenTimer() {
        if self.timer != nil {
           self.timer?.invalidate()
        }
        
        self.timer = Timer(timeInterval: 5,
            target: self,
            selector: #selector(FullScreenVideoConinerViewController.videoControllerHidden),
            userInfo: nil,
            repeats: false)
        if let timer = self.timer {
            RunLoop.main.add(timer, forMode:RunLoopMode.commonModes)
        }
    }
}
