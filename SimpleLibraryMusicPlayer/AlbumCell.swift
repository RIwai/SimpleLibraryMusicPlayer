//
//  AlbumCell.swift
//  SimpleLibraryMusicPlayer
//
//  Created by Ryota Iwai on 2015/08/26.
//  Copyright (c) 2015年 Ryota Iwai. All rights reserved.
//

import UIKit

class AlbumCell: UITableViewCell {
    
    @IBOutlet weak var artworkImageView: UIImageView!
    @IBOutlet weak var albumTitleLabel: UILabel!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var trackCountLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.artworkImageView.layer.borderWidth = 0.5
        self.artworkImageView.layer.borderColor = UIColor.lightGrayColor().CGColor
        self.artworkImageView.layer.cornerRadius = 2.0
        self.artworkImageView.clipsToBounds = true
    }
}
