//
//  HYCamera.swift
//  Camera
//
//  Created by hyw on 2018/5/22.
//  Copyright © 2018年 haiyang_wang. All rights reserved.
//
/**
    调用系统相机完成照片，视频拍摄
    自定义UI
 */
protocol HYCameraDelegate {
    /// 设备初始化失败
    func hyCameraDeviceInitFailed(hyCamera:HYCamera, errorInfo:String?)
    /// 数据写入失败
    func hyCameraAssetLibraryWriteFailed(hyCamera:HYCamera, errorInfo:String?)

}

/// 拍照or视频后的缩略图通知
let HYCameraThumbnilImageNotification = "HYCameraThumbnilImageNotification"

import UIKit
import AVFoundation
import Photos
class HYCamera: UIView {
    var delegate:HYCameraDelegate?
    
    /// 当前活跃的设备
    var activeVideoInput:AVCaptureDeviceInput?
    /// 会话
    var captureSession:AVCaptureSession?
    /// 图片输出
    var imageOutput:AVCaptureStillImageOutput?
    /// 视频输出
    var videoOutput:AVCaptureMovieFileOutput?
    
    fileprivate var outputVideoUrl:URL?
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpSession()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
/// Public methods
extension HYCamera {
    
    /// 拍照
    func takePhoto() {
        stillImage()
    }
    /// 录制开始
    func startRecord() {
        startRecording()
    }
    /// 录制结束
    func stopRecord() {
        stopRecording()
    }
  
}
/// 拍照 Or 录视频
extension HYCamera {
    
    /// 拍摄静态图片
    fileprivate func stillImage() {
        /// 连接
        let connection = imageOutput?.connection(with: .video)
        if (connection?.isVideoOrientationSupported)! {
            connection?.videoOrientation = videoOriention()
        }
        imageOutput?.captureStillImageAsynchronously(from: connection!, completionHandler: { (sampleBuffer, error) in
            if (sampleBuffer != nil) {
                let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer!)
                let image = UIImage.init(data: imageData!)
                /// 写入
                UIImageWriteToSavedPhotosAlbum(image!, self, #selector(self.image(image:didFinishSavingWithError:contextInfo:)), nil)
            }
        })
    }
   
    /// 视频拍摄
    /// 是否正在拍摄
    fileprivate func isRecording() -> Bool {
        return (videoOutput?.isRecording)!
    }
    /// 停止拍摄
    fileprivate func stopRecording() {
        if isRecording() {
            videoOutput?.stopRecording()
        }
    }
    /// 开始拍摄
    fileprivate func startRecording() {
        if !isRecording() {
            let connection = videoOutput?.connection(with: .video)
            if (connection?.isVideoOrientationSupported)! {
                connection?.videoOrientation = videoOriention()
            }
            if (connection?.isVideoStabilizationSupported)! {
                connection?.preferredVideoStabilizationMode = .auto
            }
            let device = activeCamera()
            
            if device.isSmoothAutoFocusSupported {
                
                if ((try? device.lockForConfiguration()) != nil) {
                    device.isSmoothAutoFocusEnabled = true
                    device.unlockForConfiguration()
                }else {
                    print("devide configure faild")
                }
            }
            
            outputVideoUrl = uniqueUrl()
            videoOutput?.startRecording(to: outputVideoUrl!, recordingDelegate: self)
        }
    }
    
    /// 图片写入
    @objc func image(image: UIImage, didFinishSavingWithError: NSError?, contextInfo: AnyObject) {
        
        if didFinishSavingWithError != nil {
            print("图片写入错误")
            delegate?.hyCameraAssetLibraryWriteFailed(hyCamera: self, errorInfo: "图片写入错误")
            return
        }
        print("图片写入成功")
        postThumbnilImageNotification(image: image)
    }
    /// 视频写入
    @objc func video(image: UIImage, didFinishSavingWithError: NSError?, contextInfo: AnyObject) {
        
        if didFinishSavingWithError != nil {
            print("视频写入错误")
            delegate?.hyCameraAssetLibraryWriteFailed(hyCamera: self, errorInfo: "视频写入错误")
            return
        }
        print("视频写入成功")
        generatorThumbnilForVideoUrl(videoUrl: outputVideoUrl!)
    }
    /// 截取视频缩略图
    fileprivate func generatorThumbnilForVideoUrl(videoUrl:URL) {
       outputVideoUrl = nil
        DispatchQueue.global().async {
            let asset = AVAsset.init(url: videoUrl)
            let imageGenerator = AVAssetImageGenerator.init(asset: asset)
            /// 自动计算高度
            imageGenerator.maximumSize = CGSize.init(width: 100.0, height: 0.0)
            imageGenerator.appliesPreferredTrackTransform = true
            
            let imageRef = try? imageGenerator.copyCGImage(at: kCMTimeZero, actualTime: nil)
            if imageRef != nil {
                let image = UIImage.init(cgImage: imageRef!)
                DispatchQueue.main.async {
                    self.postThumbnilImageNotification(image: image)
                }
            }
        }
    }
    /// 缩略图通知
    fileprivate func postThumbnilImageNotification(image:UIImage) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: HYCameraThumbnilImageNotification), object: image)
    }
    /// 移除所有通知
    fileprivate func removeNotification() {
        NotificationCenter.default.removeObserver(self)
    }
    /// 视频保存路径
    fileprivate func uniqueUrl() -> URL? {
        
        let dirPath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, .userDomainMask, true)[0]
        if !dirPath.isEmpty {
            let time = Date.init().timeIntervalSinceNow
            let filePath = dirPath + "/HYCamera\(time).mov"
            return URL(fileURLWithPath: filePath)
        }
        return nil
    }
    /// 同步屏幕和图片、视频拍摄的方向
    fileprivate func videoOriention() ->AVCaptureVideoOrientation {
        let oriention:AVCaptureVideoOrientation?
        let deviceOriention = UIDevice.current.orientation
        switch deviceOriention {
        case .portrait:
            oriention = AVCaptureVideoOrientation.portrait
            break
        case .portraitUpsideDown:
            oriention = AVCaptureVideoOrientation.portraitUpsideDown
            break
        case .landscapeLeft:
            /// 物理屏幕和拍摄时 方向是相反的
            oriention = AVCaptureVideoOrientation.landscapeRight
            break
        default:
            oriention = AVCaptureVideoOrientation.landscapeLeft
        }
        return oriention!
    }
}
///AVCaptureFileOutputRecordingDelegate
extension HYCamera: AVCaptureFileOutputRecordingDelegate {
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if error != nil {
            ///失败
        }else {
            UISaveVideoAtPathToSavedPhotosAlbum(outputFileURL.path, self, #selector(self.video(image:didFinishSavingWithError:contextInfo:)), nil)
        }
    }
}
/// 会话服务
extension HYCamera {
    
    /// 开启会话
    func startSession() {
        if !(captureSession?.isRunning)! {
            DispatchQueue.global().async {
                self.captureSession?.startRunning()
            }
        }
    }
    /// 停止会话
    func stopSession() {
        if (captureSession?.isRunning)! {
            DispatchQueue.global().async {
                self.captureSession?.stopRunning()
            }
        }
    }
    /// 设置会话
    fileprivate func setUpSession() -> Bool {
        
        /// 会话
        captureSession = AVCaptureSession.init()
        captureSession?.sessionPreset = .high
        /// 默认视频设备
        let videoDevice = AVCaptureDevice.default(for: .video)
        /// 视频输入
        let videoInput = try? AVCaptureDeviceInput.init(device: videoDevice!)
        if (videoInput != nil) {
            if (captureSession?.canAddInput(videoInput!))! {
                captureSession?.addInput(videoInput!)
                activeVideoInput = videoInput
            }
        }else {
            /// 一般是因为权限被禁止 设置-隐私-开启
            delegate?.hyCameraDeviceInitFailed(hyCamera: self, errorInfo: "输入设备摄像头初始化异常")
            return false
        }
        /// 音频设备
        let audioDevice = AVCaptureDevice.default(for: .audio)
        /// 音频输入
        let audioInput = try? AVCaptureDeviceInput.init(device: audioDevice!)
        if (audioInput != nil) {
            if (captureSession?.canAddInput(audioInput!))! {
                captureSession?.addInput(audioInput!)
            }
        }else {
            delegate?.hyCameraDeviceInitFailed(hyCamera: self, errorInfo: "输入设备麦克风初始化异常")
            return false
        }
        
        /// 输出
        /// 图片输出
        imageOutput = AVCaptureStillImageOutput.init()
        imageOutput?.outputSettings = [AVVideoCodecKey:AVVideoCodecJPEG]
        if (captureSession?.canAddOutput(imageOutput!))! {
            captureSession?.addOutput(imageOutput!)
        }
        
        /// 视频输出
        videoOutput = AVCaptureMovieFileOutput.init()
        if (captureSession?.canAddOutput(videoOutput!))! {
            captureSession?.addOutput(videoOutput!)
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer.init(session: captureSession!)
        previewLayer.videoGravity = .resizeAspect
        previewLayer.frame = bounds
        
        self.layer.addSublayer(previewLayer)
        startSession()
        return true
    }
}
/// 摄像头支持方法
extension HYCamera {
    
    /// 切换摄像头
    func switchCameras() -> Bool {
        if canSwitchCameras() {
            return false
        }
        let newVideoDevice = inActiveCamera()
        let newVideoDeviceInput = try? AVCaptureDeviceInput.init(device: newVideoDevice!)
        if (newVideoDeviceInput != nil) {
            captureSession?.beginConfiguration()
            captureSession?.removeInput(activeVideoInput!)
            if (captureSession?.canAddInput(newVideoDeviceInput!))! {
                captureSession?.addInput(newVideoDeviceInput!)
                activeVideoInput = newVideoDeviceInput
            }
            captureSession?.commitConfiguration()
        }else {
            captureSession?.addInput(activeVideoInput!)
        }
        return true
    }
    /// 返回指定位置的摄像头
    fileprivate func cameraWithPosition(position:AVCaptureDevice.Position) -> AVCaptureDevice? {
        let devices = AVCaptureDevice.devices(for: .video)
        for device in devices {
            if device.position == position {
                return device
            }
        }
        return nil
    }
    /// 激活的摄像头
    fileprivate func activeCamera() -> AVCaptureDevice {
        return (activeVideoInput?.device)!
    }
    /// 未激活的摄像头
    fileprivate func inActiveCamera() -> AVCaptureDevice? {
        var device:AVCaptureDevice? = nil
        if cameraCounts() > 1 {
            if activeCamera().position == .back {
                /// 前置未激活
                device = cameraWithPosition(position: .front)
            }else {
                /// 后置未激活
                device = cameraWithPosition(position: .back)
            }
        }
        return device
    }
    /// 是否可以切换摄像头
    func canSwitchCameras() -> Bool {
        return cameraCounts() > 1
    }
    /// 设备有几个摄像头 （前后）
    fileprivate func cameraCounts() -> Int {
        return AVCaptureDevice.devices().count
    }
}
/// 配置捕捉设备 （对角，曝光不做处理）
extension HYCamera {
    
    /// 是否支兴趣点持对焦
    func cameraSupportTapFocus() -> Bool {
        return activeCamera().isFocusPointOfInterestSupported
    }
    
    /// 设置对焦点
    func focusAt(point:CGPoint) {
        let device = activeCamera()
        if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(.autoFocus) {
            if ((try? device.lockForConfiguration()) != nil) {
                device.focusPointOfInterest = point
                device.focusMode = .autoFocus
                device.unlockForConfiguration()
            }else {
                print("device configure faild")
            }
        }
    }
    
    /// 重置对焦和曝光
    func resetFocusAndExposureMode() {
        
        let device = activeCamera()
        /// 对焦
        let focusMode = AVCaptureDevice.FocusMode.continuousAutoFocus
        let canResetFocus = device.isFocusPointOfInterestSupported && device.isFocusModeSupported(focusMode)
        /// 曝光
        let exposureMode = AVCaptureDevice.ExposureMode.continuousAutoExposure
        let canResetExposure = device.isExposurePointOfInterestSupported && device.isExposureModeSupported(exposureMode)
        /// 中心点对焦曝光
        let point = CGPoint.init(x: 0.5, y: 0.5)
        
        if ((try? device.lockForConfiguration()) != nil) {
            
            if canResetFocus {
                device.focusMode = focusMode
                device.focusPointOfInterest = point
            }
            if canResetExposure {
                device.exposureMode = exposureMode
                device.exposurePointOfInterest = point
            }
            device.unlockForConfiguration()
        }else {
            print("device configure faild")
        }
    }
}
/// 手电筒和闪光灯
/// On off auto
extension HYCamera {
    /// 是否有闪光
    func cameraHasFlash() -> Bool{
        return activeCamera().hasFlash
    }
    /// 闪光模式
    func cameraFlashMode() -> AVCaptureDevice.FlashMode {
        return activeCamera().flashMode
    }
    /// 设置闪光模式
    func setFlashMode(mode:AVCaptureDevice.FlashMode) {
        
        let device = activeCamera()
        if device.isFlashModeSupported(mode) {
            if ((try? device.lockForConfiguration()) != nil) {
                device.flashMode = mode
                device.unlockForConfiguration()
            }else {
                print("device configure faild")
            }
        }
    }
    /// 是否有手电筒
    func cameraHasTorch() -> Bool {
        return activeCamera().hasTorch
    }
    /// 手电筒模式
    func cameraTorchMode() -> AVCaptureDevice.TorchMode {
        return activeCamera().torchMode
    }
    /// 设置手电筒模式
    func setTorchModel(mode:AVCaptureDevice.TorchMode) {
        let device = activeCamera()
        if device.isTorchModeSupported(mode) {
            if ((try? device.lockForConfiguration()) != nil) {
                device.torchMode = mode
                device.unlockForConfiguration()
            }else {
                print("device configure faild")
            }
        }
    }
}
