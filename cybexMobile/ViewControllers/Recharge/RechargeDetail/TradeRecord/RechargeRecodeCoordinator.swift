//
//  RechargeRecodeCoordinator.swift
//  cybexMobile
//
//  Created DKM on 2018/7/22.
//  Copyright © 2018年 Cybex. All rights reserved.
//

import UIKit
import ReSwift

protocol RechargeRecodeCoordinatorProtocol {
}

protocol RechargeRecodeStateManagerProtocol {
  var state: RechargeRecodeState { get }
  func subscribe<SelectedState, S: StoreSubscriber>(
    _ subscriber: S, transform: ((Subscription<RechargeRecodeState>) -> Subscription<SelectedState>)?
  ) where S.StoreSubscriberStateType == SelectedState
  
  func fetchRechargeRecodeList(_ accountName : String ,asset : String ,fundType : fundType ,size : Int , offset : Int ,expiration : Int ,callback:@escaping (Bool)->())
  
}

class RechargeRecodeCoordinator: AccountRootCoordinator {
  
  lazy var creator = RechargeRecodePropertyActionCreate()
  
  var store = Store<RechargeRecodeState>(
    reducer: RechargeRecodeReducer,
    state: nil,
    middleware:[TrackingMiddleware]
  )
}

extension RechargeRecodeCoordinator: RechargeRecodeCoordinatorProtocol {
  
}

extension RechargeRecodeCoordinator: RechargeRecodeStateManagerProtocol {
  var state: RechargeRecodeState {
    return store.state
  }
  
  func subscribe<SelectedState, S: StoreSubscriber>(
    _ subscriber: S, transform: ((Subscription<RechargeRecodeState>) -> Subscription<SelectedState>)?
    ) where S.StoreSubscriberStateType == SelectedState {
    store.subscribe(subscriber, transform: transform)
  }
  
  func fetchRechargeRecodeList(_ accountName : String ,asset : String ,fundType : fundType ,size : Int , offset : Int ,expiration : Int, callback:@escaping (Bool)->()) {
    getWithdrawAndDepositRecords(accountName, asset: asset, fundType: fundType, size: size, offset: offset, expiration: expiration) { [weak self](result) in
      guard let `self` = self else { return }
      self.store.dispatch(FetchDepositRecordsAction(data : result))
      if result != nil {
        callback(true)
      }else {
        callback(false)
      }
    }
  }
}
