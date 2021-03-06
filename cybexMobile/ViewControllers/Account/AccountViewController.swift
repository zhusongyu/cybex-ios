//
//  AccountViewController.swift
//  cybexMobile
//
//  Created koofrank on 2018/3/22.
//  Copyright © 2018年 Cybex. All rights reserved.
//

import UIKit
import ReSwift
import SwiftTheme
import AwaitKit
import RxSwift
import CryptoSwift
import SwiftRichString
import SwifterSwift

class AccountViewController: BaseViewController {
  
  var coordinator: (AccountCoordinatorProtocol & AccountStateManagerProtocol)?
  
  @IBOutlet weak var accountContentView: AccountContentView!
  
  var dataArray: [AccountViewModel] = []
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupUI()
    setupEvent()
    if  UserManager.shared.isLoginIn {
    }
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    SwifterSwift.delay(milliseconds: 100) {
      self.setupUI()
    }
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
//    if let nav = self.navigationController as? BaseNavigationController {
//      nav.setupNavUI()
//    }
  }
  
  func setupIconImg() {
    if UserManager.shared.isLoginIn == false {
      accountContentView.headerView.icon = R.image.accountAvatar()
    } else {
      if let hash = UserManager.shared.avatarString {
        let generator = IconGenerator(size: 168, hash: Data(hex: hash))
        if let render = generator.render() {
          let image = UIImage(cgImage: render)
          accountContentView.headerView.icon = image
        }
      }
    }
  }
  
  func setupTitle() {
    if let name = UserManager.shared.account.value?.name {
      accountContentView.headerView.title = R.string.localizable.hello.key.localized() + name
    } else {
      accountContentView.headerView.title = R.string.localizable.accountLogin.key.localized()
    }
  }
  
  // UI的初始化设置
  func setupUI(){
    
    self.navigationItem.title = ""
    setupTitle()
    setupIconImg()
    self.configRightNavButton(R.image.icSettings24Px())
    
    let imgArray = [R.image.icBalance(),R.image.w(),R.image.icOrder28Px(),R.image.icLockAsset()]
    let nameArray = [R.string.localizable.my_property.key.localized(),R.string.localizable.deposit_withdraw.key.localized(),R.string.localizable.order_value.key.localized(),R.string.localizable.lockupAssetsTitle.key.localized()]
    dataArray.removeAll()
    for i in 0..<4 {
      var model = AccountViewModel()
      model.leftImage = imgArray[i]
      model.name = nameArray[i]
      
      dataArray.append(model)
    }
    accountContentView.data = dataArray
  }
  
  func setupEvent() {
    
  }
  
  // 跳转到设置界面
  override func rightAction(_ sender: UIButton) {
    self.coordinator?.openSetting()
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
    
    UserManager.shared.account.asObservable()
      .skip(1)
      .throttle(10, latest: true, scheduler: MainScheduler.instance)
      .subscribe(onNext: { [weak self](account) in
        guard let `self` = self else{ return }
        if self.isVisible {
          self.setupTitle()
          self.setupIconImg()
        }
        }, onError: nil, onCompleted: nil, onDisposed: nil).disposed(by: disposeBag)
  }
}

extension AccountViewController{

  @objc func login(_ data:[String:Any]) {
    if !UserManager.shared.isLoginIn {
      app_coodinator.showLogin()
    }
  }
  
  @objc func clickCellView(_ sender:[String:Any]) {
    let index = sender["index"] as! Int
    switch index {
    case 0:
      if !UserManager.shared.isLoginIn {
        app_coodinator.showLogin()
      } else {
        self.coordinator?.openYourProtfolio()
      }
    case 1:
      if !UserManager.shared.isLoginIn {
        app_coodinator.showLogin()
      } else {
        self.coordinator?.openRecharge()
      }
    case 2:
      if !UserManager.shared.isLoginIn {
        app_coodinator.showLogin()
      } else {
        self.coordinator?.openOpenedOrders()
      }
    default:
      if !UserManager.shared.isLoginIn {
        app_coodinator.showLogin()
      } else {
        openLockupAssets([:])
      }
    }
  }

  @objc func openLockupAssets(_ data:[String: Any]){
    guard !isLoading() else { return }
    
    if !UserManager.shared.isLocked {
      self.coordinator?.openLockupAssets()
    }
    else {
      self.showPasswordBox()
    }
  }
  
  override func passwordPassed(_ passed: Bool) {
    self.endLoading()
    
    if self.isVisible {
      if passed {
        self.coordinator?.openLockupAssets()
      }
      else {
        self.showToastBox(false, message: R.string.localizable.recharge_invalid_password.key.localized())
      }
    }
    
  }
  
  override func passwordDetecting() {
    self.startLoading()
  }
}
