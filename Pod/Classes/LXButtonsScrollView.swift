//
//  LXButtonsScrollView.swift
//  Pods
//
//  Created by XianLi on 29/7/2016.
//
//

import UIKit

extension NSAttributedString {
    func heightWithConstrainedWidth(width: CGFloat) -> CGFloat {
        let constraintRect = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: NSStringDrawingOptions.usesLineFragmentOrigin, context: nil)
        
        return boundingBox.height
    }
    
    func widthWithConstrainedHeight(height: CGFloat) -> CGFloat {
        let constraintRect = CGSize(width: CGFloat.greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(with: constraintRect, options: NSStringDrawingOptions.usesLineFragmentOrigin, context: nil)
        
        return boundingBox.width
    }
}

public class LXButtonsScrollView: UIScrollView {
    /// config global appearce settings via LXButtonsScrollView.appreance
    public static var appearance:Appearance = Appearance()
    /// local appearance settings
    public var appearance:Appearance = LXButtonsScrollView.appearance
    
    public var selectionIndicator: UIView
    public var buttons: [UIButton]
    private var buttonTitles: [String]
    
    override public init(frame: CGRect) {
        buttons = []
        buttonTitles = []
        selectionIndicator = UIView()
        super.init(frame: frame)
        
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator   = false
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// setup buttons with a list of button titles
    /// expected to be executed on the main thread
    public func setButtonTitles(titles: [String]) {
        buttonTitles = titles
        
        /// remove (if) any previous added buttons
        buttons.forEach { $0.removeFromSuperview() }
        
        /// create buttons
        buttons = titles.map { (title) -> UIButton in
            let attrTitle = NSAttributedString.init(string: title,
                attributes: [
                    NSAttributedStringKey.font: appearance.button.font.normal,
                    NSAttributedStringKey.foregroundColor: appearance.button.foregroundColor.normal
                ])
            let attrTitleSelected = NSAttributedString.init(string: title,
                attributes: [
                    NSAttributedStringKey.font: appearance.button.font.selected,
                    NSAttributedStringKey.foregroundColor: appearance.button.foregroundColor.selected
                ])
            let btn = UIButton()
            btn.titleLabel?.textAlignment = .center
            btn.setAttributedTitle(attrTitle, for: .normal)
            btn.setAttributedTitle(attrTitleSelected, for: .selected)
            //btn.titleLabel!.adjustsFontSizeToFitWidth = true
            //btn.titleLabel?.lineBreakMode=NSLineBreakMode.ByClipping
            return btn
        }
        
        /// set up size and frames
        appearance.button.count = titles.count
        self.contentSize = calContentSize()
        for (idx, btn) in buttons.enumerated() {
            btn.translatesAutoresizingMaskIntoConstraints = true
            btn.frame = calButtonFrame(index: idx)
        }
        
        /// add buttons to view
        buttons.forEach { self.addSubview($0) }
        
        /// selection indicator
        selectionIndicator.translatesAutoresizingMaskIntoConstraints = true
        selectionIndicator.backgroundColor = appearance.selectionIndicator.color
        self.addSubview(selectionIndicator)
        self.bringSubview(toFront: selectionIndicator)
    }
    
    /// frame calculation functions
    public func calContentSize() -> CGSize {
        var width : CGFloat = 0.0
        buttons.forEach {
            width += ($0.attributedTitle(for: .normal)?.widthWithConstrainedHeight(height: appearance.button.height))! + appearance.button.gap
        }
        width  += CGFloat(appearance.button.count - 1) * appearance.button.gap + appearance.button.margin.left + appearance.button.margin.right
        let height = appearance.button.height + appearance.button.margin.top + appearance.button.margin.bottom
        return   CGSize(width:width, height:height)
    }
    
    public func calButtonFrame(index: Int) -> CGRect {
        _ = CGFloat(index)
        let btn = buttons[index]
        var x : CGFloat = 0
        if index != 0 {
            let btnBefore = buttons[index-1]
            x = btnBefore.frame.origin.x + btnBefore.frame.size.width
        }
        
        let width = (btn.attributedTitle(for: .normal)?.widthWithConstrainedHeight(height: appearance.button.height))! + appearance.button.gap
        return CGRect(x:x + appearance.button.margin.left,
                      y:appearance.button.margin.top,
                      width:width,
                      height:appearance.button.height)
    }
    public func selectionIndicatorFrame(idx: Int) -> CGRect {
        let btnframe = calButtonFrame(index: idx)
        return CGRect(x: btnframe.origin.x , y: appearance.button.margin.top + appearance.button.height - appearance.selectionIndicator.height, width: btnframe.size.width, height: appearance.selectionIndicator.height)
    }
    
    /// visibility checking function
    public func isButtonVisible(idx: Int) -> Bool {
        let btnFrame = calButtonFrame(index: idx)
        return self.bounds.minX <= btnFrame.minX &&
                self.bounds.maxX >= btnFrame.maxX &&
                self.bounds.minY <= btnFrame.minY &&
                self.bounds.maxY >= btnFrame.maxY
    }
}
