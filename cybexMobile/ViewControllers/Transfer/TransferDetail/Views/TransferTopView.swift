//
//  TransferTopView.swift
//  cybexMobile
//
//  Created by DKM on 2018/7/22.
//  Copyright © 2018年 Cybex. All rights reserved.
//

import UIKit

class TransferTopView: UIView {
  
  @IBOutlet weak var icon: UIImageView!
  @IBOutlet weak var state: UILabel!
  @IBOutlet weak var amount: UILabel!
  
  var data : Any? {
    didSet{
      if let data = data as? TransferRecordViewModel {
        self.icon.image = data.isSend ? R.image.ic_sent_40_px() : R.image.ic_income_40_px()
        self.state.text = data.isSend ? R.string.localizable.transfer_detail_send.key.localized() : R.string.localizable.transfer_detail_income.key.localized()
        if let amountInfo = data.amount, let assetInfo = app_data.assetInfo[amountInfo.asset_id] {
          self.amount.text = getRealAmount(amountInfo.asset_id, amount: amountInfo.amount).stringValue.formatCurrency(digitNum: assetInfo.precision) + assetInfo.symbol.filterJade
          self.amount.text = data.isSend ? "-" + self.amount.text! : "+" + self.amount.text!
        }
        if UIScreen.main.bounds.width == 320 {
          self.amount.font = UIFont.systemFont(ofSize: 20.0, weight: .medium)
        }
        
        updateHeight()
      }
    }
  }
  
  func setup() {
    
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
    return (lastView?.frame.origin.y)! + (lastView?.frame.size.height)!
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
