//
//  ADNormalVC.swift
//  ADSwift-Player
//
//  Created by 阿蛋 on 17/10/7.
//  Copyright © 2017年 adan. All rights reserved.
//

import UIKit

private let cellId : String = "cellId"
class ADNormalVC: UIViewController{
    //懒加载ViewModel
    fileprivate lazy var requestViewModel = ADRequestViewModel()
    fileprivate lazy var ModelArr : [NewsModel] = [NewsModel]()
    fileprivate lazy var tableView : UITableView = {[unowned self] in
        let tableView = UITableView()
        tableView.frame = CGRect(x: 0, y: 64, width: SCREEN_WIDTH, height: SCREEN_HEIGHT - 64-49)
        tableView.dataSource = self
        tableView.delegate = self
        //注册cell
        tableView.register(UINib(nibName: "ADNormalCell", bundle: nil), forCellReuseIdentifier: cellId)
        return tableView
        }()
    override func viewDidLoad() {
        super.viewDidLoad()
        automaticallyAdjustsScrollViewInsets = false
        self.view.addSubview(tableView)
        //3.请求数据
        loadData()
    }
}
//3.请求数据
extension ADNormalVC{
    fileprivate func loadData(){
        requestViewModel.loadData {
            self.tableView.reloadData()
        }
    }
}
extension ADNormalVC : UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return requestViewModel.ModelArr.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! ADNormalCell
        let model = requestViewModel.ModelArr[indexPath.row]
        cell.newsModel = model
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
}
extension ADNormalVC : UITableViewDelegate{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let videoVC = ADVideoVC()
        let model = requestViewModel.ModelArr[indexPath.row]
        videoVC.newsModel = model
        navigationController?.pushViewController(videoVC, animated: true)
        
    }
}
