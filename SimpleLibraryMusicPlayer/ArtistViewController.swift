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
    private var artists: [MPMediaItemCollection] = []
    
    // MARK: - Override methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load artists
        let query = MPMediaQuery.artistsQuery()
        // Only Media type music
        query.addFilterPredicate(MPMediaPropertyPredicate(value: MPMediaType.Music.rawValue, forProperty: MPMediaItemPropertyMediaType))
        // Include iCloud item
        query.addFilterPredicate(MPMediaPropertyPredicate(value: NSNumber(bool: false), forProperty: MPMediaItemPropertyIsCloudItem))

        self.artists = query.collections as? [MPMediaItemCollection] ?? []
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.updateCells()
    }
    
    override func updateCells() {
        for cell in self.tableView.visibleCells() {
            if let artistCell = cell as? ArtistCell {
                if let indexPath = self.tableView.indexPathForCell(artistCell) {
                    let artist = self.artists[indexPath.row]
                    if LocalMusicPlayer.sharedPlayer.isCurrentCollection(artist) {
                        artistCell.contentView.backgroundColor = UIColor(red: 1, green: 0, blue: 0, alpha: 0.2)
                    } else {
                        artistCell.contentView.backgroundColor = UIColor.clearColor()
                    }
                }
            }
        }
    }
}

// MARK: - UITableViewDataSource
extension ArtistViewController: UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.artists.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let artist = self.artists[indexPath.row]
        let cell = self.tableView.dequeueReusableCellWithIdentifier("ArtistCell", forIndexPath: indexPath) as! ArtistCell
        
        cell.artistNameLabel.text = artist.representativeItem.artist
        cell.trackCountLabel.text = "  \(artist.count) track(s)"
        
        if LocalMusicPlayer.sharedPlayer.isCurrentCollection(artist) {
            cell.contentView.backgroundColor = UIColor(red: 1, green: 0, blue: 0, alpha: 0.2)
        } else {
            cell.contentView.backgroundColor = UIColor.clearColor()
        }

        return cell
    }
}

// MARK: - UITableViewDelegate
extension ArtistViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        if let tracksViewController = UIStoryboard(name: "TracksViewController", bundle: nil).instantiateInitialViewController() as? TracksViewController {
            tracksViewController.collection = self.artists[indexPath.row]
            tracksViewController.sourceType = .Artist
            tracksViewController.title = self.artists[indexPath.row].representativeItem.artist
            self.navigationController?.pushViewController(tracksViewController, animated: true)
        }
    }
}