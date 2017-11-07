//
//  ADNormalCell.swift
//  ADSwift-Player
//
//  Created by 阿蛋 on 17/11/7.
//  Copyright © 2017年 adan. All rights reserved.
//

import UIKit
import Kingfisher

class ADNormalCell: UITableViewCell {
    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var titleLB: UILabel!
    var newsModel : NewsModel? {
        didSet{
            titleLB.text = newsModel?.title
            let url  = URL(string: newsModel?.cover ?? "")
            iconView.kf.setImage(with: url)
        }
    }
}
