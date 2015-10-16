//
//  AlbumsViewController.swift
//  SimpleLibraryMusicPlayer
//
//  Created by Ryota Iwai on 2015/08/26.
//  Copyright (c) 2015年 Ryota Iwai. All rights reserved.
//

import UIKit
import MediaPlayer

class AlbumsViewController: BaseViewController {
    
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
        query.addFilterPredicate(MPMediaPropertyPredicate(value: NSNumber(bool: false), forProperty: MPMediaItemPropertyIsCloudItem))
        if let collections = query.collections {
            self.albums = collections
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.updateCells()
    }
    
    override func updateCells() {
        for cell in self.tableView.visibleCells {
            if let albumCell = cell as? AlbumCell {
                if let indexPath = self.tableView.indexPathForCell(albumCell) {
                    let album = self.albums[indexPath.row]
                    if LocalMusicPlayer.sharedPlayer.isCurrentCollection(album) {
                        albumCell.contentView.backgroundColor = UIColor(red: 1, green: 0, blue: 0, alpha: 0.2)
                    } else {
                        albumCell.contentView.backgroundColor = UIColor.clearColor()
                    }
                }
            }
        }
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
        
        cell.trackCountLabel.text = "  \(album.count) track(s)"
        if let representativeItem = album.representativeItem {
            cell.albumTitleLabel.text = representativeItem.albumTitle
            cell.artistNameLabel.text = representativeItem.artist
            if let artwork = representativeItem.artwork {
                let scale = UIScreen.mainScreen().scale
                cell.artworkImageView.image = artwork.imageWithSize(CGSizeMake(80 * scale, 80 * scale))
            } else {
                cell.artworkImageView.image = nil
            }
        }

        if LocalMusicPlayer.sharedPlayer.isCurrentCollection(album) {
            cell.contentView.backgroundColor = UIColor(red: 1, green: 0, blue: 0, alpha: 0.2)
        } else {
            cell.contentView.backgroundColor = UIColor.clearColor()
        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension AlbumsViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        if let tracksViewController = UIStoryboard(name: "TracksViewController", bundle: nil).instantiateInitialViewController() as? TracksViewController {
            tracksViewController.collection = self.albums[indexPath.row]
            tracksViewController.sourceType = .Album
            if let representativeItem = self.albums[indexPath.row].representativeItem {
                tracksViewController.title = representativeItem.albumTitle
            }
            self.navigationController?.pushViewController(tracksViewController, animated: true)
        }
    }
}