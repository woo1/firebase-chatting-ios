//
//  ChatMainViewController.swift
//  groupchat
//
//  Created by JangWooil on 2017. 6. 19..
//  Copyright © 2017년 test. All rights reserved.
//

import UIKit
import SideMenu

class ChatMainViewController: UIViewController {
    
    var roomId : String?
    var roomName : String?
    var notiKey : String?
    
    var rightView : MemberViewController?
    var rightViewOpen = false
    var bgView : UIView?
    var added = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let button = UIButton.init(frame: CGRect.init(x: 0, y: 0, width: 28, height: 28))
        button.setImage(UIImage.init(named: "ic_view_headline"), for: .normal)
        button.addTarget(self, action: #selector(rightBtnClicked), for: .touchUpInside)
        button.backgroundColor = UIColor.init(colorLiteralRed: 166/255, green: 76/255, blue: 166/255, alpha: 1)
        
        let rightItem = UIBarButtonItem.init(customView: button)
        self.navigationItem.rightBarButtonItems = [rightItem]
        
        SideMenuManager.menuFadeStatusBar = false
    }
    
    func rightBtnClicked(){
        
    }
    
    func setting(){
        if let mainVC = self.storyboard?.instantiateViewController(withIdentifier: "CustomChatViewController") as? CustomChatViewController {
            mainVC.roomId = roomId
            mainVC.roomName = roomName
            mainVC.notiKey  = notiKey
            self.title = roomName
            
//            self.view.addSubview(mainVC.view)
        }
        if let rightVC = self.storyboard?.instantiateViewController(withIdentifier: "MemberViewController") as? MemberViewController {
//            rightView = rightVC
//            let deviceS = UIScreen.main.bounds
//            let leftMargin : CGFloat = 100
//            rightView?.view.frame = CGRect.init(x: leftMargin, y: 0, width: deviceS.width-leftMargin, height: deviceS.height)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
