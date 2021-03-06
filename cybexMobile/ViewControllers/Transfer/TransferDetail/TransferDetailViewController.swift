//
//  TransferDetailViewController.swift
//  cybexMobile
//
//  Created DKM on 2018/7/22.
//  Copyright © 2018年 Cybex. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import ReSwift
import SwiftTheme

class TransferDetailViewController: BaseViewController {
  
    @IBOutlet weak var headerView: TransferTopView!
    @IBOutlet weak var contentView: TransferContentView!
    
    var coordinator: (TransferDetailCoordinatorProtocol & TransferDetailStateManagerProtocol)?
  
  var data : TransferRecordViewModel!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()

  }
  
  func setupUI() {
    self.title = R.string.localizable.transfer_detail()
    self.headerView.data = data
    self.contentView.data = data
  }
  
  func commonObserveState() {
    coordinator?.subscribe(errorSubscriber) { sub in
      return sub.select { state in state.errorMessage }.skipRepeats({ (old, new) -> Bool in
        return false
      })
    }
    
    coordinator?.subscribe(loadingSubscriber) { sub in
      return sub.select { state in state.isLoading }.skipRepeats({ (old, new) -> Bool in
        return false
      })
    }
  }
  
  override func configureObserveState() {
    commonObserveState()
    
  }
}

extension TransferDetailViewController {
  @objc func transferMemo(_ sender : [String : Any]) {
    if UserManager.shared.isLocked {
      self.showPasswordBox()
    }else {
      
      self.contentView.content_text = BitShareCoordinator.getMemo(self.data.memo)
      self.contentView.memoView.content.textColor = ThemeManager.currentThemeIndex == 0 ? UIColor.white : UIColor.darkTwo
      self.contentView.layoutIfNeeded()
    }
  }
  
  override func passwordDetecting() {
    self.startLoading()
  }
  
  override func passwordPassed(_ passed: Bool) {
    self.endLoading()
    if passed {
      self.contentView.content_text = BitShareCoordinator.getMemo(self.data.memo)
      self.contentView.memoView.content.textColor = ThemeManager.currentThemeIndex == 0 ? UIColor.white : UIColor.darkTwo
      self.contentView.layoutIfNeeded()
    }
    else{
      if self.isVisible{
        self.showToastBox(false, message: R.string.localizable.recharge_invalid_password.key.localized())
      }
    }
  }
}
