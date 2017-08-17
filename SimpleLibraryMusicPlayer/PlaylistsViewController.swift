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
    fileprivate var playlists: [MPMediaPlaylist] = []
    
    // MARK: - Override methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load playlists
        let query = MPMediaQuery.playlists()
        // Only Media type music
        query.addFilterPredicate(MPMediaPropertyPredicate(value: MPMediaType.music.rawValue, forProperty: MPMediaItemPropertyMediaType))
        // Include iCloud item
        query.addFilterPredicate(MPMediaPropertyPredicate(value: NSNumber(value: false), forProperty: MPMediaItemPropertyIsCloudItem))
        self.playlists = query.collections as? [MPMediaPlaylist] ?? []
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.updateCells()
    }

    override func updateCells() {
        for cell in self.tableView.visibleCells {
            if let playlistCell = cell as? PlaylistCell {
                if let indexPath = self.tableView.indexPath(for: playlistCell) {
                    let playlist = self.playlists[indexPath.row]
                    if LocalMusicPlayer.sharedPlayer.isCurrentCollection(collection: playlist) {
                        playlistCell.contentView.backgroundColor = UIColor(red: 1, green: 0, blue: 0, alpha: 0.2)
                    } else {
                        playlistCell.contentView.backgroundColor = UIColor.clear
                    }
                }
            }
        }
    }
}

// MARK: - UITableViewDataSource
extension PlaylistsViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.playlists.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let playlist = self.playlists[indexPath.row]
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "PlaylistCell", for: indexPath) as! PlaylistCell
        
        cell.titleLabel.text = playlist.name
        cell.descriptionLabel.text = "  \(playlist.items.count) track(s)"
        
        if LocalMusicPlayer.sharedPlayer.isCurrentCollection(collection: playlist) {
            cell.contentView.backgroundColor = UIColor(red: 1, green: 0, blue: 0, alpha: 0.2)
        } else {
            cell.contentView.backgroundColor = UIColor.clear
        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension PlaylistsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath as IndexPath, animated: true)
        
        if let tracksViewController = UIStoryboard(name: "TracksViewController", bundle: nil).instantiateInitialViewController() as? TracksViewController {
            let playlist = self.playlists[indexPath.row]
            tracksViewController.playlist = playlist
            tracksViewController.sourceType = .Playlist
            tracksViewController.title = self.playlists[indexPath.row].name
            self.navigationController?.pushViewController(tracksViewController, animated: true)
        }
    }
}
