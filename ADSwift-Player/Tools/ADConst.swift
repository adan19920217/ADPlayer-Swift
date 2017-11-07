//
//  ADConst.swift
//  ADSwift-Player
//
//  Created by 阿蛋 on 17/10/7.
//  Copyright © 2017年 adan. All rights reserved.
//

import UIKit

// 屏幕宽度
let ScreenWidth = UIScreen.main.bounds.size.height
// 屏幕高度
let ScreenHeight = UIScreen.main.bounds.size.width

//扩充系统颜色
extension UIColor{
    convenience init(r : CGFloat,g : CGFloat,b : CGFloat, alpha:CGFloat = 1.0) {
        self.init(red: r / 255.0, green: g / 255.0, blue: b / 255.0, alpha: 1.0)
    }
}
//缩放图片
extension UIImage {
    // 将当前图片缩放到指定尺寸
    func scaleImageToSize(size: CGSize) -> UIImage {
        UIGraphicsBeginImageContext(size)
        draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return scaledImage!
    }
}
/** 计算文本尺寸 */
func textSizeWithString(_ str: String, font: UIFont, maxSize:CGSize) -> CGSize {
    let dict = [NSFontAttributeName: font]
    let size = (str as NSString).boundingRect(with: maxSize, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: dict, context: nil).size
    return size
}

/** 屏幕尺寸 */

// 屏幕宽度
let SCREEN_HEIGHT = UIScreen.main.bounds.size.height
// 屏幕高度
let SCREEN_WIDTH = UIScreen.main.bounds.size.width
// 自适应屏幕宽度
func FIT_SCREEN_WIDTH(_ size: CGFloat) -> CGFloat {
    return size * SCREEN_WIDTH / 375.0
}
// 自适应屏幕高度
func FIT_SCREEN_HEIGHT(_ size: CGFloat) -> CGFloat {
    return size * SCREEN_HEIGHT / 667.0
}
// 自适应屏幕字体大小
func AUTO_FONT(_ size: CGFloat) -> UIFont {
    let autoSize = size * SCREEN_WIDTH / 375.0
    return UIFont.systemFont(ofSize: autoSize)
}


/** 颜色值 */
// RGB颜色
func RGB_COLOR(_ r:CGFloat, g:CGFloat, b:CGFloat, alpha:CGFloat) -> UIColor {
    return UIColor(red: r / 255.0, green: g / 255.0, blue: b / 255.0, alpha: alpha)
}





