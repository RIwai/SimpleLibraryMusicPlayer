//
//  SelectViewController.swift
//  SimpleLibraryMusicPlayer
//
//  Created by Ryota Iwai on 2015/08/26.
//  Copyright (c) 2015年 Ryota Iwai. All rights reserved.
//

import UIKit
import MediaPlayer

// MARK: - TableView Section's enum
enum SelectType: Int {
    case Playlist = 0
    case Album
    case Artist
    case Track
    static let Count = SelectType.Track.rawValue + 1
    var title: String {
        get {
            switch self {
            case .Playlist:
                return "Playlists"
            case .Album:
                return "Albums"
            case .Artist:
                return "Artists"
            case .Track:
                return "Tracks"
            }
        }
    }

    var transitionsViewController: UIViewController? {
        get {
            switch self {
            case .Playlist:
                return UIStoryboard(name: "PlaylistsViewController", bundle: nil).instantiateInitialViewController()
            case .Album:
                return UIStoryboard(name: "AlbumsViewController", bundle: nil).instantiateInitialViewController()
            case .Artist:
                return UIStoryboard(name: "ArtistViewController", bundle: nil).instantiateInitialViewController()
            case .Track:
                if let tracksViewController = UIStoryboard(name: "TracksViewController", bundle: nil).instantiateInitialViewController() as? TracksViewController {
                    let query = MPMediaQuery.songs()
                    // Only Media type music
                    query.addFilterPredicate(MPMediaPropertyPredicate(value: MPMediaType.music.rawValue, forProperty: MPMediaItemPropertyMediaType))
                    // Include iCloud item
                    query.addFilterPredicate(MPMediaPropertyPredicate(value: NSNumber(value: false), forProperty: MPMediaItemPropertyIsCloudItem))
                    tracksViewController.collection = MPMediaItemCollection(items: query.items ?? [])
                    tracksViewController.sourceType = .Track
                    
                    return tracksViewController as UIViewController
                }
                return nil
            }
        }
    }
}

// MARK: -
class SelectViewController: BaseViewController {
    
    // MARK: - Outlet property
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Override methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Local Music Library"
    }
}

// MARK: - UITableViewDataSource
extension SelectViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return SelectType.Count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "NormalCell", for: indexPath)
        
        cell.textLabel?.text = SelectType(rawValue: indexPath.row)?.title ?? ""
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension SelectViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath as IndexPath, animated: true)
        
        if let viewController = SelectType(rawValue: indexPath.row)?.transitionsViewController {
            viewController.title = SelectType(rawValue: indexPath.row)?.title ?? ""
            self.navigationController?.pushViewController(viewController, animated: true)
        }
    }
}
