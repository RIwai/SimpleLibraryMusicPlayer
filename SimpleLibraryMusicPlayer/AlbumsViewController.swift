//
//  AlbumsViewController.swift
//  SimpleLibraryMusicPlayer
//
//  Created by Ryota Iwai on 2015/08/26.
//  Copyright (c) 2015年 Ryota Iwai. All rights reserved.
//

import UIKit
import MediaPlayer

class AlbumsViewController: UIViewController {
    
    // MARK: - Outlet property
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Private property
    private var albums: [MPMediaItemCollection] = []
    
    // MARK: - Override methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load albums
        let query = MPMediaQuery.albumsQuery()
        // Only Media type music
        query.addFilterPredicate(MPMediaPropertyPredicate(value: MPMediaType.Music.rawValue, forProperty: MPMediaItemPropertyMediaType))
        // Include iCloud item
        query.addFilterPredicate(MPMediaPropertyPredicate(value: NSNumber(bool: true), forProperty: MPMediaItemPropertyIsCloudItem))
        self.albums = query.collections as? [MPMediaItemCollection] ?? []
    }
    
}

// MARK: - UITableViewDataSource
extension AlbumsViewController: UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.albums.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let album = self.albums[indexPath.row]
        let cell = self.tableView.dequeueReusableCellWithIdentifier("AlbumCell", forIndexPath: indexPath) as! AlbumCell
        
        cell.albumTitleLabel.text = album.representativeItem.albumTitle
        cell.artistNameLabel.text = album.representativeItem.artist
        cell.trackCountLabel.text = "  \(album.count) track(s)"
        if let artwork = album.representativeItem.artwork {
            let scale = UIScreen.mainScreen().scale
            cell.artworkImageView.image = artwork.imageWithSize(CGSizeMake(80 * scale, 80 * scale))
        } else {
            cell.artworkImageView.image = nil
        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension AlbumsViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        if let tracksViewController = UIStoryboard(name: "TracksViewController", bundle: nil).instantiateInitialViewController() as? TracksViewController {
            if let items = self.albums[indexPath.row].items as? [MPMediaItem] {
                tracksViewController.tracks = items
                tracksViewController.title = self.albums[indexPath.row].representativeItem.albumTitle
                self.navigationController?.pushViewController(tracksViewController, animated: true)
            }
        }
    }
}