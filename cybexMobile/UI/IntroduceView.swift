//
//  IntroduceView.swift
//  cybexMobile
//
//  Created by DKM on 2018/7/1.
//  Copyright © 2018年 Cybex. All rights reserved.
//

import UIKit
import SwiftRichString


@IBDesignable
class IntroduceView: UIView {

    @IBOutlet weak var content: UILabel!
    
    
    @IBInspectable
    var locail : String?{
        didSet{
          if let locail = self.locail{
            self.content.attributedText = locail.set(style: StyleNames.withdraw_introduce.rawValue)
          }
        }
    }
    
  func setup(){
    
  }
  
  override var intrinsicContentSize: CGSize {
    return CGSize.init(width: UIViewNoIntrinsicMetric,height: dynamicHeight())
  }
  
  fileprivate func updateHeight() {
    layoutIfNeeded()
    self.height = dynamicHeight()
    invalidateIntrinsicContentSize()
  }
  
  fileprivate func dynamicHeight() -> CGFloat {
    let lastView = self.subviews.last?.subviews.last
    return lastView!.bottom
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    layoutIfNeeded()
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    loadViewFromNib()
    setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    loadViewFromNib()
    setup()
  }
  
  fileprivate func loadViewFromNib() {
    let bundle = Bundle(for: type(of: self))
    let nibName = String(describing: type(of: self))
    let nib = UINib.init(nibName: nibName, bundle: bundle)
    let view = nib.instantiate(withOwner: self, options: nil).first as! UIView
    
    addSubview(view)
    view.frame = self.bounds
    view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
  }
}
