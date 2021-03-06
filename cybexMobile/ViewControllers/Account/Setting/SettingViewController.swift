//
//  SettingViewController.swift
//  cybexMobile
//
//  Created koofrank on 2018/3/22.
//  Copyright © 2018年 Cybex. All rights reserved.
//

import UIKit
import ReSwift
import Localize_Swift
import SwiftTheme
import SwiftyUserDefaults
import SwifterSwift
import XLActionController


class SettingViewController: BaseViewController {
  
    @IBOutlet weak var topContentShadowView: CornerAndShadowView!
    
    @IBOutlet weak var themeShadowView: CornerAndShadowView!
    
  @IBOutlet weak var language: NormalCellView!
  @IBOutlet weak var frequency: NormalCellView!
  @IBOutlet weak var version: NormalCellView!
  @IBOutlet weak var theme: NormalCellView!
  
  @IBOutlet weak var logoutView: Button!
  var coordinator: (SettingCoordinatorProtocol & SettingStateManagerProtocol)?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.localized_text = R.string.localizable.navSetting.key.localizedContainer()
    if #available(iOS 11.0, *) {
      navigationItem.largeTitleDisplayMode = .always
    }
    setupUI()
    setupNotification()
    setupEvent()
    if !UserManager.shared.isLoginIn{
      self.logoutView.isHidden = true
    }
    self.logoutView.rx.tapGesture().when(.recognized).subscribe(onNext: {[weak self] tap in
      guard let `self` = self else { return }
      
      UserManager.shared.logout()
      self.coordinator?.dismiss()
    }).disposed(by: disposeBag)
  }
  
  func setupUI() {
    language.content_locali =  R.string.localizable.setting_language.key.localized()
    version.content.text = Bundle.main.version
    theme.content_locali = ThemeManager.currentThemeIndex == 0 ? R.string.localizable.dark.key.localized() : R.string.localizable.light.key.localized()
    frequency.content_locali = UserManager.shared.frequency_type.description()
    self.topContentShadowView.newShadowColor = ThemeManager.currentThemeIndex == 0 ? UIColor.black10 : UIColor.steel20
    self.themeShadowView.newShadowColor = ThemeManager.currentThemeIndex == 0 ? UIColor.black10 : UIColor.steel20
  }
  
  
  func setupEvent() {
    let itemsView = [language,frequency,version,theme]
    
    for itemView in itemsView {
      itemView?.rx.tapGesture().when(.ended).asObservable().subscribe(onNext: { [weak self](tap) in
        guard let `self` = self else { return }
        if let view = tap.view as? NormalCellView {
          self.clickCellView(view)
        }
        }, onError: nil, onCompleted: nil, onDisposed: nil).disposed(by: disposeBag)
    }
  }
  
  func clickCellView(_ sender : NormalCellView) {
    if sender == language {
      self.coordinator?.openSettingDetail(type: .language)
    }
    else if sender == frequency {
      self.chooseRefreshStyle()
    }
    else if sender == version {
      handlerUpdateVersion({
        self.endLoading()
      }, showNoUpdate: true)
    }
    else {
      self.coordinator?.openSettingDetail(type: .theme)
    }
  }
  
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
  }
  
  func setupNotification() {
    NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: ThemeUpdateNotification), object: nil, queue: nil, using: { [weak self] notification in
      guard let `self` = self else { return }
      self.topContentShadowView.newShadowColor = ThemeManager.currentThemeIndex == 0 ? UIColor.black10 : UIColor.steel20
      self.themeShadowView.newShadowColor = ThemeManager.currentThemeIndex == 0 ? UIColor.black10 : UIColor.steel20
    })
    
    NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: LCLLanguageChangeNotification), object: nil, queue: nil, using: { [weak self] notification in
      guard let `self` = self else { return }
      
      let color = ThemeManager.currentThemeIndex == 0 ? UIColor.dark : UIColor.paleGrey
      self.navigationController?.navigationBar.setBackgroundImage(UIImage(color: color), for: .default)
    })
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
  
  deinit {
    NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: LCLLanguageChangeNotification), object: nil)
    NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: ThemeUpdateNotification), object: nil)
  }
}

extension SettingViewController {
  func chooseRefreshStyle() {
    let actionController = PeriscopeActionController()
    actionController.selectedIndex = IndexPath(row: UserManager.shared.frequency_type.rawValue, section: 0)
    actionController.addAction(Action(R.string.localizable.frequency_normal.key.localized(), style: .destructive, handler: {[weak self] action in
      guard let `self` = self else {return}
      UserManager.shared.frequency_type = .normal
      self.frequency.content_locali = UserManager.shared.frequency_type.description()
    }))
    
    actionController.addAction(Action(R.string.localizable.frequency_time.key.localized(), style: .destructive, handler: { [weak self]action in
      guard let `self` = self else {return}

      UserManager.shared.frequency_type = .time
      self.frequency.content_locali = UserManager.shared.frequency_type.description()

    }))
    
    actionController.addAction(Action(R.string.localizable.frequency_wifi.key.localized(), style: .destructive, handler: { [weak self]action in
      guard let `self` = self else {return}
      UserManager.shared.frequency_type = .WiFi
      self.frequency.content_locali = UserManager.shared.frequency_type.description()
    }))
    
    actionController.addSection(PeriscopeSection())
    actionController.addAction(Action(R.string.localizable.alert_cancle.key.localized(), style: .cancel, handler: { action in
    }))
    
    present(actionController, animated: true, completion: nil)
    
  }
}

