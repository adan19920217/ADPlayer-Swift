//
//  HomeViewCell.swift
//
//  Created by mkxy on 17/6/14.
//  Copyright © 2017年 阿蛋. All rights reserved.
//

import UIKit
import Kingfisher

class HomeViewCell: UITableViewCell {
    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var titleLB: UILabel!
    override func awakeFromNib() {
        iconView.isUserInteractionEnabled = true
    }
    //*******这个地方******//
    var newsModel : NewsModel?{
        //监听属性改变
        didSet{
            //如果url为空,就传递空字符串
            let url = URL(string: newsModel?.cover ?? "")
            //根据URL创建图片
            iconView.kf.setImage(with: url)
            let title = newsModel?.title
            titleLB.text = title
            
        }
    }
}
