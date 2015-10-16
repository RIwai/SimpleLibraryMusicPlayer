//
//  TracksViewController.swift
//  SimpleLibraryMusicPlayer
//
//  Created by Ryota Iwai on 2015/08/26.
//  Copyright (c) 2015年 Ryota Iwai. All rights reserved.
//

import UIKit
import MediaPlayer

class TracksViewController: BaseViewController {

    // MARK: - Internal property
    var collection: MPMediaItemCollection?
    var playlist: MPMediaPlaylist?
    var sourceType: LocalTrackSouceType = .Unkown

    // MARK: - Outlet property
    @IBOutlet weak var tableView: UITableView!

    // MARK: - Override method
    override func updateCells() {
        for cell in self.tableView.visibleCells {
            if let trackCell = cell as? TrackCell {
                if let indexPath = self.tableView.indexPathForCell(trackCell) {
                    if let mediaItem = self.mediaItem(indexPath.row - 1) {
                        if LocalMusicPlayer.sharedPlayer.isCurrentTrack(mediaItem) {
                            trackCell.contentView.backgroundColor = UIColor(red: 1, green: 0, blue: 0, alpha: 0.2)
                        } else {
                            trackCell.contentView.backgroundColor = UIColor.clearColor()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Private method
    private func currentCollection() -> MPMediaItemCollection? {
        return self.collection != nil ? self.collection : self.playlist
    }
    
    private func mediaItem(index: Int) -> MPMediaItem? {
        if let correction = self.currentCollection() {
            if correction.items.count > index {
                return correction.items[index]
            }
        }
        return nil
    }
}

// MARK: - UITableViewDataSource
extension TracksViewController: UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let correction = self.currentCollection() {
            return correction.count + 1
        }
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            return self.tableView.dequeueReusableCellWithIdentifier("TrackPlayAllCell", forIndexPath: indexPath) as! TrackPlayAllCell
        }
        
        let trackCell = self.tableView.dequeueReusableCellWithIdentifier("TrackCell", forIndexPath: indexPath) as! TrackCell
        if let mediaItem = self.mediaItem(indexPath.row - 1) {
            
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
            
            if LocalMusicPlayer.sharedPlayer.isCurrentTrack(mediaItem){
                trackCell.contentView.backgroundColor = UIColor(red: 1, green: 0, blue: 0, alpha: 0.2)
            } else {
                trackCell.contentView.backgroundColor = UIColor.clearColor()
            }
        }
    
        if trackCell.cloudImageView.hidden == false || trackCell.drmLabel.hidden == false {
           trackCell.contentView.alpha = 0.5
        } else {
            trackCell.contentView.alpha = 1.0
        }
        
        return trackCell
    }
}

// MARK: - UITableViewDelegate
extension TracksViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        let selectedIndex = indexPath.row - 1
        if self.sourceType == .Playlist {
            if let playlist = self.playlist {
                if !LocalMusicPlayer.sharedPlayer.playWithPlaylist(playlist, selectTrackIndex: selectedIndex) {
                    return
                }
            }
        } else {
            if let correction = self.currentCollection() {
                if !LocalMusicPlayer.sharedPlayer.playWithCollection(correction, selectTrackIndex: selectedIndex, type: self.sourceType) {
                    return
                }
            }
        }
        self.presentViewController(PlayerViewController(nibName: "PlayerViewController", bundle:nil),
            animated: true,
            completion: nil)
   }
}