//
//  WHPlayerBottomView.swift
//  YYMusic
//
//  Created by 王浩 on 2020/5/18.
//  Copyright © 2020 haoge. All rights reserved.
//

import UIKit
import Kingfisher
import MarqueeLabel

class WHPlayerBottomView: UIView {
    static let shared = WHPlayerBottomView()
    var musicModel: MusicModel?
    /*圆环进度指示器*/
    var progress: CGFloat = 0.0 {
        didSet{
            if progress > 1 || progress < 0 { return }
            arcLayer.removeFromSuperlayer()
            drawCircle(rect: playAndPauseBtn.frame, progress: progress)
        }
    }

    /*播放暂停按钮*/
    var playAndPauseBtn: UIButton!
    /**播放的背景*/
    var contentView: UIControl!
    var currentMusicView: MusicView?
    fileprivate lazy var arcLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = kThemeColor.cgColor
        layer.lineWidth = 2.5
        layer.lineCap = CAShapeLayerLineCap(rawValue: "round")
        return layer
    }()
    
    fileprivate var playerBarH: CGFloat = 65.0
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
        
        contentView = UIControl()
        contentView.backgroundColor = .white
        self.addSubview(contentView)
        contentView.snp.makeConstraints { (make) in
            make.left.right.equalTo(self)
            make.bottom.equalTo(self.snp.bottom)
            make.height.equalTo(48)
        }
  
        
        playAndPauseBtn = UIButton(type: .custom)
        playAndPauseBtn.setImage(UIImage(named: "icons_play_music1"), for: .normal)
        playAndPauseBtn.setImage(UIImage(named: "icons_stop_music1"), for: .selected)
        playAndPauseBtn.addTarget(self, action: #selector(playAndPause(_:)), for: .touchUpInside)
        contentView.addSubview(playAndPauseBtn)
        playAndPauseBtn.snp.makeConstraints { (make) in
            make.height.width.equalTo(35)
            make.right.equalTo(contentView.snp.right).offset(-10)
            make.centerY.equalTo(contentView.snp.centerY)
        }
        
        drawCircle(rect: playAndPauseBtn.frame, progress: 0.0)
        //注册监听
        NotificationCenter.addObserver(observer: self, selector: #selector(musicChange(_:)), name: .kMusicChange)
        NotificationCenter.addObserver(observer: self, selector: #selector(musicTimeInterval), name: .kMusicTimeInterval)
        NotificationCenter.addObserver(observer: self, selector: #selector(playStatusChange(_:)), name: .kReloadPlayStatus)
        
        //获取上次播放存储的歌曲
        if let music = UserDefaultsManager.shared.unarchive(key: CURRENTMUSIC) as? MusicModel {
            self.musicModel = music
        }
        self.updateMusic(model: self.musicModel)
        
        let scrollView = InfiniteCycleView()
        scrollView.delegate = self
        self.addSubview(scrollView)
        scrollView.snp.makeConstraints { (make) in
            make.left.top.bottom.equalTo(self)
            make.right.equalTo(self.snp.right).offset(-55)
        }
    }
    
    @objc fileprivate func musicTimeInterval() {
        let currentTime = PlayerManager.shared.getCurrentTime()
        let totalTime = PlayerManager.shared.getTotalTime()
        let cT = Double(currentTime ?? "0")
        let dT = Double(totalTime ?? "0")
        if let ct = cT, let dt = dT, dt > 0.0 {
            self.progress = CGFloat(ct/dt)
            if CGFloat(ct/dt) >= 1.0 {
                self.progress = 0.0
            }
        }
    }

    @objc fileprivate func musicChange(_ notification: Notification) {
        if let model = notification.object as? MusicModel {
            self.musicModel = model
            playAndPauseBtn.isSelected = true
            self.currentMusicView?.model = model
            self.currentMusicView?.startAnimation()
        }
    }
    
    @objc fileprivate func playStatusChange(_ notification: Notification) {
        if let isPlay = notification.object as? Bool {
            playAndPauseBtn.isSelected = isPlay
            if isPlay {
                self.currentMusicView?.startAnimation()
            } else {
                self.currentMusicView?.stopAnimation()
            }
        }
    }
    
    func updateMusic(model: MusicModel?) {
        self.musicModel = model
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //绘制进度圆环
    fileprivate func drawCircle(rect: CGRect, progress: CGFloat) {
        let xCenter = rect.size.width * 0.5
        let yCenter = rect.size.height * 0.5
        let radius = rect.size.width/2-2
        //绘制环形进度环
        // - M_PI * 0.5为改变初始位置
        let to = -CGFloat(Double.pi)*0.5 + progress * CGFloat(Double.pi)*2
        
        let path = UIBezierPath()
        path.addArc(withCenter: CGPoint(x: xCenter, y: yCenter), radius: CGFloat(radius), startAngle: -CGFloat(Double.pi)*0.5, endAngle: to, clockwise: true)
        arcLayer.path = path.cgPath  //46,169,230
        playAndPauseBtn.layer.addSublayer(arcLayer)
    }
    
    @objc func playAndPause(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if !sender.isSelected {
            tapPlayButton(isPlay: false)
        } else {
            tapPlayButton(isPlay: true)
        }
    }
    
    //继续播放
    func playActive() {
        PlayerManager.shared.playerPlay()
    }
    
    //暂停播放
    func pauseActive() {
        PlayerManager.shared.playerPause()
    }
    
    //加载播放
    func loadMusic(model: MusicModel) {
        //每次切换都要清空一下进度
        self.progress = 0.0
        self.musicModel = model
        PlayerManager.shared.playMusic(model: model)
    }
    
    //MARK:-播放按钮
    func tapPlayButton(isPlay: Bool) {
        self.playAndPauseBtn.isSelected = isPlay
        //第一次点击底部播放按钮并且还是未在播放状态
        if PlayerManager.shared.isFristPlayerPauseBtn && !PlayerManager.shared.isPlaying {
            PlayerManager.shared.isFristPlayerPauseBtn = false
            if let music = UserDefaultsManager.shared.unarchive(key: CURRENTMUSIC) as? MusicModel {
                loadMusic(model: music)
            } else {
                //归档没找到默认播放第一个
                if let model = PlayerManager.shared.currentModel {
                    loadMusic(model: model)
                }
            }
        } else {
            PlayerManager.shared.isFristPlayerPauseBtn = false
            if isPlay {
                playActive()
            } else {
                pauseActive()
            }
        }
    }

    deinit {
        NotificationCenter.removeObserver(observer: self, name: .kMusicChange)
        NotificationCenter.removeObserver(observer: self, name: .kMusicTimeInterval)
        NotificationCenter.removeObserver(observer: self, name: .kReloadPlayStatus)
        
    }
}

extension WHPlayerBottomView: InfiniteCycleViewDelegate {
    
    func infiniteCycleView(_ scrollView: InfiniteCycleView) -> UIView {
        return MusicView()
    }
    //更新当前视图
    func infiniteCycleView(currentView: UIView?) {
        if let mv = currentView as? MusicView {
            self.currentMusicView = mv
            mv.model = self.musicModel
        }
    }
    //更新前一个视图
    func infiniteCycleView(previousView: UIView?, isEndDragging: Bool) {
        if let mv = previousView as? MusicView {
            if !PlayerManager.shared.musicArray.isEmpty {
                let m = PlayerManager.shared.musicArray[PlayerManager.shared.previousIndex]
                mv.model = m
                if isEndDragging {
                    self.musicModel = m
                    PlayerManager.shared.playMusic(model: m)
                }
            }
        }
    }
    //更新下一个视图
    func infiniteCycleView(nextView: UIView?, isEndDragging: Bool) {
        if let mv = nextView as? MusicView {
            if !PlayerManager.shared.musicArray.isEmpty {
                let m = PlayerManager.shared.musicArray[PlayerManager.shared.nextIndex]
                mv.model = m
                if isEndDragging {
                    self.musicModel = m
                    PlayerManager.shared.playMusic(model: m)
                }
            }
        }
    }
    
    func infiniteCycleViewDidSelect(_ currentView: UIView?) {
        let vc = UIApplication.shared.keyWindow?.rootViewController
        PlayerManager.shared.presentPlayController(vc: vc, model: self.musicModel)
    }
}
