//
//  BusinessViewController.swift
//  cybexMobile
//
//  Created DKM on 2018/6/11.
//  Copyright © 2018年 Cybex. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import ReSwift
import SwiftTheme
import Localize_Swift
import SwifterSwift

class BusinessViewController: BaseViewController {
  var pair: Pair? {
    didSet{
      if oldValue != pair{
        self.coordinator?.resetState()

        refreshView()
      }
    }
  }
  
  @IBOutlet weak var containerView: BusinessView!

  var type : exchangeType = .buy
  
  var coordinator: (BusinessCoordinatorProtocol & BusinessStateManagerProtocol)?
    
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupUI()

   setupEvent()
  }
  
  func setupUI(){
    containerView.button.gradientLayer.colors = type == .buy ? [UIColor.paleOliveGreen.cgColor,UIColor.apple.cgColor] : [UIColor.pastelRed.cgColor,UIColor.reddish.cgColor]
  }
  
  func setupEvent(){
    NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: ThemeUpdateNotification), object: nil, queue: nil, using: { [weak self] notification in
      guard let `self` = self else { return }
      
      if ThemeManager.currentThemeIndex == 0 {
        self.containerView.priceTextfield.textColor = .white
        self.containerView.amountTextfield.textColor = .white
      }else{
        self.containerView.priceTextfield.textColor = .darkTwo
        self.containerView.amountTextfield.textColor = .darkTwo
      }
    })
    
    NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: LCLLanguageChangeNotification), object: nil, queue: nil) { [weak self](notification) in
      guard let `self` = self else { return }
    
      self.containerView.amountTextfield.placeholder = R.string.localizable.withdraw_amount.key.localized()
      self.containerView.priceTextfield.placeholder = R.string.localizable.orderbook_price.key.localized()
      self.containerView.amountTextfield.setPlaceHolderTextColor(UIColor.steel50)
      self.containerView.priceTextfield.setPlaceHolderTextColor(UIColor.steel50)
    }
  }
  
  func refreshView() {
    guard let pair = pair, let base_info = app_data.assetInfo[pair.base], let quote_info = app_data.assetInfo[pair.quote] else { return }

    self.containerView.quoteName.text = quote_info.symbol.filterJade
    
    self.coordinator?.getFee(self.type == .buy ? base_info.id : quote_info.id)
    self.coordinator?.getBalance((self.type == .buy ? base_info.id : quote_info.id))
    
    changeButtonState()
  }
  
  @discardableResult func checkBalance() -> Bool {
    guard let pair = self.pair else {
      self.containerView.tipView.isHidden = true

      return false
    }
    
    guard let canPost = self.coordinator?.checkBalance(pair, isBuy: self.type == .buy) else {
      self.containerView.tipView.isHidden = true
      return false
    }
    
    if !canPost {
      self.containerView.tipView.isHidden = false
      return false
    }
    else {
      self.containerView.tipView.isHidden = true
      return true
    }
  }
  
  func changeButtonState() {
    if UserManager.shared.isLoginIn {
      guard let pair = pair, let quote_info = app_data.assetInfo[pair.quote] else { return }
      
      self.containerView.button.locali = self.type == .buy ? R.string.localizable.openedBuy.key.localized() : R.string.localizable.openedSell.key.localized()
      if let title = self.containerView.button.button.titleLabel?.text {
        self.containerView.button.locali = "\(title) \(quote_info.symbol.filterJade)"
      }
    }
    else {
      self.containerView.button.locali = R.string.localizable.business_login_title.key.localized()
    }
  }
  

  func showOpenedOrderInfo(){
    guard let base_info = app_data.assetInfo[(self.pair?.base)!], let quote_info = app_data.assetInfo[(self.pair?.quote)!],let _ = app_data.assetInfo[(self.coordinator?.state.property.feeID.value)!],  self.coordinator?.state.property.fee_amount.value != 0, let cur_amount = self.coordinator?.state.property.amount.value.toDouble(), cur_amount != 0, let price = self.coordinator?.state.property.price.value.toDouble(), price != 0 else { return }
    
    let openedOrderDetailView = StyleContentView(frame: .zero)
    let ensure_title = self.type == .buy ? R.string.localizable.openedorder_buy_ensure.key.localized() : R.string.localizable.openedorder_sell_ensure.key.localized()
    
    ShowToastManager.shared.setUp(title: ensure_title, contentView: openedOrderDetailView, animationType: .up_down)
    ShowToastManager.shared.showAnimationInView(self.view)
    ShowToastManager.shared.delegate = self
    
    let prirce = price.string(digits: base_info.precision) + " " + base_info.symbol.filterJade
    let amount = cur_amount.string(digits: quote_info.precision)  + " " + quote_info.symbol.filterJade
    let total = (price * cur_amount).string(digits: base_info.precision) + " " + base_info.symbol.filterJade
//    let feeInfo = (self.coordinator?.state.property.fee_amount.value.string)! + " " + fee_info.symbol.filterJade
    openedOrderDetailView.data = getOpenedOrderInfo(price: prirce, amount: amount, total: total, fee: "", isBuy: self.type == .buy)
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

    (self.containerView.amountTextfield.rx.text.orEmpty <-> self.coordinator!.state.property.amount).disposed(by: disposeBag)
    (self.containerView.priceTextfield.rx.text.orEmpty <-> self.coordinator!.state.property.price).disposed(by: disposeBag)
    
//RMB
    self.coordinator!.state.property.price.subscribe(onNext: {[weak self] (text) in
      guard let `self` = self else { return }
      
      self.checkBalance()
      guard let pair = self.pair, let base_info = app_data.assetInfo[pair.base], let text = self.containerView.priceTextfield.text, text != "", text.toDouble() != 0, text.components(separatedBy: ".").count <= 2 && text != "." else {
        self.containerView.value.text = "≈¥0.00"
        return
      }

      self.containerView.value.text = "≈¥" + String(describing: changeToETHAndCYB(base_info.id).eth.toDouble()! * text.toDouble()! * app_state.property.eth_rmb_price).formatCurrency(digitNum: 2)
      
      }, onError: nil, onCompleted: nil, onDisposed: nil).disposed(by: disposeBag)
    
  
    self.coordinator!.state.property.amount.subscribe(onNext: {[weak self] (text) in
      guard let `self` = self else { return }
      
      self.checkBalance()
      }, onError: nil, onCompleted: nil, onDisposed: nil).disposed(by: disposeBag)
    
//precision
    NotificationCenter.default.addObserver(forName: Notification.Name.UITextFieldTextDidEndEditing, object: self.containerView.priceTextfield, queue: nil) {[weak self] (notifi) in
      guard let `self` = self else { return }
      
      guard let text = self.containerView.priceTextfield.text, text != "", text.toDouble() != 0 else {
        self.containerView.priceTextfield.text = ""
        return
      }
      self.containerView.priceTextfield.text = text.tradePrice.price

    }
    
    NotificationCenter.default.addObserver(forName: Notification.Name.UITextFieldTextDidEndEditing, object: self.containerView.amountTextfield, queue: nil) {[weak self] (notifi) in
      guard let `self` = self else { return }

      guard let text = self.containerView.amountTextfield.text, text != "", text.toDouble() != 0 else {
        self.containerView.amountTextfield.text = ""
        return
      }
      self.containerView.amountTextfield.text = text.tradePrice.price
    }
    
    NotificationCenter.default.addObserver(forName: Notification.Name.UITextFieldTextDidBeginEditing, object: self.containerView.amountTextfield, queue: nil) {[weak self](notifi) in
      guard let `self` = self else {return}
      if !UserManager.shared.isLoginIn {
        self.containerView.amountTextfield.resignFirstResponder()
        app_coodinator.showLogin()
        return
      }
    }
    
    NotificationCenter.default.addObserver(forName: Notification.Name.UITextFieldTextDidBeginEditing, object: self.containerView.priceTextfield, queue: nil) {[weak self](notifi) in
      guard let `self` = self else {return}
      
      if !UserManager.shared.isLoginIn {
        self.containerView.priceTextfield.resignFirstResponder()
        app_coodinator.showLogin()
        return
      }
    }

    UserManager.shared.balances.asObservable().subscribe(onNext: {[weak self] (balances) in
      guard let `self` = self else { return }

      guard let pair = self.pair, let base_info = app_data.assetInfo[pair.base], let quote_info = app_data.assetInfo[pair.quote] else { return }

      self.coordinator?.getBalance((self.type == .buy ? base_info.id : quote_info.id))
      self.coordinator?.getFee(self.type == .buy ? base_info.id : quote_info.id)

    }, onError: nil, onCompleted: nil, onDisposed: nil).disposed(by: disposeBag)

//balance
    self.coordinator?.state.property.balance.asObservable().subscribe(onNext: {[weak self] (balance) in
      guard let `self` = self else { return }

      guard let pair = self.pair, let base_info = app_data.assetInfo[pair.base], let quote_info = app_data.assetInfo[pair.quote], balance != 0 else {
        self.containerView.balance.text = "--"
        return

      }

      let info = self.type == .buy ? base_info : quote_info
      let symbol = info.symbol.filterJade
      let realAmount = balance.doubleValue.string(digits: info.precision)

      self.containerView.balance.text = "\(realAmount) \(symbol)"

    }, onError: nil, onCompleted: nil, onDisposed: nil).disposed(by: disposeBag)

//fee
    Observable.combineLatest(coordinator!.state.property.feeID.asObservable(), coordinator!.state.property.fee_amount.asObservable()).subscribe(onNext: {[weak self] (fee_id, fee_amount) in
      guard let `self` = self else { return }

      guard let info = app_data.assetInfo[fee_id] else {
        self.containerView.fee.text = "--"
        return
      }

      self.containerView.fee.text = fee_amount.doubleValue.string(digits: info.precision) + " \(info.symbol.filterJade)"

    }, onError: nil, onCompleted: nil, onDisposed: nil).disposed(by: disposeBag)


//total
    Observable.combineLatest(coordinator!.state.property.feeID.asObservable(), self.coordinator!.state.property.amount, self.coordinator!.state.property.price, coordinator!.state.property.fee_amount.asObservable()).subscribe(onNext: {[weak self] (feeID, amount, price, fee) in
      guard let `self` = self else { return }
      guard let pair = self.pair, let base_info = app_data.assetInfo[pair.base] else {
        self.containerView.endMoney.text = "--"
        return
      }

      guard let limit = price.toDouble(), let amount = amount.toDouble(), limit != 0, amount != 0, fee != 0 else {
        self.containerView.endMoney.text = "--"
        return
      }

      let total = Decimal(floatLiteral: limit) * Decimal(floatLiteral: amount)

      self.containerView.endMoney.text = "\(total.tradePrice().price) \(base_info.symbol.filterJade)"

    }, onError: nil, onCompleted: nil, onDisposed: nil).disposed(by: disposeBag)


    UserManager.shared.name.skip(1).asObservable().subscribe(onNext: {[weak self] (name) in
      guard let `self` = self else { return }
      
      self.changeButtonState()

      guard let _ = name else {
        self.coordinator?.resetState()
        return
      }

    }, onError: nil, onCompleted: nil, onDisposed: nil).disposed(by: disposeBag)
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self.containerView.priceTextfield)
    NotificationCenter.default.removeObserver(self.containerView.amountTextfield)
    NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: ThemeUpdateNotification), object: nil)
  }
}

extension BusinessViewController : TradePair {
  var pariInfo: Pair {
    get {
      return self.pair!
    }
    set {
      self.pair = newValue
    }
  }
  
  func refresh() {
//    refreshView()
  }
}

extension BusinessViewController {
  @objc func amountPercent(_ data:[String:Any]) {
    if let percent = data["percent"] as? String {
      guard let pair = self.pair, let base_info = app_data.assetInfo[pair.base], let quote_info = app_data.assetInfo[pair.quote]  else { return }
      self.coordinator?.changePercent(percent.toDouble()! / 100.0, isBuy: self.type == .buy, assetID: self.type == .buy ? base_info.id : quote_info.id)
    }
  }
  
  @objc func buttonDidClicked(_ data: [String: Any]) {  
    if self.coordinator!.parentIsLoading(self.parent) {
      return
    }
    
    if !UserManager.shared.isLoginIn {
      app_coodinator.showLogin()
      return
    }
    
    
    guard checkBalance() else { return }
    
//    if UserManager.shared.isLocked {
//      showPasswordBox(R.string.localizable.withdraw_unlock_wallet.key.localized())
//    }
//    else {
      self.showOpenedOrderInfo()
//    }
  }
  
  @objc func adjustPrice(_ data:[String : Bool]) {
    self.coordinator?.adjustPrice(data["plus"]!)
  }
  
  func postOrder() {
    guard let pair = self.pair else { return }

    self.coordinator?.postLimitOrder(pair, isBuy: self.type == .buy, callback: {[weak self] (success) in
      guard let `self` = self else { return }
      self.coordinator?.parentEndLoading(self.parent)

      if success {
        self.coordinator?.resetState()
      }
      
      self.showToastBox(success, message:success ? R.string.localizable.order_create_success() : R.string.localizable.order_create_fail())
     
    })
  }

  override func returnEnsureAction() {
//    self.coordinator?.parentStartLoading(self.parent)
    ShowToastManager.shared.hide()
    if UserManager.shared.isLocked {
      SwifterSwift.delay(milliseconds: 100) {
        self.showPasswordBox(R.string.localizable.withdraw_unlock_wallet.key.localized())
      }
    }else{
      self.coordinator?.parentStartLoading(self.parent)
      postOrder()
    }
  }

  override func passwordDetecting() {
    self.coordinator?.parentStartLoading(self.parent)
  }
  
  override func passwordPassed(_ passed:Bool) {

//    guard let trade = self.parent?.parent as? TradeViewController, (trade.selectedIndex == 0 && self.type == .buy) ||  (trade.selectedIndex == 1 && self.type == .sell), self.isVisible else {
//      return
//    }
    
    if passed {
      
//      self.coordinator?.parentStartLoading(self.parent)
      postOrder()
//      self.showOpenedOrderInfo()
    }
    else {
      self.coordinator?.parentEndLoading(self.parent)
      self.showToastBox(false, message: R.string.localizable.recharge_invalid_password.key.localized())
    }
    
  }
}
