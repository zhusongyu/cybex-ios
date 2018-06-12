//
//  WithdrawDetailActions.swift
//  cybexMobile
//
//  Created DKM on 2018/6/7.
//  Copyright © 2018年 Cybex. All rights reserved.
//

import Foundation
import ReSwift

//MARK: - State
struct WithdrawDetailState: StateType {
    var isLoading = false
    var page: Int = 1
    var errorMessage:String?
    var property: WithdrawDetailPropertyState
}

struct WithdrawDetailPropertyState {
}

//MARK: - Action Creator
class WithdrawDetailPropertyActionCreate: LoadingActionCreator {
    public typealias ActionCreator = (_ state: WithdrawDetailState, _ store: Store<WithdrawDetailState>) -> Action?
    
    public typealias AsyncActionCreator = (
        _ state: WithdrawDetailState,
        _ store: Store <WithdrawDetailState>,
        _ actionCreatorCallback: @escaping ((ActionCreator) -> Void)
        ) -> Void
}
