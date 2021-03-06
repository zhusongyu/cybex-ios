//
//  ExchangeCoordinator.swift
//  cybexMobile
//
//  Created koofrank on 2018/6/23.
//  Copyright © 2018年 Cybex. All rights reserved.
//

import UIKit
import ReSwift
import TinyConstraints

protocol ExchangeCoordinatorProtocol {
  func setupChildVC(_ exchange:ExchangeViewController)
  
  func switchPriceToBusinessVC(_ price:String, isBuy:Bool)
}

protocol ExchangeStateManagerProtocol {
    var state: ExchangeState { get }
    func subscribe<SelectedState, S: StoreSubscriber>(
        _ subscriber: S, transform: ((Subscription<ExchangeState>) -> Subscription<SelectedState>)?
    ) where S.StoreSubscriberStateType == SelectedState
}

class ExchangeCoordinator: TradeRootCoordinator {
    
    lazy var creator = ExchangePropertyActionCreate()
    
    var store = Store<ExchangeState>(
        reducer: ExchangeReducer,
        state: nil,
        middleware:[TrackingMiddleware]
    )
}

extension ExchangeCoordinator: ExchangeCoordinatorProtocol {
  func setupChildVC(_ exchange:ExchangeViewController) {
    if let business = R.storyboard.business.businessViewController() {
      if let container = exchange.containerView, let leftView = container.leftView {
        business.coordinator = BusinessCoordinator(rootVC: self.rootVC)
        business.type = exchange.type
        exchange.addChildViewController(business)
        
        leftView.addSubview(business.view)
        business.view.edges(to: leftView)
      
        business.didMove(toParentViewController: exchange)
      }
    }
    
    if let orderbook = R.storyboard.main.orderBookViewController() {
      if let container = exchange.containerView, let rightView = container.rightView {
        orderbook.coordinator = OrderBookCoordinator(rootVC: self.rootVC)
        orderbook.VC_TYPE = orderbook_type.tradeView.rawValue
        exchange.addChildViewController(orderbook)
        
        rightView.addSubview(orderbook.view)
        orderbook.view.edges(to: rightView)
        
        orderbook.didMove(toParentViewController: exchange)
      }
    }
    
    if let tradeHistory = R.storyboard.business.tradeHistoryViewController() {
      if let container = exchange.containerView, let bottomView = container.bottomView {
        tradeHistory.coordinator = TradeHistoryCoordinator(rootVC: self.rootVC)
        exchange.addChildViewController(tradeHistory)
        
        tradeHistory.pageType = .trade
        bottomView.addSubview(tradeHistory.view)
        tradeHistory.view.edges(to: bottomView)
        
        tradeHistory.didMove(toParentViewController: exchange)
      }
    }    
  }
  
  func switchPriceToBusinessVC(_ price:String, isBuy:Bool) {
    guard let tradeVC = self.rootVC.topViewController as? TradeViewController,
      let exchange = tradeVC.childViewControllers.filter({ (vc) -> Bool in
        if let vc = vc as? ExchangeViewController {
          let type = isBuy ? exchangeType.buy : exchangeType.sell
          if type == vc.type {
            return true
          }
          return false
        }
        
        return false
      }).first as? ExchangeViewController ,
      let business = exchange.childViewControllers.filter({ $0 is BusinessViewController}).first as? BusinessViewController else {
        return
    }
    business.coordinator?.switchPrice(price)
  }
}

extension ExchangeCoordinator: ExchangeStateManagerProtocol {
    var state: ExchangeState {
        return store.state
    }
    
    func subscribe<SelectedState, S: StoreSubscriber>(
        _ subscriber: S, transform: ((Subscription<ExchangeState>) -> Subscription<SelectedState>)?
        ) where S.StoreSubscriberStateType == SelectedState {
        store.subscribe(subscriber, transform: transform)
    }
    
}
