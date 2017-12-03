//
//  LXPageViewWithButtonsViewController.swift
//
//  Created by XianLi on 23/3/2016.
//  Copyright © 2016 LXIAN. All rights reserved.
//

import Foundation
import UIKit

public protocol LXPageViewWithButtonsViewDelegate: class {
    func pageViewWithButtonsView(pageViewController: UIPageViewController, buttonsScrollView: LXButtonsScrollView, currentIndexUpdated index: Int)
}

open class LXPageViewWithButtonsViewController: UIViewController, UIPageViewControllerDelegate {
    /// delegate
    public weak var pageViewWithButtonsViewDelegate: LXPageViewWithButtonsViewDelegate?
    
    /// page view controller
    public let pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    /// the scrollView inside the pageViewController
    private var _pageViewScrollView: UIView?
    var pageViewScrollView : UIView? {
        if _pageViewScrollView == nil {
            var views : [UIView] = [pageViewController.view]
            while views.count > 0 {
                let view = views[0]
                if view is UIScrollView {
                    _pageViewScrollView = view
                    break
                }
                views.append(contentsOf: view.subviews)
                views.remove(at: 0)
            }
        }
        return _pageViewScrollView
    }
    /// buttons
    public let buttonsScrollView: LXButtonsScrollView = LXButtonsScrollView()
    /// data source required by UIpageViewController
    let pageViewControllerDataSource = LXPageViewWithButtonsViewControllerDataSource()
    
    /// page index
    var targetIndex: Int?
    public var currentIdx = 0 {
        didSet {
            currentIdxUpdated()
        }
    }
    public func currentIdxUpdated() {
        buttonsScrollView.buttons.forEach { $0.isSelected = false }
        buttonsScrollView.buttons[currentIdx].isSelected = true
        
        /// scroll the scroll view if needed
        /// if the target button is already visible, then no need to scorll the view
        if !(targetIndex != nil && buttonsScrollView.isButtonVisible(idx: targetIndex!)) {
            DispatchQueue.main.async { [weak self] in
                self?.scrollButtonsViewToCurrentIndex()
            }
        }
        
        if currentIdx == targetIndex {
            targetIndex = nil
        }
        
        pageViewWithButtonsViewDelegate?.pageViewWithButtonsView(pageViewController: pageViewController, buttonsScrollView: buttonsScrollView, currentIndexUpdated: currentIdx)
    }
    
    public var viewControllers : [UIViewController]? {
        didSet {
            pageViewControllerDataSource.viewControllers = self.viewControllers
        }
    }
    public var currentViewController: UIViewController? {
        return viewControllers?[currentIdx]
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        setupPageViewController()
        setupButtons()
    }
    
    private var viewAppearedOnce = false
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !viewAppearedOnce {
            setupButtons()
            pageViewController.setViewControllers([viewControllers![0]], direction: .forward, animated: false, completion: nil)
            viewAppearedOnce = true
        }
    }
    
    deinit {
        pageViewScrollView?.removeObserver(self, forKeyPath: "contentOffset")
    }
    
    open override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        lx_LayoutViews()
    }
    
    /// layout buttonsScrollView and page view controller's view 
    /// override this function if you want other layout
    public func lx_LayoutViews() {
        /// layout the buttons scroll view
        view.addSubview(buttonsScrollView)
        buttonsScrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: buttonsScrollView, attribute: .centerX, relatedBy: .equal, toItem: self.view, attribute: .centerX, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: buttonsScrollView, attribute: .top, relatedBy: .equal, toItem: self.topLayoutGuide, attribute: .bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: buttonsScrollView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: buttonsScrollView.appearance.button.height),
            NSLayoutConstraint(item: buttonsScrollView, attribute: .width, relatedBy: .equal, toItem: self.view, attribute: .width, multiplier: 1, constant: 0)
            ])
        
        /// layout page view controllers' view
        let pageViewControllerView = pageViewController.view!
        pageViewControllerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: pageViewControllerView, attribute: .centerX, relatedBy: .equal, toItem: self.view, attribute: .centerX, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: pageViewControllerView, attribute: .top, relatedBy: .equal, toItem: buttonsScrollView, attribute: .bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: pageViewControllerView, attribute: .bottom, relatedBy: .equal, toItem: self.bottomLayoutGuide, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: pageViewControllerView, attribute: .width, relatedBy: .equal, toItem: self.view, attribute: .width, multiplier: 1, constant: 0)
            ])
    }
    
    // MARK: - Setups
    public func setupButtons() {
        guard let viewControllers = viewControllers else { return }
        buttonsScrollView.setButtonTitles( titles: viewControllers.map{ return $0.title ?? "" })
        
        for (idx, btn) in buttonsScrollView.buttons.enumerated() {
            btn.tag = idx
            btn.addTarget(self, action: #selector(LXPageViewWithButtonsViewController.selectionButtonTapped(btn:)), for: .touchUpInside)
        }
        
        buttonsScrollView.buttons[currentIdx].isSelected = true
        buttonsScrollView.selectionIndicator.frame = buttonsScrollView.selectionIndicatorFrame(idx: currentIdx)
    }
    
    public func setupPageViewController() {
        if viewControllers == nil { return }
        
        pageViewController.dataSource = pageViewControllerDataSource
        pageViewController.delegate = self
        
        self.view.addSubview(pageViewController.view)
        self.addChildViewController(pageViewController)
        pageViewController.didMove(toParentViewController: self)
        
        pageViewScrollView?.addObserver(self, forKeyPath: "contentOffset", options: .new, context: &LXPageViewWithButtonsViewControllerScrollingViewContentOffsetXContext)
    }
    
    var LXPageViewWithButtonsViewControllerScrollingViewContentOffsetXContext : Int32 = 0
    
    // MARK: - Selection Indicator
    @objc
    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &LXPageViewWithButtonsViewControllerScrollingViewContentOffsetXContext {
            guard let offset = (change?[NSKeyValueChangeKey.newKey] as AnyObject).cgPointValue else {
                return
            }
            updateSelectionIndicatorPosition(offsetX: offset.x)
            return
        }
        super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
    }
    
    public func updateSelectionIndicatorPosition(offsetX: CGFloat) {
        var frame = buttonsScrollView.selectionIndicatorFrame(idx: currentIdx)
        guard let pageViewScrollView = pageViewScrollView else { return }
        let tabOffset = ((offsetX - pageViewScrollView.frame.size.width) / pageViewScrollView.frame.size.width) * frame.width
        
        
        let percetageMovment =  tabOffset / frame.width
        var nextBtnFrame = buttonsScrollView.selectionIndicatorFrame(idx: currentIdx)
        if percetageMovment < 0 && currentIdx != 0 {
            nextBtnFrame = buttonsScrollView.calButtonFrame(index: currentIdx-1)
            //TODO MAKE IT GENERIC
            let oldWidth = frame.size.width
            frame.size.width = (1-abs(percetageMovment)) * frame.size.width + abs(percetageMovment) * nextBtnFrame.size.width
            frame.origin.x +=  tabOffset - (frame.size.width - oldWidth)
        }else if percetageMovment > 0 && currentIdx != (viewControllers?.count)!-1 {
            nextBtnFrame = buttonsScrollView.calButtonFrame(index: currentIdx+1)
            frame.origin.x += tabOffset
            frame.size.width = (1-percetageMovment) * frame.size.width + percetageMovment * nextBtnFrame.size.width
        }
        
        
        
        buttonsScrollView.selectionIndicator.frame = frame
    }
    
    @objc func scrollButtonsViewToCurrentIndex() {
        let targetRect = buttonsScrollView.calButtonFrame(index: currentIdx)
        buttonsScrollView.scrollRectToVisible(targetRect, animated: true)
    }
    
    // MARK: - Buttons
    @objc public func selectionButtonTapped(btn: UIButton) {
        let idx = btn.tag
        /// set the target index for scrolling buttons view purpose
        targetIndex = idx
        let vcs = viewControllers!
        //guard let vcs = viewControllers where idx >= 0 && idx < vcs.count else {
        //    return
        //}
        
        if idx == currentIdx {
            return
        }
        
        let dir : UIPageViewControllerNavigationDirection = currentIdx < idx ? .forward :  .reverse
        var nextIdx = currentIdx
        setIndex(idx: targetIndex!)
/*
        while nextIdx != idx  {
            nextIdx  += ((dir == .Forward) ? 1 : -1)
            dispatch_async(dispatch_get_main_queue(), { [weak self, nextIdx, vcs, dir] in
                guard let bself = self else { return }
                /// set the view controllers to be displayed
                bself.pageViewController.setViewControllers([vcs[nextIdx]], direction: dir, animated: true) { (finished) in
                    if finished {
                        bself.currentIdx = nextIdx
                    }
                }
                })
        }*/
    }
    
    // MARK: - Controls
    public func setIndex(idx: Int) {
        guard let viewControllers = viewControllers else { return }
        
        if idx >= viewControllers.count { return }
        
        self.pageViewController.setViewControllers([viewControllers[idx]], direction: .forward , animated: false, completion: nil)
        currentIdx = idx
        
        guard let pageViewScrollView = pageViewScrollView else { return }
        DispatchQueue.main.async { [weak self] in
            guard let bself = self else { return }
            bself.updateSelectionIndicatorPosition(offsetX: pageViewScrollView.frame.size.width)
        }
    }
    
    public func reset() {
        setIndex(idx: 0)
    }
    
    // MARK: - UIPageViewControllerDelegate
    public func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
    }
    
    public func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed {
            guard let curVC = pageViewController.viewControllers?.last,
                let newCurIdx = viewControllers?.index(of: curVC) else { return }
            self.currentIdx = newCurIdx
        }
    }
    
}
