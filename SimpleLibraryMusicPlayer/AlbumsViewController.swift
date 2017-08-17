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
    fileprivate var albums: [MPMediaItemCollection] = []
    
    // MARK: - Override methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load albums
        let query = MPMediaQuery.albums()
        // Only Media type music
        query.addFilterPredicate(MPMediaPropertyPredicate(value: MPMediaType.music.rawValue, forProperty: MPMediaItemPropertyMediaType))
        // Include iCloud item
        query.addFilterPredicate(MPMediaPropertyPredicate(value: NSNumber(value: false), forProperty: MPMediaItemPropertyIsCloudItem))
        if let collections = query.collections {
            self.albums = collections
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.updateCells()
    }
    
    override func updateCells() {
        for cell in self.tableView.visibleCells {
            if let albumCell = cell as? AlbumCell {
                if let indexPath = self.tableView.indexPath(for: albumCell) {
                    let album = self.albums[indexPath.row]
                    if LocalMusicPlayer.sharedPlayer.isCurrentCollection(collection: album) {
                        albumCell.contentView.backgroundColor = UIColor(red: 1, green: 0, blue: 0, alpha: 0.2)
                    } else {
                        albumCell.contentView.backgroundColor = UIColor.clear
                    }
                }
            }
        }
    }
}

// MARK: - UITableViewDataSource
extension AlbumsViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.albums.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let album = self.albums[indexPath.row]
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "AlbumCell", for: indexPath) as! AlbumCell
        
        cell.trackCountLabel.text = "  \(album.count) track(s)"
        if let representativeItem = album.representativeItem {
            cell.albumTitleLabel.text = representativeItem.albumTitle
            cell.artistNameLabel.text = representativeItem.artist
            if let artwork = representativeItem.artwork {
                let scale = UIScreen.main.scale
                cell.artworkImageView.image = artwork.image(at: CGSize(width: 80 * scale, height: 80 * scale))
            } else {
                cell.artworkImageView.image = nil
            }
        }

        if LocalMusicPlayer.sharedPlayer.isCurrentCollection(collection: album) {
            cell.contentView.backgroundColor = UIColor(red: 1, green: 0, blue: 0, alpha: 0.2)
        } else {
            cell.contentView.backgroundColor = UIColor.clear
        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension AlbumsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
        
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
