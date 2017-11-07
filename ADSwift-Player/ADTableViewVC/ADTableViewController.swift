//
//  ADTableViewController.swift
//  ADSwift-Player
//
//  Created by 阿蛋 on 17/10/3.
//  Copyright © 2017年 adan. All rights reserved.
//

import UIKit
private let cellId : String = "cellId"
class ADTableViewController: UIViewController ,UITableViewDelegate,UITableViewDataSource,PlayerViewDelegate,UIScrollViewDelegate{

    var playerView: ADPlayerView!
    var isSmallScreen : Bool?
    var ClickedBtn : UIButton!
    var isOnCell = true
    
    var cell  = HomeViewCell()
    var currentIndexpath = IndexPath()
    //懒加载ViewModel
    fileprivate lazy var requestViewModel = ADRequestViewModel()
    fileprivate lazy var tableView : UITableView = {[unowned self] in
        let tableView = UITableView()
        tableView.frame = CGRect(x: 0, y: 64, width: SCREEN_WIDTH, height: SCREEN_HEIGHT - 64-49)
        tableView.dataSource = self
        tableView.delegate = self
        //注册cell
        tableView.register(UINib(nibName:"HomeViewCell", bundle: nil), forCellReuseIdentifier: cellId)
        return tableView
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        automaticallyAdjustsScrollViewInsets = false
        self.view.addSubview(tableView)
        navigationItem.title = "ADTableviewVC"
        //3.请求数据
        loadData()
    }
}
//3.请求数据
extension ADTableViewController{
    fileprivate func loadData(){
        requestViewModel.loadData {
            self.tableView.reloadData()
        }
    }
}
extension ADTableViewController{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return requestViewModel.ModelArr.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! HomeViewCell
        let model = requestViewModel.ModelArr[indexPath.row]
        cell.playButton.addTarget(self, action: #selector(titleClick(_:)), for: .touchUpInside)
        cell.playButton.tag = indexPath.row
        cell.newsModel = model
        // 当播放器的View存在的时候
        if (self.playerView != nil)&&(self.playerView.superview != nil) {
            if indexPath.row == self.currentIndexpath.row {
                cell.playButton.superview?.sendSubview(toBack: cell.playButton)
            }else{
                cell.playButton.superview?.bringSubview(toFront: cell.playButton)
            }
        }
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 300
    }
}
extension ADTableViewController{
    func titleClick(_ button : UIButton) {
        ClickedBtn = button
        currentIndexpath = IndexPath(row: button.tag, section: 0)
        if (playerView != nil) {
            playerView.removeFromSuperview()
        }
        cell = superUITableViewCell(of: button)! as! HomeViewCell
        let model = requestViewModel.ModelArr[button.tag]
        playerView = ADPlayerView(frame: CGRect(x: 0, y: 0, width: SCREEN_WIDTH, height: cell.iconView.height), contentView: cell.iconView)
        playerView.delegate = self
        playerView.titleLB.text = model.title
        cell.iconView.addSubview(playerView)
        cell.contentView.sendSubview(toBack: cell.playButton)
        playerView.changePlayUrl(model.mp4_url, startTime: 0)
        playerView.play()
        self.tableView.reloadData()
    }
    func superUITableViewCell(of: UIButton) -> UITableViewCell? {
        for view in sequence(first: of.superview, next: { $0?.superview }) {
            if let cell = view as? UITableViewCell {
                return cell
            }
        }
        return nil
    }
    
    // MARK:- PlayerManagerDelegate
    // 返回按钮点击回调
    func playerViewBack() {
        if playerView.isWindow == true {
            playerView.smallScreen()
        }else{
            playerView.originalScreen()
        }

    }
    
    // 播放完成回调
    func playFinished() {
        if playerView.isWindow == true {
            tableView.reloadData()
        }else{
            cell = tableView.cellForRow(at: currentIndexpath) as! HomeViewCell
            cell.contentView.bringSubview(toFront: cell.playButton)
        }
    }
    //返回按钮的回调事件
    func videoViewBackButtonClicked(){
        if playerView.isWindow == true {
            tableView.reloadData()
        }else{
        cell = tableView.cellForRow(at: currentIndexpath) as! HomeViewCell
        cell.contentView.bringSubview(toFront: cell.playButton)
       }
    }
}
extension ADTableViewController{
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if self.playerView == nil {
            return
        }
        if (self.playerView.superview != nil) {
            let rectInTableView = tableView.rectForRow(at: currentIndexpath as IndexPath)
            let rectInSuperview = tableView.convert(rectInTableView, to: tableView.superview)
            if (rectInSuperview.origin.y < -cell.iconView.frame.size.height||rectInSuperview.origin.y>SCREEN_HEIGHT-64-49) {//往上拖动
                //放widow上,小屏显示
                ToSmallScreen()
            }else{
                if isOnCell == true{
                }else{
                ToCell()
                }
            }
        }
    }
}
extension ADTableViewController{
    fileprivate func ToSmallScreen(){
        isOnCell = false
        //放widow上
        playerView.isWindow = true
        playerView.smallScreen()
    }
    //放在cell上播放
    fileprivate func ToCell(){
        isOnCell = true
        playerView.isWindow = false
        cell = tableView.cellForRow(at: currentIndexpath) as! HomeViewCell
        playerView.backToCell(cell)
    }
}
