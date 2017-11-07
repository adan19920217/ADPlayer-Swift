//
//  ADVideoVC.swift
//  ADSwift-Player
//
//  Created by 阿蛋 on 17/11/7.
//  Copyright © 2017年 adan. All rights reserved.
//

import UIKit

class ADVideoVC: UIViewController ,PlayerViewDelegate {

    var playerView: ADPlayerView!
    var imageView : UIImageView!
    var newsModel : NewsModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        navigationItem.title = "ADVideoVC"
        setupUI()
    }
    deinit{
        if playerView != nil {
            playerView.removeFromSuperview()
        }
    }
    // 返回按钮点击回调
    func playerViewBack() {
        //do someThing
    }
    func videoViewBackButtonClicked() {
        //do someThing
    }
    // 播放完成回调
    func playFinished() {
        //do someThing
    }
}
extension ADVideoVC{
    fileprivate func setupUI(){
        imageView = UIImageView(frame: CGRect(x: 0, y: 64, width: SCREEN_WIDTH, height: 210))
        let url  = URL(string: newsModel?.cover ?? "")
        imageView.kf.setImage(with: url)
        imageView.isUserInteractionEnabled = true
        view.addSubview(imageView);
        
        let button = UIButton()
        button.frame = CGRect(x: (SCREEN_WIDTH - 50)/2, y: 80, width: 50, height: 50)
        button.setImage(UIImage(named : ("video_play_btn_bg")), for: .normal)
        imageView.addSubview(button)
        button.addTarget(self, action: #selector(titleClick(_:)), for: .touchUpInside)
        
    }
}
extension ADVideoVC{
    @objc fileprivate func titleClick(_ button : UIButton) {
        playerView = ADPlayerView(frame: CGRect(x: 0, y: 64, width: SCREEN_WIDTH, height: 210), contentView: self.view)
        view.addSubview(playerView)
        playerView.delegate = self
        playerView.titleLB.text = newsModel?.title
        //设置播放URL
        playerView.playUrlStr = newsModel?.mp4_url
        // 跳转至第N秒的进度位置
        playerView.seekToTime(0)
        playerView.play()
    }
}
