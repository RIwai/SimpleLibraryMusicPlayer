//
//  ViewController.swift
//  SimpleLibraryMusicPlayer
//
//  Created by Ryota Iwai on 2015/08/17.
//  Copyright (c) 2015年 Ryota Iwai. All rights reserved.
//

import UIKit
import MediaPlayer

class ViewController: UIViewController {
    
    // MARK: - Outlet property
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var includeiCloudTracksSwitch: UISwitch!

    // MARK: Private property
    private var mediaQuery: MPMediaQuery? = nil
    private let includeiCloudTracksKey = "includeiCloudTracks"

    // MARK: - Override methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set value
        self.includeiCloudTracksSwitch.setOn(NSUserDefaults.standardUserDefaults().boolForKey(self.includeiCloudTracksKey), animated: true)
        
        // Get Media
        self.updateMediaQuery()
        
        // Set top inset
        self.tableView.contentInset.top = 64
    }

    // MARK:
    @IBAction func includeiCloudSwitchValueChanged(sender: AnyObject) {
        self.updateMediaQuery()
        
        NSUserDefaults.standardUserDefaults().setBool(self.includeiCloudTracksSwitch.on, forKey: self.includeiCloudTracksKey)
        NSUserDefaults.standardUserDefaults().synchronize()
    }

    
    // MARK: Private methods
    private func updateMediaQuery() {
        if self.includeiCloudTracksSwitch.on {
            self.mediaQuery = MPMediaQuery()
            // Only Media type music
            self.mediaQuery?.addFilterPredicate(MPMediaPropertyPredicate(value: MPMediaType.Music.rawValue, forProperty: MPMediaItemPropertyMediaType))
            // Include iCloud item
            self.mediaQuery?.addFilterPredicate(MPMediaPropertyPredicate(value: NSNumber(bool: true), forProperty: MPMediaItemPropertyIsCloudItem))
        } else {
            self.mediaQuery = MPMediaQuery()
            // Only Media type music
            self.mediaQuery?.addFilterPredicate(MPMediaPropertyPredicate(value: MPMediaType.Music.rawValue, forProperty: MPMediaItemPropertyMediaType))
            // Exclude iCloud item
            self.mediaQuery?.addFilterPredicate(MPMediaPropertyPredicate(value: NSNumber(bool: false), forProperty: MPMediaItemPropertyIsCloudItem))
        }
        
        self.tableView.reloadData()
    }
    
    private func mediaItemWithIndex(index: Int) -> MPMediaItem? {
        if let items = self.mediaQuery?.items {
            if items.count > index {
               return items[index] as? MPMediaItem
            }
            return nil
        }
        
        return nil
    }
    
}

// MARK: - UITableViewDataSource
extension ViewController: UITableViewDataSource {

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let items = self.mediaQuery?.items {
            return items.count
        }
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let trackCell = self.tableView.dequeueReusableCellWithIdentifier("TrackCell", forIndexPath: indexPath) as! TrackCell
        
        if let mediaItem = self.mediaItemWithIndex(indexPath.row) {
            trackCell.trackTitle.text = mediaItem.title
            trackCell.artistNameAlbumNameLabel.text = (mediaItem.artist ?? "-") + " | " + (mediaItem.albumTitle ?? "-")
            trackCell.timeLabel.text = Util.timeString(mediaItem.playbackDuration)
            if let artwork = mediaItem.artwork {
                let scale = UIScreen.mainScreen().scale
                trackCell.artworkImageView.image = artwork.imageWithSize(CGSizeMake(80 * scale, 80 * scale))
            } else {
                trackCell.artworkImageView.image = nil
            }
        } else {
            trackCell.trackTitle.text = "-"
            trackCell.artistNameAlbumNameLabel.text = "-"
            trackCell.timeLabel.text = "-:-"
            trackCell.artworkImageView.image = nil
        }
        
        return trackCell
    }
}

// MARK: - UITableViewDelegate
extension ViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        if let mediaItem = self.mediaItemWithIndex(indexPath.row) {
            let playerViewController = PlayerViewController(nibName: "PlayerViewController", bundle:nil)
            playerViewController.mediaItem = mediaItem
            self.presentViewController(playerViewController, animated: true, completion: nil)
        }
        
    }
}
