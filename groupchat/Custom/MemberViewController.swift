//
//  MemberViewController.swift
//  groupchat
//
//  Created by JangWooil on 2017. 6. 19..
//  Copyright © 2017년 test. All rights reserved.
//

import UIKit

/**
  # MemberViewController 클래스 설명
 - 채팅방 안에 있는 사용자들을 보여주는 화면
 */
class MemberViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet var mTableview: UITableView!
    var userList : [Dictionary<String, String>] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        userList = SessionManager.sharedSessionManager().chatUserList
        mTableview.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    //MARK: Animations
    func animateWhenViewAppear(){
        UIView.animate(withDuration: 0.3, animations: { () -> Void in
//            self.btnCloseTableViewMenu.alpha = 0.3
            self.mTableview.frame = CGRect(x: self.mTableview.bounds.size.width, y: 0, width: self.mTableview.bounds.size.width,height: self.mTableview.bounds.size.height)
            self.mTableview.layoutIfNeeded()
        }, completion: nil)
    }
    
    func animateWhenViewDisappear(){
        UIView.animate(withDuration: 0.3, animations: { () -> Void in
//            self.btnCloseTableViewMenu.alpha = 0.0
            self.mTableview.frame = CGRect(x: -self.mTableview.bounds.size.width, y: 0, width: self.mTableview.bounds.size.width,height: self.mTableview.bounds.size.height)
            self.mTableview.layoutIfNeeded()
            self.view.backgroundColor = UIColor.clear
        }, completion: { (finished) -> Void in
            self.willMove(toParentViewController: nil)
            self.view.removeFromSuperview()
            self.removeFromParentViewController()
        })
    }
    
    //MARK: UITableViewDelegate
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! MtableViewCell
        cell.label1.text = userList[indexPath.row]["name"]
        
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userList.count
    }
}

class MtableViewCell: UITableViewCell {
    @IBOutlet var label1: UILabel!
}
