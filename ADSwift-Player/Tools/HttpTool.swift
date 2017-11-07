//
//  HttpTool.swift
//
//  Created by mkxy on 17/6/13.
//  Copyright © 2017年 阿蛋. All rights reserved.
//

import UIKit
import Alamofire

enum MethodType{
    case get
    case post
}
class HttpTool {
    class func requestData(URLString : String,type : MethodType,params : [String : Any]? = nil,finishCallBack : @escaping(_ result : Any) -> ()){
        let method = type == .get ? HTTPMethod.get : HTTPMethod.post
        Alamofire.request(URLString, method: method, parameters: params).responseJSON { (response) in
            //使用guard校验
            guard let result = response.result.value else{
                return
            }
            //有值
            finishCallBack(result)
        }
    }
}
