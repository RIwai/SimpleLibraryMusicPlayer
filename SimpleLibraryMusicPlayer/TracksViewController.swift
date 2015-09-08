//
//  TracksViewController.swift
//  SimpleLibraryMusicPlayer
//
//  Created by Ryota Iwai on 2015/08/26.
//  Copyright (c) 2015年 Ryota Iwai. All rights reserved.
//

import UIKit
import MediaPlayer

class TracksViewController: UIViewController {

    // MARK: - Internal property
    var tracks: [MPMediaItem] = []

    // MARK: - Outlet property
    @IBOutlet weak var tableView: UITableView!

}

// MARK: - UITableViewDataSource
extension TracksViewController: UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tracks.count + 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            return self.tableView.dequeueReusableCellWithIdentifier("TrackPlayAllCell", forIndexPath: indexPath) as! TrackPlayAllCell
        }
        
        let mediaItem = self.tracks[indexPath.row - 1]
        let trackCell = self.tableView.dequeueReusableCellWithIdentifier("TrackCell", forIndexPath: indexPath) as! TrackCell
        
        trackCell.trackTitle.text = mediaItem.title
        trackCell.artistNameAlbumNameLabel.text = (mediaItem.artist ?? "-") + " | " + (mediaItem.albumTitle ?? "-")
        trackCell.timeLabel.text = Util.timeString(mediaItem.playbackDuration)
        if let artwork = mediaItem.artwork {
            let scale = UIScreen.mainScreen().scale
            trackCell.artworkImageView.image = artwork.imageWithSize(CGSizeMake(80 * scale, 80 * scale))
        } else {
            trackCell.artworkImageView.image = nil
        }
        
        if mediaItem.cloudItem {
            trackCell.cloudImageView.hidden = false
            trackCell.drmLabel.hidden = true
        } else {
            trackCell.cloudImageView.hidden = true
            if mediaItem.assetURL == nil {
                trackCell.drmLabel.hidden = false
            } else {
                trackCell.drmLabel.hidden = true
            }
        }
        
        return trackCell
    }
}

// MARK: - UITableViewDelegate
extension TracksViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        let playerViewController = PlayerViewController(nibName: "PlayerViewController", bundle:nil)
        if indexPath.row == 0 {
            playerViewController.mediaItems = self.tracks
        } else {
            playerViewController.mediaItems = [self.tracks[indexPath.row - 1]]
        }
        self.presentViewController(playerViewController, animated: true, completion: nil)
   }
}