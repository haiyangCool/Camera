//
//  HYCameraDock.swift
//  Camera
//
//  Created by hyw on 2018/5/22.
//  Copyright © 2018年 haiyang_wang. All rights reserved.
//

import UIKit

class HYCameraDock: UIView {

    /// 拍摄静态图片
    fileprivate var stillImageBtn:UIButton?
    /// 开始录制视频
    fileprivate var startRecordBtn:UIButton?
    /// 结束录制视频
    fileprivate var stopRecordBtn:UIButton?
    /// 切换摄像头
    fileprivate var switchCameraBtn:UIButton?
    /// 闪光灯
    fileprivate var flashButton:UIButton?
    /// 手电筒
    fileprivate var torchButton:UIButton?
    /// 闪光灯or手电筒 开
    fileprivate var flashOrTorchOnBtn:UIButton?
    /// 闪光灯or手电筒 关
    fileprivate var flashOrTorchOffBtn:UIButton?
    /// 闪光灯or手电筒 自动
    fileprivate var flashOrTorchAutoBtn:UIButton?

    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
