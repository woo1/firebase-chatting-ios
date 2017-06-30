//
//  ChatRoomViewController.swift
//  groupchat
//
//  Created by JangWooil on 2017. 6. 14..
//  Copyright © 2017년 test. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseMessaging

/**
 # ChatRoomViewController 클래스 설명
 - 채팅방 검색 화면
 */
class ChatRoomViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NVActivityIndicatorViewable {
    
    @IBOutlet var rTableview: UITableView!
    var roomList : [Dictionary<String, String>] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "채팅방 검색"
        //로딩 시작
        startAnimating(getLoadingSize(), message: getLoadingMsg(), type: getLoadingType())
        
        //채팅방 목록 조회
        let ref = FIRDatabase.database().reference()
        ref.child("chattingroom").observeSingleEvent(of: .value, with: { (snapshot) in
            // Get user value
            if let postDict = snapshot.valueInExportFormat() as? NSDictionary {
                for key in postDict.allKeys {
                    if let roomInfo = postDict[key] as? NSDictionary {
                        if let roomName = roomInfo["roomname"] as? String, let users = roomInfo["users"] as? NSDictionary {
                            if(users.allKeys.count > 0){
                                self.roomList.append(["roomName":roomName, "cnt":"\(users.allKeys.count)", "roomId":key as! String])
                            }
                        }
                    }
                }
                self.stopAnimating()
                
                self.rTableview.reloadData()
            }
            
            // ...
        }) { (error) in
            print(error.localizedDescription)
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: UITableViewDelegate
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! ChatRoomSearchTv
        
        cell.roomName.text = roomList[indexPath.row]["roomName"]
        if let cnt = roomList[indexPath.row]["cnt"] {
            cell.peopleCnt.text = "\(cnt)명"
        }
        
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return roomList.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let roomName = roomList[indexPath.row]["roomName"] {
            showAlert2(msg: "\(roomName) 채팅방에 접속하시겠습니까?", complete: {
                self.view.isUserInteractionEnabled = false
                //로딩 시작
                self.startAnimating(self.getLoadingSize(), message: self.getLoadingMsg(), type: self.getLoadingType())
                
                //이미 내가 있는 곳인지 확인한다.
                if let selectedRoomId = self.roomList[indexPath.row]["roomId"] {
                    if(SessionManager.sharedSessionManager().chatrooms.count > 0){
                        for chat in SessionManager.sharedSessionManager().chatrooms {
                            if let roomId = chat["roomId"] {
                                if(selectedRoomId == roomId){
                                    self.view.isUserInteractionEnabled = true
                                    self.stopAnimating()
                                    
                                    self.showAlert(msg: "이미 접속되어 있습니다.", complete: nil)
                                    return
                                    //                                    break
                                }
                            }
                        }
                    }
                    
                    //이미 있는 방이 아니면 연결한다.
                    //1. 사용자 데이터에서 채팅방 번호, 이름 넣기
                    let ref = FIRDatabase.database().reference()
                    ref.child("users").child(SessionManager.sharedSessionManager().uuid).child("chatrooms").updateChildValues(["\(selectedRoomId)":roomName], withCompletionBlock: {
                        err, ref in
                        
                        //2. 채팅룸 데이터에 사용자 정보 넣기
                        let ref2 = FIRDatabase.database().reference()
                        ref2.child("chattingroom").child(selectedRoomId).child("users").child(SessionManager.sharedSessionManager().uuid).updateChildValues(["alarm":"Y"], withCompletionBlock: {
                            err, ref in
                            
                            //3. 주제 구독 처리(푸쉬 알림)
                            Transaction().addToGroup(groupNm: "room\(selectedRoomId)", userToken: SessionManager.sharedSessionManager().pushToken, completeBlock: {
                                self.view.isUserInteractionEnabled = true
                                self.stopAnimating()
                                
                                //세션에 채팅방 추가
                                SessionManager.sharedSessionManager().addChatRoom(roomName: roomName, roomId: selectedRoomId)
                                
                                self.showAlert(msg: "추가되었습니다.", complete: {
                                    self.navigationController?.popViewController(animated: true)
                                })
                            })
                        })
                        self.view.isUserInteractionEnabled = true
                    })
                }
            })
        }
    }

}

class ChatRoomSearchTv: UITableViewCell {
    @IBOutlet var roomName: UILabel!
    @IBOutlet var peopleCnt: UILabel!
    
}
