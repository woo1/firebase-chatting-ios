//
//  NewChatViewController.swift
//  groupchat
//
//  Created by JangWooil on 2017. 6. 13..
//  Copyright © 2017년 test. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseMessaging

class NewChatViewController: UIViewController, NVActivityIndicatorViewable {

    @IBOutlet var roomNmTxtf: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //채팅방 생성
    @IBAction func newBtnClicked(_ sender: Any) {
        if roomNmTxtf.text != nil && roomNmTxtf.text!.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
            let ref = FIRDatabase.database().reference()
            let roomNm = roomNmTxtf.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            
            self.view.isUserInteractionEnabled = false
            //로딩 시작
            startAnimating(getLoadingSize(), message: getLoadingMsg(), type: getLoadingType())
            
            //채팅방 ID 구하기
            var indexNo = 1
            ref.child("/chattingroom").queryOrderedByValue().queryLimited(toLast: 1).observeSingleEvent(of: .value, with: { (snapshot) in
                
                //MAX 인덱스값 구하기
                if let postDict = snapshot.valueInExportFormat() as? NSDictionary {
                    if let keyStr = postDict.allKeys[0] as? String {
                        indexNo = Int(keyStr)! + 1
                        print("indexNo \(indexNo)")
                    }
                }
                
                //채팅룸 생성
                let uuid = SessionManager.sharedSessionManager().uuid
                
                
                ref.child("chattingroom").child("\(indexNo)").setValue(["roomname": "\(roomNm)", "users": ["\(uuid)":["alarm":"Y"]]], withCompletionBlock: {
                    error, ref in
                                            
                    //사용자 데이터에서 채팅방 번호, 이름 넣기
                    let ref2 = FIRDatabase.database().reference()
                    ref2.child("users").child("\(uuid)").child("chatrooms").updateChildValues(["\(indexNo)":roomNm], withCompletionBlock: {
                        err, ref in
                        
                        //3. 푸쉬 채팅방 그룹 만들기
                        Transaction().sendNewGroup(groupNm: "room\(indexNo)", userToken: SessionManager.sharedSessionManager().pushToken, completeBlock: {
                            self.view.isUserInteractionEnabled = true
                            self.stopAnimating()
                            
                            //세션에 채팅방 추가
                            SessionManager.sharedSessionManager().addChatRoom(roomName: roomNm, roomId: "\(indexNo)")
                            
                            self.showAlert(msg: "추가되었습니다.", complete: {
                                SessionManager.sharedSessionManager().chatrooms.append(["roomName":roomNm, "roomId":"\(indexNo)"])
                                self.navigationController?.popViewController(animated: true)
                            })
                        })
                    })
                })
                    
            }) { (error) in
                print(error.localizedDescription)
            }
        }
    }
    
    
}
