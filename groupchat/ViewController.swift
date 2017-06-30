//
//  ViewController.swift
//  groupchat
//
//  Created by JangWooil on 2017. 6. 12..
//  Copyright © 2017년 test. All rights reserved.
//

import UIKit
import CRToast
import FirebaseDatabase

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NVActivityIndicatorViewable {

    var roomList : [Dictionary<String, String>] = []
    @IBOutlet var rTableview: UITableView!
    private var selectedRoom : String?
    private var selectedRName : String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        SessionManager.sharedSessionManager().uuid = getUUID()!
        self.title = "채팅방"
        
        //최초접속 X
        if let _ = UserDefaults.standard.object(forKey: "uuid") as? String {
            //로딩 시작
            startAnimating(getLoadingSize(), message: getLoadingMsg(), type: getLoadingType())
            
            //채팅방 목록 조회
            let ref = FIRDatabase.database().reference()
            ref.child("users").child(SessionManager.sharedSessionManager().uuid).observeSingleEvent(of: .value, with: { (snapshot) in
                // Get user value
                if let postDict = snapshot.valueInExportFormat() as? NSDictionary {
                    if let userNm = postDict["username"] as? String {
                        SessionManager.sharedSessionManager().userName = userNm
                    }
                    if let skin = postDict["skin"] as? String {
                        SessionManager.sharedSessionManager().skin = skin
                    }
                    
                    if let chatroom = postDict["chatrooms"] as? NSDictionary {
                        for key in chatroom.allKeys {
                            if let r1 = chatroom[key] as? String, let r2 = key as? String {
                                //마지막 메세지, 일시 조회
                                let ref2 = FIRDatabase.database().reference()
                                ref2.child("messages").child(r2).queryOrdered(byChild: "time").queryLimited(toLast: 1).observeSingleEvent(of: .value, with: {
                                    (snapshot2) in
                                    var sLastTime = ""
                                    var sLastMsg = ""
                                    
                                    if let postDict2 = snapshot2.valueInExportFormat() as? NSDictionary {
                                        if let detailDic = postDict2[postDict2.allKeys[0]] as? NSDictionary {
                                            if let lastMsg = detailDic["message"] as? String, let lastTime = detailDic["time"] as? String {
                                                sLastTime = lastTime.substring(startIdx: 8, endIdx: 9) + ":" + lastTime.substring(startIdx: 10, endIdx: 11)
                                                sLastMsg  = lastMsg
                                            }
                                        }
                                    }
                                    
                                    //알람설정여부 조회
                                    ref2.child("chattingroom").child("\(r2)/users/\(SessionManager.sharedSessionManager().uuid)").queryLimited(toLast: 1).observeSingleEvent(of: .value, with: {
                                        (snapshot3) in
                                        var _alarmYN = "Y"
                                        
                                        if let postDict3 = snapshot3.valueInExportFormat() as? NSDictionary {
                                            if let alarmYN = postDict3["alarm"] as? String {
                                                _alarmYN = alarmYN
                                            }
                                        }
                                        self.stopAnimating()
                                        
                                        self.roomList.append(["roomName":r1, "roomId":r2, "lastTime":sLastTime, "lastMessage":sLastMsg, "alarmYN":_alarmYN])
                                        SessionManager.sharedSessionManager().chatrooms = self.roomList
                                        
                                        self.rTableview.reloadData()
                                    })
                                })
                                
                                let currentDt = self.getFormatDt()
                                //데이터가 추가로 들어오면 수신한다.
                                let ref3 = FIRDatabase.database().reference(withPath: "messages/\(r2)")
                                ref3.observe(FIRDataEventType.childAdded, with: { (snapshot) in
                                    let postDict2 = snapshot.value as! [String : AnyObject]
                                    //로딩바 감추기
                                    self.stopAnimating()
                                    
                                    if let time = postDict2["time"] as? String {
                                        if(Int(time)! > Int(currentDt)!){
                                            if let msg = postDict2["message"] as? String {
                                                self.updateChatRInfo(message: msg, time: time.toMMSS()!, roomId: r2)
                                                self.refreshData()
                                            }
                                        }
                                    }
                                })
                            }
                        }
                    } else {
                        //로딩바 감추기
                        self.stopAnimating()
                        self.rTableview.reloadData()
                    }
                }
                
                // ...
            }) { (error) in
                print(error.localizedDescription)
            }
            
        } else {
            //최초접속
            let ref = FIRDatabase.database().reference()
            let random = arc4random() % 1000
            
            //로딩 시작
            startAnimating(getLoadingSize(), message: getLoadingMsg(), type: getLoadingType())
            
            let uuid = SessionManager.sharedSessionManager().uuid
            ref.child("users").child(uuid).setValue(["username": "user\(random)", "token":SessionManager.sharedSessionManager().pushToken], withCompletionBlock: {
                _,_ in
                self.stopAnimating()
            })
            SessionManager.sharedSessionManager().userName = "user\(random)"
            
            UserDefaults.standard.set(uuid, forKey: "uuid")
            UserDefaults.standard.synchronize()
        }
    }
    
    func refreshData(){
        self.roomList = SessionManager.sharedSessionManager().chatrooms
        rTableview.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        refreshData()
    }
        
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier != nil && segue.identifier! == "chat2"){
            let chatController = segue.destination as! CustomChatViewController
            
            chatController.roomName = selectedRName
            chatController.roomId = selectedRoom
        }
    }
    
    /**
     테스트 버튼을 클릭하는 메소드
     
     - Parameters:
        -sender : 버튼
     
     - Returns: 반환 데이터 없음
     */
    @IBAction func teClicked(_ sender: Any) {
        let options:[AnyHashable:Any]  = [
            kCRToastTextKey : "Hello World! This is a sample message up after loading the view",
            kCRToastBackgroundColorKey : UIColor.init(colorLiteralRed: 47/255, green: 214/255, blue: 239/255, alpha: 1),
            kCRToastTextColorKey: UIColor.yellow,
            kCRToastTextMaxNumberOfLinesKey: 2,
            kCRToastTimeIntervalKey: 3,
            kCRToastUnderStatusBarKey : NSNumber(value: true),
            kCRToastTextAlignmentKey : NSTextAlignment.left.rawValue,
            kCRToastNotificationTypeKey : NSNumber(value: CRToastType.navigationBar.rawValue),
            kCRToastAnimationInTypeKey : CRToastAnimationType.gravity.rawValue,
            kCRToastAnimationOutTypeKey : CRToastAnimationType.gravity.rawValue,
            kCRToastAnimationInDirectionKey : CRToastAnimationDirection.top.rawValue,
            kCRToastAnimationOutDirectionKey : CRToastAnimationDirection.top.rawValue
        ]
        
        CRToastManager.showNotification(options: options, completionBlock: { () -> Void in
            print("done!")
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
    }
    
    //MARK: UITableViewDelegate
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if(indexPath.section == 0){
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell2", for: indexPath) as! MyInfoCell
            
            cell.myName.text = SessionManager.sharedSessionManager().userName
            cell.accessibilityCustomActions = nil
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! RoomTableCell
            
            cell.roomName.text = roomList[indexPath.row]["roomName"]
            cell.lastMessage.text = roomList[indexPath.row]["lastMessage"]
            cell.lastTime.text = roomList[indexPath.row]["lastTime"]
            if let alarmYN = roomList[indexPath.row]["alarmYN"] {
                if(alarmYN == "Y"){
                    cell.unnotiImg.isHidden = true
                } else {
                    cell.unnotiImg.isHidden = false
                }
            } else {
                cell.unnotiImg.isHidden = false
            }
            
            return cell
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(section == 0){
            return 1
        } else {
            return roomList.count
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if(indexPath.section == 0){
            //이름 바꾸기
            self.performSegue(withIdentifier: "nameChange", sender: nil)
        } else {
            selectedRoom = roomList[indexPath.row]["roomId"]
            selectedRName = roomList[indexPath.row]["roomName"]
            self.performSegue(withIdentifier: "chat2", sender: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if(section == 0){
            let headerView = HeaderView.init()
            headerView.textMsg?.text = "내 정보"
            
            return headerView
        } else {
            let headerView = HeaderView.init()
            headerView.textMsg?.text = "채팅방"
            
            return headerView
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        if indexPath.section == 1 {
            let alarmYN = self.roomList[indexPath.row]["alarmYN"]!
            var alarmTxt = "알림켜기"
            var changed  = "Y"
            if(alarmYN == "Y"){
                alarmTxt = "알림끄기"
                changed = "N"
            }
            
            //알림 켜기/끄기
            let alarmBtn = UITableViewRowAction(style: .normal, title: alarmTxt) { action, index in
                //로딩 시작
                self.startAnimating(self.getLoadingSize(), message: self.getLoadingMsg(), type: self.getLoadingType())
                let refOrigin = FIRDatabase.database().reference()
                let selectedId = self.roomList[indexPath.row]["roomId"]!
                
                //채팅방 데이터에서 알림 여부를 업데이트한다.
                refOrigin.child("chattingroom/\(selectedId)/users/\(SessionManager.sharedSessionManager().uuid)").updateChildValues(["alarm":changed], withCompletionBlock: {
                    err, ref in
                    //알림 테이블에 값을 추가하거나 제거한다.
                    if(changed == "Y"){ //Y - 추가
                        refOrigin.child("chatNoti/room\(selectedId)").updateChildValues([SessionManager.sharedSessionManager().uuid:SessionManager.sharedSessionManager().pushToken], withCompletionBlock: {
                            err2, ref2 in
                            self.stopAnimating()
                        })
                    } else { //N - 제거
                        refOrigin.child("chatNoti/room\(selectedId)/\(SessionManager.sharedSessionManager().uuid)").removeValue(completionBlock: {
                            err2, ref2 in
                            self.stopAnimating()
                        })
                    }
                    
                    //세션에 적용한다.
                    SessionManager.sharedSessionManager().chatrooms[indexPath.row]["alarmYN"] = changed
                    self.refreshData()
                })
            }
            alarmBtn.backgroundColor = UIColor.lightGray
            
            //나가기
            let outBtn = UITableViewRowAction(style: .normal, title: "나가기") { action, index in
                let roomNm = self.roomList[indexPath.row]["roomName"] as! String
                self.showAlert2(msg: "\(roomNm) 채팅방을 나가시겠습니까?", complete: {
                    //로딩 시작
                    self.startAnimating(self.getLoadingSize(), message: self.getLoadingMsg(), type: self.getLoadingType())
                    let selectedId = self.roomList[indexPath.row]["roomId"]!
                    
                    //1.사용자 데이터에서 제거한다.
                    let refOrigin = FIRDatabase.database().reference()
                    refOrigin.child("users/\(SessionManager.sharedSessionManager().uuid)/chatrooms/\(selectedId)").removeValue(completionBlock: {
                        err, ref in
                        //2.채팅방 데이터에서 제거한다.
                        refOrigin.child("chattingroom/\(selectedId)/users/\(SessionManager.sharedSessionManager().uuid)").removeValue(completionBlock: {
                            err2, ref2 in
                            //3.Noti 데이터에서 제거한다.
                            refOrigin.child("chatNoti/room\(selectedId)/\(SessionManager.sharedSessionManager().uuid)").removeValue(completionBlock: {
                                err3, ref3 in
                                self.stopAnimating()
                                //세션 데이터에서 제거
                                SessionManager.sharedSessionManager().removeChatRoom(index: indexPath.row)
                                self.refreshData()
                            })
                        })
                    })
                })
            }
            outBtn.backgroundColor = UIColor.orange
            
            return [alarmBtn, outBtn]
        } else {
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        if indexPath.section == 1 {
            return .delete
        } else {
            return .none
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

class RoomTableCell: UITableViewCell {
    @IBOutlet var roomName: UILabel!
    @IBOutlet var lastMessage: UILabel!
    @IBOutlet var lastTime: UILabel!
    @IBOutlet var unnotiImg: UIImageView!
}

class MyInfoCell: UITableViewCell {
    @IBOutlet var myName: UILabel!
    
}
