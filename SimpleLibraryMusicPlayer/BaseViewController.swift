//
//  BaseViewController.swift
//  SimpleLibraryMusicPlayer
//
//  Created by Ryota Iwai on 2015/09/15.
//  Copyright (c) 2015年 Ryota Iwai. All rights reserved.
//

import UIKit

class BaseViewController: UIViewController {

    // MARK: - Override method
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.addObserver(observer: self, selector: #selector(BaseViewController.showPlayer), event: .showPlayer, object: nil)
        NotificationCenter.addObserver(observer: self, selector: #selector(BaseViewController.playbackStatusDidChange), event: .localMusicStarted, object: nil)
        NotificationCenter.addObserver(observer: self, selector: #selector(BaseViewController.playbackStatusDidChange), event: .localMusicPaused, object: nil)
        NotificationCenter.addObserver(observer: self, selector: #selector(BaseViewController.playingItemDidChange), event: .localMusicTrackDidChange, object: nil)
        
        if LocalMusicPlayer.sharedPlayer.currentTrack() != nil {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: PlayerButtonView.loadFromNib())
        } else {
            self.navigationItem.rightBarButtonItems = nil
        }
        
        self.updateCells()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        NotificationCenter.removeObserver(observer: self, event: .showPlayer, object: nil)
        NotificationCenter.removeObserver(observer: self, event: .localMusicStarted, object: nil)
        NotificationCenter.removeObserver(observer: self, event: .localMusicPaused, object: nil)
        NotificationCenter.removeObserver(observer: self, event: .localMusicTrackDidChange, object: nil)
    }
    
    // MARK: - Internal method
    func updateCells() {
        // For override
    }
    
    // MARK: - Notification handler
    func showPlayer() {
        let playerViewController = PlayerViewController(nibName: "PlayerViewController", bundle:nil)

        if let topViewController = self.navigationController?.topViewController {
            topViewController.present(playerViewController,
                animated: true,
                completion: nil)
        }
    }

    func playbackStatusDidChange() {
        self.updateCells()
    }

    func playingItemDidChange() {
        self.updateCells()
    }
}
