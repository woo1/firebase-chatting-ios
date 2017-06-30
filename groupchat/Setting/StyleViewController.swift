//
//  StyleViewController.swift
//  groupchat
//
//  Created by JangWooil on 2017. 6. 20..
//  Copyright © 2017년 test. All rights reserved.
//

import UIKit
import FirebaseDatabase

class StyleViewController: UIViewController, NVActivityIndicatorViewable {

    @IBOutlet var btn2: UIButton!
    @IBOutlet var btn1: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        btn1.accessibilityLabel = "기본 스타일의 채팅방 배경"
        btn2.accessibilityLabel = "개발자 스타일의 채팅방 배경"
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //기본 스킨
    @IBAction func defaultSkinClicked(_ sender: Any) {
        updateUserSkin(type: "2")
    }
    
    //개발자 스킨
    @IBAction func helloSkinClicked(_ sender: Any) {
        updateUserSkin(type: "1")
    }
    
    func updateUserSkin(type:String){
        //로딩 시작
        self.startAnimating(self.getLoadingSize(), message: self.getLoadingMsg(), type: self.getLoadingType())
        let ref = FIRDatabase.database().reference()
        
        ref.child("users").child(SessionManager.sharedSessionManager().uuid).updateChildValues(["skin": type], withCompletionBlock: {
            error, ref in
            self.stopAnimating()
            SessionManager.sharedSessionManager().skin = type
            self.navigationController?.popViewController(animated: true)
        })
    }
    
}
