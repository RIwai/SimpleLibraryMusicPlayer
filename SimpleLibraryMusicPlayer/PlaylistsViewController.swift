//
//  PlaylistsViewController.swift
//  SimpleLibraryMusicPlayer
//
//  Created by Ryota Iwai on 2015/08/26.
//  Copyright (c) 2015年 Ryota Iwai. All rights reserved.
//

import UIKit
import MediaPlayer

class PlaylistsViewController: BaseViewController {
    
    // MARK: - Outlet property
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Private property
    private var playlists: [MPMediaPlaylist] = []
    
    // MARK: - Override methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load playlists
        let query = MPMediaQuery.playlistsQuery()
        // Only Media type music
        query.addFilterPredicate(MPMediaPropertyPredicate(value: MPMediaType.Music.rawValue, forProperty: MPMediaItemPropertyMediaType))
        // Include iCloud item
        query.addFilterPredicate(MPMediaPropertyPredicate(value: NSNumber(bool: false), forProperty: MPMediaItemPropertyIsCloudItem))
        self.playlists = query.collections as? [MPMediaPlaylist] ?? []
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.updateCells()
    }

    override func updateCells() {
        for cell in self.tableView.visibleCells() {
            if let playlistCell = cell as? PlaylistCell {
                if let indexPath = self.tableView.indexPathForCell(playlistCell) {
                    let playlist = self.playlists[indexPath.row]
                    if LocalMusicPlayer.sharedPlayer.isCurrentCollection(playlist) {
                        playlistCell.contentView.backgroundColor = UIColor(red: 1, green: 0, blue: 0, alpha: 0.2)
                    } else {
                        playlistCell.contentView.backgroundColor = UIColor.clearColor()
                    }
                }
            }
        }
    }
}

// MARK: - UITableViewDataSource
extension PlaylistsViewController: UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.playlists.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let playlist = self.playlists[indexPath.row]
        let cell = self.tableView.dequeueReusableCellWithIdentifier("PlaylistCell", forIndexPath: indexPath) as! PlaylistCell
        
        cell.titleLabel.text = playlist.name
        cell.descriptionLabel.text = "  \(playlist.items.count) track(s)"
        
        if LocalMusicPlayer.sharedPlayer.isCurrentCollection(playlist) {
            cell.contentView.backgroundColor = UIColor(red: 1, green: 0, blue: 0, alpha: 0.2)
        } else {
            cell.contentView.backgroundColor = UIColor.clearColor()
        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension PlaylistsViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        if let tracksViewController = UIStoryboard(name: "TracksViewController", bundle: nil).instantiateInitialViewController() as? TracksViewController {
            let playlist = self.playlists[indexPath.row]
            tracksViewController.playlist = playlist
            tracksViewController.sourceType = .Playlist
            tracksViewController.title = self.playlists[indexPath.row].name
            self.navigationController?.pushViewController(tracksViewController, animated: true)
        }
    }
}