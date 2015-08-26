//
//  ArtistViewController.swift
//  SimpleLibraryMusicPlayer
//
//  Created by Ryota Iwai on 2015/08/26.
//  Copyright (c) 2015年 Ryota Iwai. All rights reserved.
//

import UIKit
import MediaPlayer

class ArtistViewController: UIViewController {
    
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
        query.addFilterPredicate(MPMediaPropertyPredicate(value: NSNumber(bool: true), forProperty: MPMediaItemPropertyIsCloudItem))
        self.artists = query.collections as? [MPMediaItemCollection] ?? []
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
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension ArtistViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        if let tracksViewController = UIStoryboard(name: "TracksViewController", bundle: nil).instantiateInitialViewController() as? TracksViewController {
            if let items = self.artists[indexPath.row].items as? [MPMediaItem] {
                tracksViewController.tracks = items
                tracksViewController.title = self.artists[indexPath.row].representativeItem.artist
                self.navigationController?.pushViewController(tracksViewController, animated: true)
            }
        }
    }
}