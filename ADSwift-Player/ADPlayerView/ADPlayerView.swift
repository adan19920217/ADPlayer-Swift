//
//  ADPlayerView.swift
//  ADSwift-Player
//
//  Created by 阿蛋 on 17/9/28.
//  Copyright © 2017年 adan. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer
import CoreMedia

protocol PlayerViewDelegate: class {
    // 返回按钮点击代理
    func videoViewBackButtonClicked()
    func playerViewBack() // 返回
    func playFinished() // 播放完成
}
extension PlayerViewDelegate {
    func playFinished() {} // 播放完成
}

enum ProgressChangeType { // 进度调节触发方式
    case panGuesture // 屏幕拖拽手势
    case sliderPan // 拖拽滑条
    case sliderTap // 点击滑条
}

enum ErrorType { // 异常错误类型
    case playUrlNull // 播放地址为空
}

enum RotateDirection { // 屏幕旋转方向
    case left
    case right
    case up
}

enum DragDirection {//拖拽方向
    case none // 无
    case horizontal // 水平
    case vertical // 竖直
}
class ADPlayerView: UIView ,UIGestureRecognizerDelegate {
    public var playUrlStr: String? {
        didSet {
            initPlayerURL()
        }
    }
    public var isAutoFull = true // 横屏时是否自动全屏
    // MARK: 控件变量属性
    private var playbackTimeObserver: NSObject?
    fileprivate var timeContext: Void?
    fileprivate var statusContext: Void?
//代理属性
    weak var delegate: PlayerViewDelegate?
    
    var totalTime : Int = 0
    var  currentTime : Int = 0
    //播放器层面
    lazy var player : AVPlayer = {
        return AVPlayer()
    }()
    var playerItem: AVPlayerItem?
    var lastPlayerItem : AVPlayerItem?
    var playerLayer = AVPlayerLayer()
    //视图层面
    fileprivate var coverView = UIView()
    //顶部View
    var topView = UIView()
    var backBtn = UIButton()
    let titleLB = UILabel()
    //底部View
    fileprivate var toolBarView = UIView()
    fileprivate let playOrPauseBtn = UIButton()
    fileprivate let fullScreenBtn = UIButton()
    fileprivate var beginTimeLabel = UILabel() //开始时间
    fileprivate var endTimeLabel = UILabel() //右侧时间
    fileprivate let progressView = UIProgressView()//缓冲条
    fileprivate let progressSlider = UISlider()//进度条
    fileprivate var loadingView = UIActivityIndicatorView()//菊花
    
    //控件属性
    fileprivate var contentView = UIView()
    var customFarme = CGRect()
    fileprivate let navigationHeight: CGFloat = 64
    fileprivate let toolBarViewH: CGFloat = FIT_SCREEN_HEIGHT(40)
    fileprivate let Padding = FIT_SCREEN_WIDTH(10)
    fileprivate let ProgressColor = RGB_COLOR(255.0, g: 255.0, b: 255.0, alpha: 1) //进度条颜色
    fileprivate let ProgressTintColor = RGB_COLOR(221, g: 221, b: 221, alpha: 1) //缓冲颜色
    fileprivate let PlayFinishColor = RGB_COLOR(252, g: 106, b: 125, alpha: 1) //播放完成颜色
    fileprivate let initTimeString = "00:00"
    
    // MARK:- 变量属性控制
    fileprivate var toolBarTimer: Timer?
    fileprivate var isFullScreen = false //是否是全屏
    var isWindow = false
    
    fileprivate var firstPoint = CGPoint()
    fileprivate var secondPoint = CGPoint()
    fileprivate var isDragging = false // 是否正在拖拽进度条或者滑动屏幕进度
    fileprivate let DisapperAnimateDuration = 0.5
    fileprivate var dragDirection: DragDirection?
    
    init(frame: CGRect,contentView : UIView) {
        super.init(frame: frame)
//下面两句未懂
        self.contentView = contentView
        customFarme = frame
        backgroundColor = UIColor.black
//        //创建UI界面
//        setupUI()
        //计时器，循环执行(在视频暂停以及进入后台时会自动停止，恢复后自动开始)
        playbackTimeObserver = self.player.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(1.0, Int32(NSEC_PER_SEC)), queue: DispatchQueue.main) { [weak self] (time) in
            self?.refreshTimeObserve()
            } as? NSObject
        // 进入后台通知
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground(_:)), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        // 播放完成通知
        NotificationCenter.default.addObserver(self, selector: #selector(moviePlayDidEnd(_:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        // 注册屏幕旋转通知
        NotificationCenter.default.addObserver(self, selector: #selector(statusBarOrientationChange(_:)), name: NSNotification.Name.UIDeviceOrientationDidChange, object: UIDevice.current)
    }
    
    // 初始化播放地址
    private func initPlayerURL() {
        //视频音频设置
        do {
            _ = try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: AVAudioSessionCategoryOptions.mixWithOthers)
        } catch {
        }
        
        let asset = self.getAVURLAsset(urlStr: self.playUrlStr ?? "")
        self.playerItem = AVPlayerItem(asset: asset)
        changePlayerItem()
        self.playerLayer = AVPlayerLayer(player: self.player)
        self.player.replaceCurrentItem(with: self.playerItem)
        
        self.originalScreen()
        self.startLoadingAnimation()
    }
    
    // 转换url
    fileprivate func getAVURLAsset(urlStr: String) -> AVURLAsset {
        let url: URL?
        // 确保转成url后不会为nil
        let encodeStr = urlStr.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) ?? "invalidURLStr"
        if encodeStr.contains("http") == true { // 在线视频
            url = URL(string: encodeStr)
        } else {// 本地视频
            url = URL(fileURLWithPath: encodeStr)
        }
        return AVURLAsset(url: url!)
    }
    
    // 改变item
    fileprivate func changePlayerItem() {
        if self.lastPlayerItem == self.playerItem {
            return
        }
        
        if let item = self.lastPlayerItem {
            item.removeObserver(self, forKeyPath: "status")
            item.removeObserver(self, forKeyPath: "loadedTimeRanges")
        }
        
        self.lastPlayerItem = self.playerItem
        if let item = self.playerItem {
            item.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.new, context: &statusContext)
            item.addObserver(self, forKeyPath: "loadedTimeRanges", options: NSKeyValueObservingOptions.new, context: &timeContext)
        }
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    deinit{//销毁的时候
        self.playerItem?.removeObserver(self, forKeyPath: "status")
        self.playerItem?.removeObserver(self, forKeyPath: "loadedTimeRanges")
        self.player.replaceCurrentItem(with: nil)
        self.player.currentItem?.cancelPendingSeeks()
        self.player.currentItem?.asset.cancelLoading()
        if playbackTimeObserver != nil {
            //添加异常判断
            self.player.removeTimeObserver(playbackTimeObserver!)
        }
        NotificationCenter.default.removeObserver(self)
        playerLayer.player = nil
        invalidateToolBarTimer()
    }
}

extension ADPlayerView {// MARK: 外部调用方法
    // 播放
    func play() {
        self.playVideo()
    }
    // 暂停
    func pause() {
        self.pauseVideo()
    }
    // 切换播放地址
    func changePlayUrl(_ urlStr: String, startTime: Int) {
        self.player.replaceCurrentItem(with: nil)
        self.originalScreen()
        self.startLoadingAnimation()
        
        let asset = getAVURLAsset(urlStr: urlStr)
        self.playerItem = AVPlayerItem(asset: asset)
        changePlayerItem()
        self.player.replaceCurrentItem(with: self.playerItem)
        
        self.playerLayer.removeFromSuperlayer()
        self.playerLayer = AVPlayerLayer(player: self.player)
        self.layer.addSublayer(self.playerLayer)
        
        self.originalScreen()
        self.startLoadingAnimation()
        self.seekToVideo(startTime)
        play()
    }
    // 调整视频进度
    func seekToTime(_ startTime: Int) {
        self.seekToVideo(startTime)
    }
    // 获取当前时间
    func getCurrentTime() -> Int {
        return self.currentTime
    }
    // 获取总时间
    func getTotalTime() -> Int {
        return self.totalTime
    }
    // MARK: PlayerView代理方法
    // 返回按钮点击代理
    func videoViewBackButtonClicked() {
        delegate?.playerViewBack()
    }
}

extension ADPlayerView {
    
    // MARK: 监听
    // 定时刷新监听
    func refreshTimeObserve() {
        self.refreshShowValues()
    }
    
    // 缓存条、视频加载状态监听
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if context == &timeContext {
            // 刷新缓冲条进度
            self.setProgressValue()
            
        } else if context == &statusContext {
            if self.player.status == AVPlayerStatus.readyToPlay {
                // 根据时间重新调整时间frame值
                self.resizeTimeLabel()
                self.stopLoadingAnimation()
                
            } else if self.player.status == AVPlayerStatus.unknown {
                self.startLoadingAnimation()
                
            } else if self.player.status == AVPlayerStatus.failed {
                self.stopLoadingAnimation()
            }
        }
    }
    
    
    // 进入后台通知
    @objc fileprivate func appDidEnterBackground(_ notification: Notification) {
        pause()
    }
    
    // 播放完成通知
    @objc fileprivate func moviePlayDidEnd(_ notification: Notification) {
        self.showToolBar()
        self.startToolBarTimer()
        pause()

        removeFromSuperview()
        delegate?.playFinished()
    }
    
    // 屏幕旋转
    @objc fileprivate func statusBarOrientationChange(_ notification: Notification) {
        if isAutoFull == false {
            return
        }
        let orientation = UIDevice.current.orientation
        if orientation == UIDeviceOrientation.landscapeLeft {
            self.fullScreenWithDirection(.left)
        } else if orientation == UIDeviceOrientation.landscapeRight {
            self.fullScreenWithDirection(.right)
        } else if orientation == UIDeviceOrientation.portrait {
            self.originalScreen()
        }
    }
}

extension ADPlayerView{
    fileprivate func setupUI(){
        //添加playerlayer
        AddPlayerLayer()
        //1.添加顶部视图
        AddTopView()
        //2.添加底部视图
        AddBottomView()
        //添加中间菊花等
        AdMidView()
        //添加手势
        addTapGes()
    }
    fileprivate func AddPlayerLayer(){
        // 播放器layer
        playerLayer.videoGravity = AVLayerVideoGravityResizeAspect
        playerLayer.backgroundColor = UIColor.black.cgColor
        self.layer.addSublayer(playerLayer)
        // 播放器最上边的遮盖view
        coverView = UIView(frame:(CGRect(x: 0, y: playerLayer.frame.minY, width: playerLayer.frame.width, height: playerLayer.frame.height)))
        self.addSubview(coverView)
    }
    fileprivate func AddTopView(){
        // 底部进度条view
        topView = UIView(frame: CGRect(x: 0, y: 0, width: coverView.width, height: toolBarViewH))
        topView.backgroundColor = RGB_COLOR(0, g: 0, b: 0, alpha: 0.6)
        coverView.addSubview(topView)
        backBtn = UIButton(frame:(CGRect(x: FIT_SCREEN_WIDTH(10), y: 10, width: FIT_SCREEN_WIDTH(20), height: FIT_SCREEN_WIDTH(20))))
//        backBtn.y = (navigationHeight - backBtn.height) * 0.5
        backBtn.setBackgroundImage(UIImage(named: "icon_video_return"), for: UIControlState())
        backBtn.addTarget(self, action: #selector(backBtnDidClicked), for: UIControlEvents.touchUpInside)
        topView.addSubview(backBtn)
        
        titleLB.frame = CGRect(x: 40, y: 10, width: topView.width - 50, height: 20)
        titleLB.textColor = UIColor.white
        titleLB.font = UIFont.systemFont(ofSize: 15)
        topView.addSubview(titleLB)
    }
    fileprivate func AdMidView(){
        // 菊花转
        loadingView = UIActivityIndicatorView.init(activityIndicatorStyle: UIActivityIndicatorViewStyle.white)
        loadingView.center = coverView.center
        self.addSubview(loadingView)
    }
    fileprivate func AddBottomView(){
        // 底部进度条view
        toolBarView = UIView(frame: CGRect(x: 0, y: coverView.height-toolBarViewH, width: coverView.width, height: toolBarViewH))
        toolBarView.backgroundColor = RGB_COLOR(0, g: 0, b: 0, alpha: 0.6)
        coverView.addSubview(toolBarView)
        //播放按钮
        toolBarView.addSubview(playOrPauseBtn)
        playOrPauseBtn.frame = CGRect(x: Padding, y: 0, width: FIT_SCREEN_WIDTH(15), height: FIT_SCREEN_WIDTH(18))
        playOrPauseBtn.y = toolBarView.height/2.0 - playOrPauseBtn.height/2.0
        playOrPauseBtn.setBackgroundImage(UIImage(named: "video_pauseBtn"), for: UIControlState.selected)
        playOrPauseBtn.setBackgroundImage(UIImage(named: "video_playBtn"), for: UIControlState())
        playOrPauseBtn.addTarget(self, action: #selector(startAction(_:)), for: UIControlEvents.touchUpInside)
        
        //左侧的时间
        if beginTimeLabel.text == nil {
            beginTimeLabel.text = initTimeString
        }
        let totalTimeStr = endTimeLabel.text ?? initTimeString//取总时长算宽度，避免开始时当前时间字符串长度小于总的
        let leftTimeWidth = textSizeWithString(totalTimeStr, font: beginTimeLabel.font, maxSize: CGSize(width: toolBarView.width, height: toolBarView.height)).width + FIT_SCREEN_WIDTH(5)
        beginTimeLabel.frame =  CGRect(x: 0, y: 0, width: leftTimeWidth, height: Padding)
        beginTimeLabel.centerY = playOrPauseBtn.centerY
        beginTimeLabel.x = playOrPauseBtn.right + Padding
        beginTimeLabel.textColor = UIColor.white
        beginTimeLabel.font = AUTO_FONT(12.0)
        beginTimeLabel.textAlignment = NSTextAlignment.center
        toolBarView.addSubview(beginTimeLabel)
        
        //全屏按钮
        fullScreenBtn.frame = CGRect(x: 0, y: 0, width: FIT_SCREEN_WIDTH(25), height: FIT_SCREEN_WIDTH(25))
        fullScreenBtn.right = toolBarView.right - Padding
        fullScreenBtn.y = toolBarView.height/2 - fullScreenBtn.height/2
        if isFullScreen == true {
            fullScreenBtn.setBackgroundImage(UIImage(named: "video_minBtn"), for: UIControlState())
        } else {
            fullScreenBtn.setBackgroundImage(UIImage(named: "video_maxBtn"), for: UIControlState())
        }
        fullScreenBtn.addTarget(self, action: #selector(maxBtnClicked), for: UIControlEvents.touchUpInside)
        toolBarView.addSubview(fullScreenBtn)
        
        //右侧时间
        if endTimeLabel.text == nil {
            endTimeLabel.text = initTimeString
        }
        let rightTotalTimeStr = endTimeLabel.text
        let rightTimeWidth = textSizeWithString(rightTotalTimeStr!, font: endTimeLabel.font, maxSize: CGSize(width: toolBarView.width, height: toolBarView.height)).width + FIT_SCREEN_WIDTH(5)
        endTimeLabel.frame = CGRect(x: 0, y: 0, width: rightTimeWidth, height: Padding)
        endTimeLabel.centerY = beginTimeLabel.centerY
        endTimeLabel.right = fullScreenBtn.x - Padding
        
        endTimeLabel.textColor = UIColor.white
        endTimeLabel.font = beginTimeLabel.font
        endTimeLabel.textAlignment = NSTextAlignment.center
        toolBarView.addSubview(endTimeLabel)
        
        //进度缓冲条
        toolBarView.addSubview(progressView)
        let progressX = beginTimeLabel.right + Padding
        progressView.frame = CGRect(x: progressX, y: 0, width: endTimeLabel.x - progressX - Padding, height: Padding)
        progressView.centerY = playOrPauseBtn.centerY
        progressView.trackTintColor = ProgressColor //进度条颜色
        progressView.progressTintColor = ProgressTintColor
        
        //拖拽视频进度的slider
        toolBarView.addSubview(progressSlider)
        progressSlider.frame = CGRect(x: progressView.x - 2, y: 0, width: progressView.width + 4, height: toolBarViewH)
        progressSlider.centerY = progressView.centerY
        toolBarView.addSubview(progressSlider)
        var image = UIImage(named: "video_round") //红点
        image = image?.scaleImageToSize(size: CGSize(width: FIT_SCREEN_WIDTH(15), height: FIT_SCREEN_WIDTH(15)))
        progressSlider.setThumbImage(image, for: UIControlState.normal)
        progressSlider.minimumValue = 0
        progressSlider.maximumValue = 1 // 总共时长
        progressSlider.minimumTrackTintColor = PlayFinishColor
        progressSlider.maximumTrackTintColor = UIColor.clear
        progressSlider.addTarget(self, action: #selector(sliderIsDraging(slider:)), for: .valueChanged)
        progressSlider.addTarget(self, action: #selector(sliderStartDrag(slider:)), for: .touchDown)
        progressSlider.addTarget(self, action: #selector(sliderEndDrag(slider:)), for: .touchUpInside)
        progressSlider.addTarget(self, action: #selector(sliderEndDrag(slider:)), for: .touchDragExit)
        progressSlider.addTarget(self, action: #selector(sliderEndDrag(slider:)), for: .touchDragOutside)
    }
    fileprivate func addTapGes(){
        // 屏幕点击手势
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapGes(tap:)))
        tapGesture.delegate = self
        self.addGestureRecognizer(tapGesture)
        // 屏幕滑动手势
        let panGesture = UIPanGestureRecognizer.init(target: self, action: #selector(viewPanGes(pan:)))
        panGesture.delegate = self
        self.addGestureRecognizer(panGesture)
    }
}
//一些点击方法
extension ADPlayerView{
    //释放定时器
    fileprivate func invalidateToolBarTimer(){
        toolBarTimer?.invalidate()
        toolBarTimer = nil
    }
    // 返回按钮点击
    @objc fileprivate func backBtnDidClicked() {
        UIApplication.shared.isStatusBarHidden = false
        if isFullScreen == true {
            if isWindow == true{
                smallScreen()
                return
            }else{
            // 全屏 返回半屏
            originalScreen()
            return
            }
        }
        delegate?.videoViewBackButtonClicked()
        pauseVideo()
        removeFromSuperview()
    }
    // 半屏
     func originalScreen() {
        isFullScreen = false
        UIApplication.shared.isStatusBarHidden = false
        UIView.animate(withDuration: 0.25, animations: {
            self.transform = CGAffineTransform.identity
        })
        self.frame = customFarme
        playerLayer.frame = CGRect(x: 0, y: 0, width: customFarme.size.width, height: customFarme.size.height)
        contentView.addSubview(self)
        
        _ = self.subviews.map (
            { $0.removeFromSuperview() }
        )
        setupUI()
    }
    //放在window上
    func smallScreen() {
        isFullScreen = false
        customFarme = CGRect(x: SCREEN_WIDTH*0.5, y: SCREEN_HEIGHT - 49 + 40 - (SCREEN_WIDTH/2)*0.75, width: SCREEN_WIDTH*0.5, height: (SCREEN_WIDTH*0.5)*0.75)
        UIView.animate(withDuration: 0.25, animations: {
            self.transform = CGAffineTransform.identity
        })
        self.frame = customFarme
        playerLayer.frame = CGRect(x: 0, y: 0, width: customFarme.size.width, height: customFarme.size.height)
        UIApplication.shared.keyWindow?.addSubview(self)
        _ = self.subviews.map (
            { $0.removeFromSuperview() }
        )
        setupUI()
    }
    //返回cell播放
    func backToCell(_ cell : HomeViewCell) {
        isFullScreen = false
        UIView.animate(withDuration: 0.25, animations: {
            self.transform = CGAffineTransform.identity
        })
        customFarme = cell.iconView.bounds
        self.frame = customFarme
        playerLayer.frame = CGRect(x: 0, y: 0, width: customFarme.size.width, height: customFarme.size.height)
        cell.iconView.addSubview(self)
        _ = self.subviews.map (
            { $0.removeFromSuperview() }
        )
        setupUI()
    }
    // 播放暂停按钮方法
    @objc fileprivate func startAction(_ button: UIButton) {
        if button.isSelected == true {
            pauseVideo()
        } else {
            playVideo()
        }
    }
    // 开始、继续播放
    func playVideo() {
        player.play()
        playOrPauseBtn.isSelected = true
    }
    // 暂停播放
     func pauseVideo() {
        player.pause()
        playOrPauseBtn.isSelected = false
    }
    //全屏按钮点击
    @objc fileprivate func maxBtnClicked() {
        if isFullScreen == false {
            fullScreenWithDirection(RotateDirection.left)
        } else {
            if isWindow == true {
                smallScreen()
            }else{
                originalScreen()
            }
        }
    }
    //全屏操作
    func fullScreenWithDirection(_ direction: RotateDirection) {
        
        isFullScreen = true
        UIApplication.shared.isStatusBarHidden = true
        window?.addSubview(self)
        
        UIView.animate(withDuration: 0.25, animations: {
            if direction == RotateDirection.left {
                self.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi/2))
            } else if direction == RotateDirection.right {
                self.transform = CGAffineTransform(rotationAngle: -CGFloat(Double.pi/2))
            }
        })
        self.frame = CGRect(x: 0, y: 0, width: SCREEN_WIDTH, height: SCREEN_HEIGHT)
        playerLayer.frame = CGRect(x: 0, y: 0, width: SCREEN_HEIGHT, height: SCREEN_WIDTH)
        
        _ = self.subviews.map (
            { $0.removeFromSuperview() }
        )
        setupUI()
    }
}
//滚动条方法
extension ADPlayerView{
    
//     滑条开始拖动
       @objc fileprivate func sliderStartDrag(slider: UISlider) {
            // 避免拖动过程中工具条自动消失
            invalidateToolBarTimer()
            showToolBar()
    
            isDragging = true // 标记开始拖动
            pauseVideo() // 暂停播放
        }
    // 显示工具条(外部需要用到)
         func showToolBar() {
            if isFullScreen {
                UIView.animate(withDuration: DisapperAnimateDuration, animations: {
                    self.coverView.alpha = 1
                    self.backBtn.alpha = 1
                })
            } else {
                UIView.animate(withDuration: DisapperAnimateDuration, animations: {
                    self.coverView.alpha = 1
                })
            }
        }
    
    
    //滑条正在拖拽
    @objc fileprivate func sliderIsDraging(slider: UISlider) {
        if player.status == AVPlayerStatus.readyToPlay {
            // 改变视频进度
            changeVideoProgress(changeType: .sliderPan)
        }
    }
    //改变视频进度
    fileprivate func changeVideoProgress(changeType: ProgressChangeType) {
        
        let timescaleT = playerItem?.duration.timescale ?? 0
        if timescaleT == 0 {
            return
        }
        playerItem?.cancelPendingSeeks()
        
        if changeType == .panGuesture { // 通过屏幕手势拖拽
            progressSlider.value -= Float((firstPoint.x - secondPoint.x) / 300)
        }
        
        let durationT = playerItem?.duration.value ?? 0
        let total = Float64(durationT) / Float64(timescaleT)
        //计算出拖动的当前秒数
        let dragedSeconds = floorf(Float(total * Float64(progressSlider.value)))
        let dragedCMTime = CMTimeMake(Int64(dragedSeconds), 1)
        // 刷新时间
        refreshTimeLabelValue(dragedCMTime)
        // 刷新进度
        DispatchQueue.main.async {
            self.seekToVideo(Int(dragedSeconds))
        }
    }
    @discardableResult
    func refreshTimeLabelValue(_ time: CMTime) -> String {
        
        let timescale = playerItem?.duration.timescale ?? 0
        if Int64(timescale) == 0 || CMTimeGetSeconds(time).isNaN {
            return String(format: "%02ld:%02ld", 0, 0)
        }
        
        // 当前时长进度progress
        let proMin = Int64(CMTimeGetSeconds(time)) / 60//当前分钟
        let proSec = Int64(CMTimeGetSeconds(time)) % 60//当前秒
        // duration 总时长
        let durationT = playerItem?.duration.value ?? 0
        let durMin = Int64(durationT) / Int64(timescale) / 60//总分钟
        let durSec = Int64(durationT) / Int64(timescale) % 60//总秒
        
        let leftTimeStr = String(format: "%02ld:%02ld", proMin, proSec )
        let rightTimeStr = String(format: "%02ld:%02ld", durMin, durSec )
        
        beginTimeLabel.text = leftTimeStr
        endTimeLabel.text = rightTimeStr
        totalTime = Int(durMin * 60 + durSec)
        currentTime = Int(proMin * 60 + proSec)
        
        return rightTimeStr
    }
    // 调整视频进度
    func seekToVideo(_ startTime: Int) {
        let time = startTime < 0 ? 0 : startTime
        // 定位精度较差，但是性能比较高
        //        player.seek(to: CMTimeMakeWithSeconds(Float64(time), 1))
        // 定位最为精确，但是性能很差
        player.seek(to: CMTimeMakeWithSeconds(Float64(time), 1), toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
    }
    // 启动转子
    func startLoadingAnimation() {
        loadingView.startAnimating()
    }
    // 停止转子
    func stopLoadingAnimation() {
        loadingView.stopAnimating()
    }
    
    
    // 滑条结束拖拽
    func sliderEndDrag(slider: UISlider) {
        isDragging = false // 标记拖动完成
        startToolBarTimer() // 定时器，工具条消失
        playVideo() // 继续播放
    }
    //开启定时器
    func startToolBarTimer() {
        showToolBar() // 显示出工具条
        toolBarTimer = Timer.scheduledTimer(timeInterval: 6.0, target: self, selector: #selector(hiddenToolBar), userInfo: nil, repeats: false) // 6秒后自动隐藏
        RunLoop.current.add(toolBarTimer!, forMode: RunLoopMode.defaultRunLoopMode)
    }
    // 隐藏、显示工具条
    func hiddenToolBar() {
        if isFullScreen {
            UIView.animate(withDuration: DisapperAnimateDuration, animations: {
                self.coverView.alpha = 0
                self.backBtn.alpha = 0
            })
        } else {
            UIView.animate(withDuration: DisapperAnimateDuration, animations: {
                self.coverView.alpha = 0
            })
        }
    }
}
//屏幕手势方法
extension ADPlayerView{
    // 屏幕点击手势
    @objc fileprivate func viewTapGes(tap: UITapGestureRecognizer) {
        if coverView.alpha == 1 {
            invalidateToolBarTimer()
            hiddenToolBar()
        } else if coverView.alpha == 0 {
            startToolBarTimer()
        }
    }
    
    //屏幕滑动手势
    func viewPanGes(pan: UIPanGestureRecognizer) {
        if pan.state == UIGestureRecognizerState.began { // 开始拖动
            isDragging = true // 标记开始拖动
            pauseVideo() // 暂停播放
            dragDirection = .none
            
            // 避免拖动过程中工具条自动消失
            invalidateToolBarTimer()
            showToolBar()
            firstPoint = pan.location(in: self)
        } else if pan.state == UIGestureRecognizerState.ended { // 结束拖动
            
            isDragging = false // 标记拖动完成
            startToolBarTimer() // 开启工具条定时器
            playVideo() // 继续播放
            
        } else if pan.state == UIGestureRecognizerState.changed { // 正在拖动
            secondPoint = pan.location(in: self)
            
            // 判断是左右滑动还是上下滑动
            let horValue = fabs(firstPoint.x - secondPoint.x) // 水平方向
            let verValue = fabs(firstPoint.y - secondPoint.y) // 竖直方向
            
            // 确定本次手势操作是水平滑动还是竖直滑动，避免一次手势操作中出现水平和竖直先后都出现的情况
            // 比如先向右滑动30，然后继续向上滑动50，就会出现一次手势操作中先调节视频进度又调节了音量
            if dragDirection == .none {
                if horValue > verValue {
                    dragDirection = .horizontal
                } else {
                    dragDirection = .vertical
                }
            }
            if dragDirection == .horizontal { // 左右滑动
                // 调节视频的播放进度
                changeVideoProgress(changeType: .panGuesture)
            }
            firstPoint = secondPoint
        }
    }
}
//manager需要用到的方法
extension ADPlayerView{
    // 计算缓冲进度
    fileprivate func availableDuration() -> TimeInterval {
        guard let timeRange = playerItem?.loadedTimeRanges.first?.timeRangeValue else {
            return 0
        }
        let startSeconds = CMTimeGetSeconds(timeRange.start)
        let durationSeconds = CMTimeGetSeconds(timeRange.duration)
        let result = startSeconds + durationSeconds // 计算缓冲总进度
        return result
    }
    // 设置缓冲条进度(外部需要用到)
     func setProgressValue() {
        let timeInterval = availableDuration() // 计算缓冲进度
        guard let duration = playerItem?.duration else {
            return
        }
        if CMTimeGetSeconds(duration).isNaN {
            return
        }
        let totalDuration = CMTimeGetSeconds(duration)
        if TimeInterval(totalDuration) == 0 {
            return
        }
        progressView.setProgress(Float(TimeInterval(timeInterval) / TimeInterval(totalDuration)), animated: false)
    }
    
    // 定时刷新监听
    func refreshShowValues() {
        
        let durationT = playerItem?.duration.value ?? 0
        let timescaleT = playerItem?.duration.timescale ?? 0
        if (TimeInterval(durationT) == 0) || (TimeInterval(timescaleT) == 0) {
            return
        }
        guard let currentT = playerItem?.currentTime() else {
            return
        }
        if CMTimeGetSeconds(currentT).isNaN {
            return
        }
        if isDragging == false { // 当没有正在拖动进度时，才刷新时间和进度条
            let currentTime = CMTimeGetSeconds(currentT)
            // 显示时间
            refreshTimeLabelValue(CMTimeMake(Int64(currentTime), 1))
            progressSlider.value = Float(TimeInterval(currentTime) / (TimeInterval(durationT) / TimeInterval(timescaleT)))
        }
        // 开始播放停止转子
        if (player.status == AVPlayerStatus.readyToPlay) {
            stopLoadingAnimation()
        } else {
            startLoadingAnimation()
        }
    }
    
    // 重新计算时间和滑条的frame
    func resizeTimeLabel() {
        guard let currentTime = playerItem?.currentTime() else {
            return
        }
        if CMTimeGetSeconds(currentTime).isNaN {
            return
        }
        let timeSecond = CMTimeGetSeconds(currentTime)
        let totalTimeStr = refreshTimeLabelValue(CMTimeMake(Int64(timeSecond), 1))
        
        let contantSize = CGSize(width: SCREEN_WIDTH, height: SCREEN_HEIGHT)
        //左侧时间宽度
        let leftTimeWidth = textSizeWithString(totalTimeStr, font: beginTimeLabel.font, maxSize: contantSize).width
        beginTimeLabel.width = leftTimeWidth + FIT_SCREEN_WIDTH(5)
        beginTimeLabel.x = playOrPauseBtn.right + Padding
        //右侧时间宽度
        let EndtimelabelW = textSizeWithString(totalTimeStr, font: endTimeLabel.font, maxSize: contantSize).width
        endTimeLabel.width = EndtimelabelW + FIT_SCREEN_WIDTH(5)
        endTimeLabel.right = fullScreenBtn.x - Padding
        // 进度条
        let progressX = beginTimeLabel.right + Padding
        progressView.x = progressX
        progressView.width = endTimeLabel.x - progressX - Padding
        progressSlider.x = progressView.x - 2 //空隙补偿
        progressSlider.width = progressView.width + 4
    }
}
