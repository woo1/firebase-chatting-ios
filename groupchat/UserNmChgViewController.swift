//
//  UserNmChgViewController.swift
//  groupchat
//
//  Created by JangWooil on 2017. 6. 16..
//  Copyright © 2017년 test. All rights reserved.
//

import UIKit
import FirebaseDatabase

class UserNmChgViewController: UIViewController, NVActivityIndicatorViewable {

    @IBOutlet var nmTxtf: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nmTxtf.text = SessionManager.sharedSessionManager().userName
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //이름 변경
    @IBAction func chgBtnClicked(_ sender: Any) {
        if let nm = nmTxtf.text?.trimmingCharacters(in: .whitespacesAndNewlines) {
            if(nm.characters.count > 10){
                showAlert(msg: "이름은 10자까지 입력 가능합니다.", complete: nil)
                return
            }
            
            //로딩 시작
            self.startAnimating(self.getLoadingSize(), message: self.getLoadingMsg(), type: self.getLoadingType())
            let ref = FIRDatabase.database().reference()
            
            ref.child("users").child(SessionManager.sharedSessionManager().uuid).updateChildValues(["username": nm], withCompletionBlock: {
                error, ref in
                self.stopAnimating()
                SessionManager.sharedSessionManager().userName = nm
                self.navigationController?.popViewController(animated: true)
            })
        }
    }

}
