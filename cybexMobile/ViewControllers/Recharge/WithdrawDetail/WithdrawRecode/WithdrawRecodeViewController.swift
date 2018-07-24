//
//  WithdrawRecodeViewController.swift
//  cybexMobile
//
//  Created DKM on 2018/7/22.
//  Copyright © 2018年 Cybex. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import ReSwift

class WithdrawRecodeViewController: BaseViewController {

    @IBOutlet weak var tableView: UITableView!
    
	var coordinator: (WithdrawRecodeCoordinatorProtocol & WithdrawRecodeStateManagerProtocol)?

	override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    func setupUI() {
      self.title = R.string.localizable.withdraw_list()

      let nibString = String(describing: RecodeCell.self)
      self.tableView.register(UINib(nibName: nibString, bundle: nil), forCellReuseIdentifier: nibString)
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

extension WithdrawRecodeViewController : UITableViewDataSource ,UITableViewDelegate {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 5
  }
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cellString = String(describing: RecodeCell.self)
    let cell = tableView.dequeueReusableCell(withIdentifier: cellString, for: indexPath)
    return cell
  }
}