//
//  ADRequestViewModel.swift
//  ADSwift-Player
//
//  Created by 阿蛋 on 17/11/7.
//  Copyright © 2017年 adan. All rights reserved.
//

import UIKit

class ADRequestViewModel{
    //无线轮播器数组
    lazy var ModelArr : [NewsModel] = [NewsModel]()
    func loadData(finishCallBack : @escaping ()->()){
        HttpTool.requestData(URLString: "http://c.m.163.com/nc/video/home/0-10.html", type: .get) { (result : Any) in
               print(result)
            //1.将any类型转化成字典
            guard let resultDict = result as? [String : Any]else{return}
            //2.根据key取出字典数组
            guard let DataArr = resultDict["videoList"] as?[[String : Any]]else{
            return
            }
            //3.遍历字典,字典转模型
            for dict in DataArr{
            self.ModelArr.append(NewsModel(dict: dict))
            }
            finishCallBack()
        }
    }
}
