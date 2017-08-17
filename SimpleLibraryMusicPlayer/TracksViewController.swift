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
                if let indexPath = self.tableView.indexPath(for: trackCell) {
                    if let mediaItem = self.mediaItem(index: indexPath.row - 1) {
                        if LocalMusicPlayer.sharedPlayer.isCurrentTrack(track: mediaItem) {
                            trackCell.contentView.backgroundColor = UIColor(red: 1, green: 0, blue: 0, alpha: 0.2)
                        } else {
                            trackCell.contentView.backgroundColor = UIColor.clear
                        }
                    }
                }
            }
        }
    }

    // MARK: - Private method
    fileprivate func currentCollection() -> MPMediaItemCollection? {
        return self.collection != nil ? self.collection : self.playlist
    }
    
    fileprivate func mediaItem(index: Int) -> MPMediaItem? {
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let correction = self.currentCollection() {
            return correction.count + 1
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            return self.tableView.dequeueReusableCell(withIdentifier: "TrackPlayAllCell", for: indexPath) as! TrackPlayAllCell
        }
        
        let trackCell = self.tableView.dequeueReusableCell(withIdentifier: "TrackCell", for: indexPath) as! TrackCell
        if let mediaItem = self.mediaItem(index: indexPath.row - 1) {
            
            trackCell.trackTitle.text = mediaItem.title
            trackCell.artistNameAlbumNameLabel.text = (mediaItem.artist ?? "-") + " | " + (mediaItem.albumTitle ?? "-")
            trackCell.timeLabel.text = Util.timeString(secondTimes: mediaItem.playbackDuration)
            if let artwork = mediaItem.artwork {
                let scale = UIScreen.main.scale
                trackCell.artworkImageView.image = artwork.image(at: CGSize(width: 80 * scale, height: 80 * scale))
            } else {
                trackCell.artworkImageView.image = nil
            }
            
            if mediaItem.isCloudItem {
                trackCell.cloudImageView.isHidden = false
                trackCell.drmLabel.isHidden = true
            } else {
                trackCell.cloudImageView.isHidden = true
                if mediaItem.assetURL == nil {
                    trackCell.drmLabel.isHidden = false
                } else {
                    trackCell.drmLabel.isHidden = true
                }
            }
            
            if LocalMusicPlayer.sharedPlayer.isCurrentTrack(track: mediaItem){
                trackCell.contentView.backgroundColor = UIColor(red: 1, green: 0, blue: 0, alpha: 0.2)
            } else {
                trackCell.contentView.backgroundColor = UIColor.clear
            }
        }
    
        if trackCell.cloudImageView.isHidden == false || trackCell.drmLabel.isHidden == false {
           trackCell.contentView.alpha = 0.5
        } else {
            trackCell.contentView.alpha = 1.0
        }
        
        return trackCell
    }
}

// MARK: - UITableViewDelegate
extension TracksViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath as IndexPath, animated: true)
        
        let selectedIndex = indexPath.row - 1
        if self.sourceType == .Playlist {
            if let playlist = self.playlist {
                if !LocalMusicPlayer.sharedPlayer.playWithPlaylist(playlist: playlist, selectTrackIndex: selectedIndex) {
                    return
                }
            }
        } else {
            if let correction = self.currentCollection() {
                if !LocalMusicPlayer.sharedPlayer.playWithCollection(collection: correction, selectTrackIndex: selectedIndex, type: self.sourceType) {
                    return
                }
            }
        }
        self.present(PlayerViewController(nibName: "PlayerViewController", bundle:nil),
            animated: true,
            completion: nil)
   }
}
