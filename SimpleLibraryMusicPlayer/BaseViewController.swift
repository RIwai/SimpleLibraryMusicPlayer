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
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        NSNotificationCenter.addObserver(self, selector: "showPlayer", event: .ShowPlayer, object: nil)
        NSNotificationCenter.addObserver(self, selector: "playbackStatusDidChange", event: .LocalMusicStarted, object: nil)
        NSNotificationCenter.addObserver(self, selector: "playbackStatusDidChange", event: .LocalMusicPaused, object: nil)
        NSNotificationCenter.addObserver(self, selector: "playingItemDidChange", event: .LocalMusicTrackDidChange, object: nil)
        
        if LocalMusicPlayer.sharedPlayer.currentTrack() != nil {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: PlayerButtonView.loadFromNib())
        } else {
            self.navigationItem.rightBarButtonItems = nil
        }
        
        self.updateCells()
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        NSNotificationCenter.removeObserver(self, event: .ShowPlayer, object: nil)
        NSNotificationCenter.removeObserver(self, event: .LocalMusicStarted, object: nil)
        NSNotificationCenter.removeObserver(self, event: .LocalMusicPaused, object: nil)
        NSNotificationCenter.removeObserver(self, event: .LocalMusicTrackDidChange, object: nil)
    }
    
    // MARK: - Internal method
    func updateCells() {
        // For override
    }
    
    // MARK: - Notification handler
    func showPlayer() {
        let playerViewController = PlayerViewController(nibName: "PlayerViewController", bundle:nil)

        if let topViewController = self.navigationController?.topViewController {
            topViewController.presentViewController(playerViewController,
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
