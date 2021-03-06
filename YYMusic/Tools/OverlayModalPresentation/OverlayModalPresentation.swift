//
//  OverlayModalPresentation.swift
//  YYMusic
//
//  Created by 王浩 on 2020/6/11.
//  Copyright © 2020 haoge. All rights reserved.
//
import UIKit

enum OverlayModalStyle {
    /**从顶向下弹出*/
    case top
    /**从底向上弹出*/
    case bottom
    /**从左向右弹出*/
    case left
    /**从右向左弹出*/
    case right
    /**中心弹出*/
    case center
}

class OverlayModalConfige: NSObject {
    /**点击阴影消失 默认点击消失*/
    var isTappedDismiss: Bool = true
    /**Y偏移量 默认150.0*/
    var offsetY: CGFloat = 150.0
    /**X偏移量 默认75.0*/
    var offsetX: CGFloat = 75.0
    /**modal样式 默认底向上*/
    var modelStyle: OverlayModalStyle = .bottom
    /**是否禁用滑动手势, 默认有滑动手势*/
    var isPanEnabled: Bool = true
}

@objc protocol OverlayModalPresentationDelegate: NSObjectProtocol {
    //获取modal视图
    func getOverlayModalView() -> Any?
    /**获取配置信息, 如果是OverlayPickerViewController*/
    @objc optional func getOverlayModalConfige() -> OverlayModalConfige
}

class OverlayModalPresentation: NSObject, UIViewControllerTransitioningDelegate {
    
    static let shared = OverlayModalPresentation()
    fileprivate weak var delegate: OverlayModalPresentationDelegate?
    
    public convenience init(delegate: OverlayModalPresentationDelegate) {
        self.init()
        self.delegate = delegate
    }
 
    func show() {
        guard let delegate = delegate else {
            print("代理getOverlayModalController没有实现")
            return
        }
        if delegate.responds(to: #selector(delegate.getOverlayModalView)) {
            var modalVC: UIViewController?
            guard let modalView = delegate.getOverlayModalView() else {
                return
            }
            
            if let vc = modalView as? UIViewController {
                modalVC = vc
            }
            
            if let view = modalView as? UIView {
                let tempVc = UIViewController()
                tempVc.view.frame = view.frame
                tempVc.view.addSubview(view)
                modalVC = tempVc
            }
            
            modalVC?.transitioningDelegate = self
            modalVC?.modalPresentationStyle = .custom
            
            var parentVc: UIViewController?
            let root = UIApplication.shared.keyWindow?.rootViewController
            if root!.isKind(of: UITabBarController.self) {
                let selectVc = (root as! UITabBarController).selectedViewController
                
                if selectVc!.isKind(of: UINavigationController.self) {
                    parentVc = (selectVc as! UINavigationController).visibleViewController
                }
                
                if (selectVc!.presentingViewController != nil) {
                    parentVc = selectVc!.presentingViewController
                }
            }
            
            if root!.isKind(of: UINavigationController.self) {
                parentVc = (root as! UINavigationController).visibleViewController
            }
            
            if (root!.presentingViewController != nil) {
                parentVc = root!.presentingViewController
            }
            
            parentVc?.present(modalVC!, animated: true, completion: nil)
        }
    }
    
    // MARK: - UIViewControllerTransitioningDelegate
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        if let d = delegate {
            let vc = OverlayPresentationController(presentedViewController:presented, presenting:presenting)
            if presented is OverlayPickerViewController {
                let confige = OverlayModalConfige()
                confige.modelStyle = .bottom
                confige.isPanEnabled = false
                confige.offsetY = UIScreen.main.bounds.height-260
                vc.confige = confige
            } else {
                if d.responds(to: #selector(d.getOverlayModalConfige)) {
                    vc.confige = d.getOverlayModalConfige!()
                }
            }
            return vc
        }
        return nil
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if let d = delegate {
            let controller = OverlayAnimatedTransitioning()
            controller.isPresentation = true
            if d.responds(to: #selector(d.getOverlayModalConfige)) {
                controller.confige = d.getOverlayModalConfige!()
            }
            return controller
        }
        return nil
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if let d = delegate {
            let controller = OverlayAnimatedTransitioning()
            controller.isPresentation = false
            if d.responds(to: #selector(d.getOverlayModalConfige)) {
                controller.confige = d.getOverlayModalConfige!()
            }
            return controller
        }
        return nil
    }
    
}
