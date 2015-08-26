//
//  PlaylistsViewController.swift
//  SimpleLibraryMusicPlayer
//
//  Created by Ryota Iwai on 2015/08/26.
//  Copyright (c) 2015年 Ryota Iwai. All rights reserved.
//

import UIKit
import MediaPlayer

class PlaylistsViewController: UIViewController {
    
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
        query.addFilterPredicate(MPMediaPropertyPredicate(value: NSNumber(bool: true), forProperty: MPMediaItemPropertyIsCloudItem))
        self.playlists = query.collections as? [MPMediaPlaylist] ?? []
    }
}

// MARK: - UITableViewDataSource
extension PlaylistsViewController: UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.playlists.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let playList = self.playlists[indexPath.row]
        let cell = self.tableView.dequeueReusableCellWithIdentifier("PlaylistCell", forIndexPath: indexPath) as! PlaylistCell
        
        cell.titleLabel.text = playList.name
        cell.descriptionLabel.text = "  \(playList.items.count) track(s)"
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension PlaylistsViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        if let tracksViewController = UIStoryboard(name: "TracksViewController", bundle: nil).instantiateInitialViewController() as? TracksViewController {
            if let items = self.playlists[indexPath.row].items as? [MPMediaItem] {
                tracksViewController.tracks = items
                tracksViewController.title = self.playlists[indexPath.row].name
                self.navigationController?.pushViewController(tracksViewController, animated: true)
            }
        }
    }
}