//
//  ViewController.swift
//  Camera
//
//  Created by hyw on 2018/5/22.
//  Copyright © 2018年 haiyang_wang. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    var camera:HYCamera!
    var names = [String]()
    var ages:[Int] = []
    
    var scores = Array(repeating: 0, count: 4)
    var letters = Set<String>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        camera = HYCamera.init(frame: self.view.bounds)
        self.view.addSubview(camera)
        for (index,value) in scores.enumerated() {
            print("下标\(index) 值\(value)")
        
        }
        for age in stride(from: 0, to: 60, by: 10) {
            /// age 0 10 20 30 40 50
        }
        if scores.contains(0) {
            print("contaions zero")
        }
        let btn = UIButton.init(frame: CGRect.init(x: 200, y: 400, width: 50, height: 30))
        btn.setTitle("拍摄", for: .normal)
        btn.addTarget(self, action: #selector(self.takeAPhoto), for: .touchUpInside)
        self.view.addSubview(btn)
        
        let btnt = UIButton.init(frame: CGRect.init(x: 200, y: 500, width: 50, height: 30))
        btnt.setTitle("停止", for: .normal)
        btnt.addTarget(self, action: #selector(self.sAPhoto), for: .allTouchEvents)
        
        self.view.addSubview(btnt)
        // Do any additional setup after loading the view, typically from a nib.
    }
    @objc func takeAPhoto() {
        
        
    
        camera.startRecord()
        camera.setTorchModel(mode: .on)
    }
    @objc func sAPhoto() {
        camera.stopRecord()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

