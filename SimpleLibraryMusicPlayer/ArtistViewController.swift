//
//  ArtistViewController.swift
//  SimpleLibraryMusicPlayer
//
//  Created by Ryota Iwai on 2015/08/26.
//  Copyright (c) 2015年 Ryota Iwai. All rights reserved.
//

import UIKit
import MediaPlayer

class ArtistViewController: BaseViewController {
    
    // MARK: - Outlet property
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Private property
    fileprivate var artists: [MPMediaItemCollection] = []
    
    // MARK: - Override methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load artists
        let query = MPMediaQuery.artists()
        // Only Media type music
        query.addFilterPredicate(MPMediaPropertyPredicate(value: MPMediaType.music.rawValue, forProperty: MPMediaItemPropertyMediaType))
        // Include iCloud item
        query.addFilterPredicate(MPMediaPropertyPredicate(value: NSNumber(value: false), forProperty: MPMediaItemPropertyIsCloudItem))

        if let collections = query.collections {
            self.artists = collections
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.updateCells()
    }
    
    override func updateCells() {
        for cell in self.tableView.visibleCells {
            if let artistCell = cell as? ArtistCell {
                if let indexPath = self.tableView.indexPath(for: artistCell) {
                    let artist = self.artists[indexPath.row]
                    if LocalMusicPlayer.sharedPlayer.isCurrentCollection(collection: artist) {
                        artistCell.contentView.backgroundColor = UIColor(red: 1, green: 0, blue: 0, alpha: 0.2)
                    } else {
                        artistCell.contentView.backgroundColor = UIColor.clear
                    }
                }
            }
        }
    }
}

// MARK: - UITableViewDataSource
extension ArtistViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.artists.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let artist = self.artists[indexPath.row]
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "ArtistCell", for: indexPath) as! ArtistCell
        
        if let representativeItem = artist.representativeItem {
            cell.artistNameLabel.text = representativeItem.artist
        }
        cell.trackCountLabel.text = "  \(artist.count) track(s)"
        
        if LocalMusicPlayer.sharedPlayer.isCurrentCollection(collection: artist) {
            cell.contentView.backgroundColor = UIColor(red: 1, green: 0, blue: 0, alpha: 0.2)
        } else {
            cell.contentView.backgroundColor = UIColor.clear
        }

        return cell
    }
}

// MARK: - UITableViewDelegate
extension ArtistViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath as IndexPath, animated: true)
        
        if let tracksViewController = UIStoryboard(name: "TracksViewController", bundle: nil).instantiateInitialViewController() as? TracksViewController {
            tracksViewController.collection = self.artists[indexPath.row]
            tracksViewController.sourceType = .Artist
            if let representativeItem = self.artists[indexPath.row].representativeItem {
                tracksViewController.title = representativeItem.artist
            }
            self.navigationController?.pushViewController(tracksViewController, animated: true)
        }
    }
}
