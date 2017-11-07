//
//  NewsModel.swift
//
//  Created by mkxy on 17/6/13.
//  Copyright © 2017年 阿蛋. All rights reserved.
//

import UIKit

class NewsModel: NSObject {
    //1.定义属性
    var mp4_url : String = ""
    var cover : String = ""
    var title : String = ""
    
    //2.字典转模型
    init(dict : [String : Any]) {
        super.init()
        setValuesForKeys(dict)
    }
    override func setValue(_ value: Any?, forUndefinedKey key: String) {
    }
}
