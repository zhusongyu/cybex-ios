//
//  RechargeDetailViewController.swift
//  cybexMobile
//
//  Created DKM on 2018/6/7.
//  Copyright © 2018年 Cybex. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import ReSwift
import Localize_Swift
import AwaitKit
import Guitar
import SwifterSwift

class RechargeDetailViewController: BaseViewController {
  
  @IBOutlet weak var avaliableView: RechargeItemView!
  @IBOutlet weak var addressView: RechargeItemView!
  @IBOutlet weak var amountView: RechargeItemView!
  
  @IBOutlet weak var gateAwayFee: UILabel!
  @IBOutlet weak var insideFee: UILabel!
  
  @IBOutlet weak var finalAmount: UILabel!
  
  @IBOutlet weak var errorView: UIView!
  @IBOutlet weak var errorL: UILabel!
  
  @IBOutlet weak var feeView: UIView!
  
  @IBOutlet weak var introduceView: UIView!
  @IBOutlet weak var withdraw: Button!
  @IBOutlet weak var stackView: UIStackView!
  
  @IBOutlet weak var introduce: IntroduceView!
  
  var feeAssetId : String  = AssetConfiguration.CYB
  
  var available : Double = 0.0
  
  var isWithdraw : Bool = false
  var isTrueAddress : Bool = false{
    didSet{
      if isTrueAddress != oldValue{
        self.changeWithdrawState()
      }
    }
  }
  var isAvalibaleAmount : Bool = false{
    didSet{
      if isAvalibaleAmount != oldValue{
        self.changeWithdrawState()
      }
    }
  }
  var trade : Trade?{
    didSet{
      if let balances = UserManager.shared.balances.value{
        for balance in balances{
          if balance.asset_type == trade?.id{
            self.balance = balance
          }
        }
      }
    }
  }
  var balance : Balance?{
    didSet{
      if let balance = balance{
        self.available = getRealAmountDouble(balance.asset_type, amount: balance.balance)
      }
    }
  }
  var coordinator: (RechargeDetailCoordinatorProtocol & RechargeDetailStateManagerProtocol)?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.title = (app_data.assetInfo[(self.trade?.id)!]?.symbol.filterJade)! + R.string.localizable.recharge_title.key.localized()
    setupUI()
    checkState()
    setupEvent()
    self.coordinator?.fetchWithDrawInfoData((app_data.assetInfo[(self.trade?.id)!]?.symbol.filterJade)!)
  }
  
  func setupUI(){
    if let name = app_data.assetInfo[(self.trade?.id)!]?.symbol.filterJade{
      self.coordinator?.fetchWithDrawMessage(callback: { (message) in
        
        self.introduce.locail = message.replacingOccurrences(of: "$asset", with: name)
      })
    }
    
    amountView.content.keyboardType = .decimalPad
    addressView.btn.isHidden        = true
    amountView.btn.setTitle(R.string.localizable.openedAll.key.localized(), for: .normal)
    if let balance = self.balance,let balance_info = app_data.assetInfo[balance.asset_type]{
      avaliableView.content.text = self.available.string(digits: balance_info.precision) + " " + balance_info.symbol.filterJade
      self.available = getRealAmount(balance.asset_type, amount: balance.balance).doubleValue
    }else{
      avaliableView.content.text = "--" + (app_data.assetInfo[(self.trade?.id)!]?.symbol.filterJade)!
    }
    self.withdraw.isEnable = false
    addressView.btn.addTarget(self, action: #selector(cleanAddress), for: .touchUpInside)
    amountView.btn.addTarget(self, action: #selector(addAllAmount), for: .touchUpInside)
    NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHidden), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
  }
  
  func checkState(){
    if !self.isWithdraw{
      self.checkIsWithdraw()
      return
    }
    if UserManager.shared.isLocked{
      showPasswordBox()
      return
    }
    if !UserManager.shared.isWithDraw{
      self.checkIsAuthory()
      return
    }
  }
  
  func checkIsWithdraw(){
    var message = ""
    if let enMsg = self.trade?.enMsg,let cnMsg = self.trade?.cnMsg{
      message = Localize.currentLanguage() == "en" ? enMsg : cnMsg
    }
    showToastBox(false, message: message)
  }
  
  func checkIsAuthory(){
    showToastBox(false, message: R.string.localizable.withdraw_miss_authority.key.localized())
  }
  
  
  func setupEvent(){
    self.withdraw.rx.tapGesture().when(.recognized).subscribe(onNext: { [weak self](tap) in
      guard let `self` = self else{ return }
      self.withDrawAction()
      }, onError: nil, onCompleted: nil, onDisposed: nil).disposed(by: disposeBag)
    
    NotificationCenter.default.addObserver(forName: NSNotification.Name.UITextFieldTextDidChange, object: amountView.content, queue: nil) { [weak self](notification) in
      guard let `self` = self else {return}
      
      if let text = self.amountView.content.text,let amount = text.toDouble(),amount > 0,let balance = self.balance,let balance_info = app_data.assetInfo[balance.asset_type]{
        
        self.amountView.content.text = checkMaxLength(text, maxLength: balance_info.precision)
        self.checkAmountIsAvailable(amount)
      }else{
        self.isAvalibaleAmount = false
      }
    }
    
    NotificationCenter.default.addObserver(forName: NSNotification.Name.UITextFieldTextDidChange, object: addressView.content, queue: nil) { [weak self] (notification) in
      guard let `self` = self else{return}
      
      if let address = self.addressView.content.text , address.count > 0 {
        self.addressView.btn.isHidden = false
        let letterBegin = Guitar(pattern: "^([a-zA-Z0-9])")
        if !letterBegin.test(string: address){
          self.isTrueAddress = false
          self.errorView.isHidden = false
          self.errorL.locali =  R.string.localizable.withdraw_address_fault.key.localized()
          return
        }
        if let balance = self.balance{
          if let assetName = app_data.assetInfo[balance.asset_type]?.symbol.filterJade{
            self.coordinator?.verifyAddress(assetName, address: address, callback: { (success) in
              if success{
                self.isTrueAddress      = true
                self.errorView.isHidden = true
                if let amount = self.amountView.content.text,amount.count != 0,let amountDouble = amount.toDouble() {
                  self.checkAmountIsAvailable(amountDouble)
                }
              }else{
                self.isTrueAddress = false
                self.errorView.isHidden = false
                self.errorL.locali =  R.string.localizable.withdraw_address_fault.key.localized()
              }
            })
          }
        }
      }else{
        self.addressView.btn.isHidden = true
        self.isTrueAddress = false
      }
    }
  }
  
  func checkAmountIsAvailable(_ amount:Double){
    if let balance = self.balance, let data = self.coordinator?.state.property.data.value{
      let avaliable = getRealAmount(balance.asset_type, amount: balance.balance).doubleValue
      if amount < data.minValue{
        self.isAvalibaleAmount  = false
        self.errorView.isHidden = false
        self.withdraw.isEnable = false
        self.errorL.locali      =  R.string.localizable.withdraw_min_value.key.localized()
      }else if amount > avaliable || avaliable < data.fee{
        self.isAvalibaleAmount  = false
        self.errorView.isHidden = false
        self.withdraw.isEnable = false
        self.errorL.locali =  R.string.localizable.withdraw_nomore.key.localized()
      }else{
        self.isAvalibaleAmount  = true
        self.errorView.isHidden = true
        self.setFinalAmount()
        if let addressText = self.addressView.content.text,addressText.count != 0,!self.isTrueAddress{
          self.errorView.isHidden = false
          self.errorL.locali =  R.string.localizable.withdraw_address_fault.key.localized()
        }
      }
    }
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
    
    self.coordinator?.state.property.data.asObservable().skip(1).subscribe(onNext: {[weak self] (withdrawInfo) in
      guard let `self` = self else{return}
      self.endLoading()
      if let data = withdrawInfo{
        if let trade = self.trade,let trade_info = app_data.assetInfo[trade.id]{
          self.insideFee.text = data.fee.string(digits: trade_info.precision) + " " + (app_data.assetInfo[trade.id]?.symbol.filterJade)!
        }
        self.setFinalAmount()
        self.changeWithdrawState()
        self.amountView.textplaceholder = R.string.localizable.recharge_min.key.localized() + String(describing: data.minValue)
      }
      }, onError: nil, onCompleted: nil, onDisposed: nil).disposed(by: disposeBag)
    
    
    self.coordinator?.state.property.gatewayFee.asObservable().subscribe(onNext: { [weak self](result) in
      guard let `self` = self else{ return }
      self.endLoading()
      if let data = result, data.success,let feeInfo = app_data.assetInfo[data.0.asset_id]{
        let fee               = data.0
        self.gateAwayFee.text = (fee.amount.toDouble()?.string(digits: feeInfo.precision))! + " " + feeInfo.symbol.filterJade
        self.isAvalibaleAmount = true
        if AssetConfiguration.CYB != fee.asset_id{
          self.feeAssetId       = fee.asset_id
        }
        self.setFinalAmount()
        self.changeWithdrawState()
      }
      }, onError: nil, onCompleted: nil, onDisposed: nil).disposed(by: disposeBag)
  }
  
  
  override func configureObserveState() {
    commonObserveState()
    
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  func setFinalAmount(){
    if let text = self.amountView.content.text,let amount = Decimal(string: text){
      var finalAmount : Decimal = amount
      if let gateway_fee = self.coordinator?.state.property.gatewayFee.value?.0{
        if self.feeAssetId != AssetConfiguration.CYB{
          if let gatewayFee = Decimal(string:gateway_fee.amount){
            if Decimal(self.available) < gatewayFee + amount{
              finalAmount = finalAmount - gatewayFee
            }
          }
        }
      }
      
      var insideFee :Decimal = 0
      if let inside_fee = self.coordinator?.state.property.data.value{
        insideFee = Decimal(inside_fee.fee)
        finalAmount = finalAmount - insideFee
      }
      if finalAmount.doubleValue > 0,let balance = self.balance, let balance_info = app_data.assetInfo[balance.asset_type]{
        self.finalAmount.text = finalAmount.doubleValue.string(digits: balance_info.precision) + " " + balance_info.symbol.filterJade
      }
    }
  }
}

extension RechargeDetailViewController{
  func changeWithdrawState(){
    if  self.trade?.enable == false {
      return
    }
    if UserManager.shared.isLocked{
      if self.isLoading(){
        return
      }
      if ShowManager.shared.showView != nil{
        return
      }
      showPasswordBox(R.string.localizable.withdraw_unlock_wallet.key.localized())
    }else{
      if UserManager.shared.isWithDraw, self.isWithdraw, self.isTrueAddress, self.isAvalibaleAmount{
        if let _ = self.coordinator?.state.property.gatewayFee.value,let _ = self.coordinator?.state.property.data.value{
          self.withdraw.isEnable = true
        }else{
          if let trade = self.trade,let amount = self.amountView.content.text,let address = self.addressView.content.text{
            self.startLoading()
            self.coordinator?.getGatewayFee(trade.id, amount: amount, address: address)
          }
        }
      }else{
        self.withdraw.isEnable = false
      }
    }
  }
  
  @objc func cleanAddress() {
    self.addressView.content.text = ""
    self.isTrueAddress = false
  }
  
  @objc func addAllAmount(){
    if let balance = self.balance{
      self.amountView.content.text = getRealAmount(balance.asset_type, amount: balance.balance).stringValue
      self.checkAmountIsAvailable(getRealAmount(balance.asset_type, amount: balance.balance).doubleValue)
      self.setFinalAmount()
    }
  }
  
  @objc func keyboardWillShow(){
    if self.addressView.content.isFirstResponder || self.amountView.content.isFirstResponder{
      self.feeView.isHidden       = true
      self.introduceView.isHidden = true
      self.stackView.layoutIfNeeded()
      self.view.layoutIfNeeded()
    }
  }
  
  @objc func keyboardWillHidden(){
    self.feeView.isHidden       = false
    self.introduceView.isHidden = false
    self.stackView.layoutIfNeeded()
    self.view.layoutIfNeeded()
    
  }
  
  func withDrawAction(){
    if self.withdraw.isEnable,let addressText = self.addressView.content.text,let amountText = self.amountView.content.text,let insideText = self.insideFee.text,let gatewayFeeText = self.gateAwayFee.text,let finalAmountText = self.finalAmount.text{
      
      let data = getWithdrawDetailInfo(addressInfo: addressText, amountInfo: amountText + " " + (app_data.assetInfo[(self.trade?.id)!]?.symbol.filterJade)!, withdrawFeeInfo: insideText, gatewayFeeInfo: gatewayFeeText, receiveAmountInfo: finalAmountText)
      if self.isVisible{
        showConfirm(R.string.localizable.withdraw_ensure_title.key.localized(), attributes: data)
      }
    }
  }
  
  override func passwordDetecting() {
    startLoading()
  }
  
  override func passwordPassed(_ passed: Bool) {
    endLoading()
    if passed {
      ShowManager.shared.hide()
      self.changeWithdrawState()
      if !UserManager.shared.isWithDraw{
        self.checkIsAuthory()
      }
    }else{
      if self.isVisible{
        self.showToastBox(false, message: R.string.localizable.recharge_invalid_password.key.localized())
      }
    }
  }
}

extension RechargeDetailViewController {
  // 提现操作
  override func returnEnsureAction(){
    if let gatewayText = self.gateAwayFee.text,let first_text = gatewayText.components(separatedBy: " ").first,let gateway = Decimal(string:first_text),let amountString = self.amountView.content.text,let amount = Decimal(string:amountString),let address = self.addressView.content.text{
      startLoading()
      let allAmount = Decimal(self.available)
      var requestAmount : String = ""
      
      if allAmount < gateway + amount{
        if self.feeAssetId != AssetConfiguration.CYB{
          requestAmount = (amount - gateway).stringValue
        }else{
          requestAmount = amount.stringValue
        }
      }else{
        requestAmount = amount.stringValue
      }
      self.coordinator?.getObjects(assetId: (self.trade?.id)!,amount: requestAmount,address: address,fee_id: self.feeAssetId,fee_amount: first_text,callback: {[weak self] (data) in
        guard let `self` = self else { return }
        self.endLoading()
        main {
          ShowManager.shared.hide()
          if self.isVisible{
            if String(describing: data) == "<null>"{
              self.showToastBox(true, message: R.string.localizable.recharge_withdraw_success.key.localized())
              SwifterSwift.delay(milliseconds: 100) {
                self.coordinator?.pop()
              }
            }else{
              self.showToastBox(false, message: R.string.localizable.recharge_withdraw_failed.key.localized())
            }
          }
        }
      })
    }
  }
}