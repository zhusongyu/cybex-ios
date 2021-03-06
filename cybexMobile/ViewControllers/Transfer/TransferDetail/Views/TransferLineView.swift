//
//  TransferLineView.swift
//  cybexMobile
//
//  Created by DKM on 2018/7/22.
//  Copyright © 2018年 Cybex. All rights reserved.
//

import UIKit

@IBDesignable
class TransferLineView: UIView {
  
  @IBOutlet weak var name: UILabel!
  
  @IBOutlet weak var content: UILabel!
  
  
  
  @IBInspectable
  var name_locali : String? {
    didSet{
      if let text = name_locali {
        name.locali = text
      }
    }
  }
  
  @IBInspectable
  var content_locali : String? {
    didSet{
      if let text = content_locali {
        content.text = text
        updateHeight()
      }
    }
  }
  
  func setup() {
    self.content.isUserInteractionEnabled = false
    let tap = UITapGestureRecognizer(target: self, action: #selector(clickToMemo))
    self.content.addGestureRecognizer(tap)
  }
  
  fileprivate func updateHeight() {
    layoutIfNeeded()
    self.frame.size.height = dynamicHeight()
    invalidateIntrinsicContentSize()
  }
  
  override var intrinsicContentSize: CGSize {
    return CGSize.init(width:UIViewNoIntrinsicMetric,height:dynamicHeight())
  }
  
  fileprivate func dynamicHeight() -> CGFloat {
    let lastView = self.subviews.last?.subviews.last
    return (lastView?.frame.origin.y)! + (lastView?.frame.size.height)! + 13
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    layoutIfNeeded()
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    loadFromXIB()
    setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    loadFromXIB()
    setup()
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    setup()
  }
  
  private func loadFromXIB() {
    let bundle = Bundle(for: type(of: self))
    let nibName = String(describing: type(of: self))
    let nib = UINib.init(nibName: nibName, bundle: bundle)
    let view = nib.instantiate(withOwner: self, options: nil).first as! UIView
    addSubview(view)
    view.frame = self.bounds
    view.autoresizingMask = [.flexibleHeight,.flexibleWidth]
  }
}

extension TransferLineView {
  @objc func clickToMemo() {
    
  }
}
