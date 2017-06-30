//
//  CustomChatViewController.swift
//  groupchat
//
//  Created by JangWooil on 2017. 6. 13..
//  Copyright © 2017년 test. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseMessaging
import SideMenu

class CustomChatViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    
    @IBOutlet var chatTableview: UITableView!
    @IBOutlet var cTextField : UITextField!
    @IBOutlet var inTxtView: UIView!
    
    var messageList : [[String : AnyObject]] = []
    var uuidStr = ""
    var kOFFSET_FOR_KEYBOARD : CGFloat = 200//80.0
    
    @IBOutlet var bottomConst: NSLayoutConstraint!
    private var tvContentHeight : CGFloat = 0
    private var originalCons : CGFloat = 0
    private var userList : Dictionary<String, String> = [:]
    private var chatUserList : [Dictionary<String, String>] = []
    
    var roomId : String?
    var roomName : String?
    var notiKey : String?
    var moving = false
    private var userNameAppendix = "" //사용자명 뒤에 붙는거(스타일)
    private var userStyle = "" //사용자 스타일
    private var lastMsgAnimation = false
    private var lastMsgKeyword : [String] = []
    
    var observerHandle : FIRDatabaseQuery?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        uuidStr = SessionManager.sharedSessionManager().uuid
        originalCons = bottomConst.constant
        
        //사용자 스타일 설정에 맞게 색상을 세팅한다.
        userStyle = SessionManager.sharedSessionManager().skin
        if(userStyle == "1"){
            //1. 콘솔
            userNameAppendix = "$"
            self.view.backgroundColor = UIColor.white
            lastMsgAnimation = true
            lastMsgKeyword = ["hello world", "printf", "println", "scanf"]
        } else {
            //2. 기본
        }
        
        //3. 주제 구독 처리(푸쉬 알림)
        if roomId != nil {
            FIRMessaging.messaging().subscribe(toTopic: "room\(roomId!)")
        }
        
        self.title = roomName
        
        //현재 일시를 포맷 맞춰서 가져온다
        let formatted = getFormatDt()
        
        //TODO: User List를 어느 시점에 가져오는 게 빠를 지 확인
        let ref2 = FIRDatabase.database().reference()
        ref2.child("users").observeSingleEvent(of: .value, with: { (snapshot) in
            // Get user value
            let postDict = snapshot.value as! [String : AnyObject]
            for key in postDict.keys {
                let username = postDict[key]!["username"] as! String
                self.userList[key] = username
            }
            
            // 채팅방의 사용자 목록을 조회한다.
            ref2.child("chattingroom/\(self.roomId!)/users").observeSingleEvent(of: .value, with: { (snapshot2) in
                if let postDict2 = snapshot2.valueInExportFormat() as? NSDictionary {
                    for key in postDict2.allKeys {
                        if let sKey = key as? String {
                            if let name = self.userList[sKey] {
                                self.chatUserList.append(["uuid":sKey, "name":name])
                            }
                        }
                    }
                    SessionManager.sharedSessionManager().chatUserList = self.chatUserList
                    
                    //데이터가 추가로 들어오면 수신한다.
                    //TODO: 메모리 문제가 있을수도 있다고 예상되서 50개로 제한함.. -> 로컬 DB 연동 또는 페이징 처리 필요함
                    self.observerHandle = FIRDatabase.database().reference(withPath: "messages/\(self.roomId!)").queryLimited(toLast: 50)
                    self.observerHandle?.observe(FIRDataEventType.childAdded, with: { (snapshot) in
                        let postDict = snapshot.value as! [String : AnyObject]
                        let myUUID = SessionManager.sharedSessionManager().uuid
                        
                        if let time = postDict["time"] as? String, let uuid = postDict["uuid"] as? String{
                            if(Int(formatted)! < Int(time)! && uuid != myUUID){ //현재 이후이고 내가 보낸 게 아니면
                                self.messageList.append(postDict)
                                self.chatTableview.reloadData()
                                self.scrollToLast(block: nil)
                            } else if(Int(formatted)! > Int(time)!){
                                self.messageList.append(postDict)
                                self.chatTableview.reloadData()
                                self.scrollToLast(block: nil)
                            }
                        }
                    })
                }
            })
        }) { (error) in
            print(error.localizedDescription)
        }
        
        //우측 메뉴 네비게이션 버튼
        let button = UIButton.init(frame: CGRect.init(x: 0, y: 0, width: 28, height: 28))
        button.setImage(UIImage.init(named: "ic_view_headline"), for: .normal)
        button.addTarget(self, action: #selector(rightBtnClicked), for: .touchUpInside)
        button.accessibilityLabel = "메뉴버튼"
        
        let rightItem = UIBarButtonItem.init(customView: button)
        self.navigationItem.rightBarButtonItems = [rightItem]
        
        SideMenuManager.menuFadeStatusBar = false
        SideMenuManager.menuPresentMode   = .menuSlideIn
    }
    
    func rightBtnClicked(){
        performSegue(withIdentifier: "showSide", sender: nil)
    }
    
    func scrollToLast(block: ((Void)->Void)?){
        self.chatTableview.scrollToRow(at: IndexPath.init(row: self.messageList.count-1, section: 0), at: .middle, animated: false)
        if(block != nil){
            block!()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // register for keyboard notifications
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(noti:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewDidLayoutSubviews() {
        if(bottomConst.constant > originalCons){
            moving = true
            self.scrollToLast(block: {
                self.moving = false
            })
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        //옵저버 제거
        if observerHandle != nil{
            observerHandle?.removeAllObservers()
        }
        
        // unregister for keyboard notifications while not visible.
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        cTextField.resignFirstResponder()
    }
    
    //MARK: 키보드 업, 다운 시 이벤트 처리
    func keyboardWillShow(noti: Notification) {
        if let keyboardInfo = noti.userInfo {
            if let value = keyboardInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue {
                kOFFSET_FOR_KEYBOARD = value.cgRectValue.height
            }
        }
        
        // Animate the current view out of the way
        self.setViewMovedUp(movedUp: true)
    }
    
    func keyboardWillHide() {
        self.setViewMovedUp(movedUp: false)
    }
    
    //MARK: UITextFieldDelegate
    func textFieldDidBeginEditing(_ textField: UITextField) {
       
    }
    
    //method to move the view up/down whenever the keyboard is shown/dismissed
    func setViewMovedUp(movedUp: Bool)
    {
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(0.3)
        
        //테이블 뷰 콘텐츠 높이 세팅
        if(tvContentHeight == 0){
            tvContentHeight = chatTableview.contentSize.height
        }
        
        var rect = self.view.frame;
        if (movedUp)
        {
            // 1. move the view's origin up so that the text field that will be hidden come above the keyboard
            // 2. increase the size of the view so that the area behind the keyboard is covered up.
//            rect.origin.y = 0 - kOFFSET_FOR_KEYBOARD;
//            rect.size.height = viewHeight + kOFFSET_FOR_KEYBOARD;
            
            bottomConst.constant = originalCons + kOFFSET_FOR_KEYBOARD
        }
        else
        {
            // revert back to the normal state.
//            rect.origin.y += kOFFSET_FOR_KEYBOARD;
//            rect.size.height -= kOFFSET_FOR_KEYBOARD;
            
            bottomConst.constant = originalCons
        }
        
        self.view.frame = rect;
        
        UIView.commitAnimations()
    }
    
    
    
    //메시지 전송
    @IBAction func sendMessageClicked(_ sender: Any) {
        let ref = FIRDatabase.database().reference()
        
        if let uuid = getUUID() {
            if cTextField.text != nil && cTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
                //room number에 따른 메시지를 저장한다.
                let date = Date.init()
                let formatter = DateFormatter.init()
                formatter.dateFormat = "yyyyMMddHHmmss"
                let formatted = formatter.string(from: date)
                let text = cTextField.text!.trimmingCharacters(in: .whitespaces)
                
                ref.child("messages").child(roomId!).childByAutoId().setValue(["uuid": uuid, "message": text, "time":formatted], withCompletionBlock: {
                    error, ref in
                    if((error) != nil){
                        print("전송 오류")
                    } else {
                        //정상이면 푸쉬 요청을 보낸다.
                        Transaction().sendPushRequest(room: "room\(self.roomId!)", message: "\(SessionManager.sharedSessionManager().userName) 님이 메세지를 보냈습니다.")
                    }
                })
                
                messageList.append(["uuid": uuid as AnyObject, "message": text as AnyObject, "time":formatted as AnyObject])
                chatTableview.reloadData()
                
                if(lastMsgAnimation){
                    for keyword in lastMsgKeyword {
                        if(text.range(of: keyword) != nil){
                            //특정 키워드일때 색깔 바꿔준다
                            if let cell = chatTableview.cellForRow(at: IndexPath.init(row: messageList.count - 1, section: 0)) as? ConsoleTableViewCell1 {
                                cell.updateColor()
                            } else if let cell = chatTableview.cellForRow(at: IndexPath.init(row: messageList.count - 1, section: 0)) as? ConsoleTableViewCell2 {
                                cell.updateColor()
                            }
                            break
                        }
                    }
                }
                
                cTextField.text = ""
                self.view.endEditing(true)
            }
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: UITableViewDelegate
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let isMe = (messageList[indexPath.row]["uuid"] as! String) == uuidStr
        let username = userList[(messageList[indexPath.row]["uuid"] as! String)]
        let message = messageList[indexPath.row]["message"] as? String
        let time = messageList[indexPath.row]["time"] as! String
        var timeTxt = time.substring(startIdx: 8, endIdx: 9) + ":" + time.substring(startIdx: 10, endIdx: 11)
        
        if(messageList.count > 1 && indexPath.row < messageList.count - 1){
            let nextIsMe = messageList[indexPath.row+1]["uuid"] as! String == uuidStr
            if(time.substring(startIdx: 0, endIdx: 9) == (messageList[indexPath.row+1]["time"] as! String).substring(startIdx: 0, endIdx: 9)){
                if(nextIsMe == isMe){
                    timeTxt = ""
                }
            }
        }
        
        let iconShow = userStyle != "1"
        
        if(messageList.count > 1 && indexPath.row > 0){
            let bfIsMe = messageList[indexPath.row-1]["uuid"] as! String == uuidStr
            
            // 지금 꺼가 내가 보낸 거면
            if(isMe){
                if(!iconShow){ //콘솔
                    let cell = tableView.dequeueReusableCell(withIdentifier: "cCell1", for: indexPath) as! ConsoleTableViewCell1
                    cell.setData(msg: message, usernm: userNameAppendix+username!, time: timeTxt)
                    
                    return cell
                } else {
                    //앞 뒤가 같으면
                    if(bfIsMe == isMe){
                        let cell = tableView.dequeueReusableCell(withIdentifier: "sCell2", for: indexPath) as! ChatTableViewCellSelf2
                        cell.setData(msg: message, time: timeTxt)
                        
                        return cell
                    } else { //다르면
                        let cell = tableView.dequeueReusableCell(withIdentifier: "sCell1", for: indexPath) as! ChatTableViewCellSelf1
                        cell.setData(msg: message, nm: username, time: timeTxt)
                        
                        return cell
                    }
                }
            } else {
                let currentUUID = messageList[indexPath.row]["uuid"] as! String
                let beforeUUID = messageList[indexPath.row-1]["uuid"] as! String
                
                if(!iconShow){ //콘솔
                    let cell = tableView.dequeueReusableCell(withIdentifier: "cCell2", for: indexPath) as! ConsoleTableViewCell2
                    cell.setData(msg: message, usernm: username!+userNameAppendix, time: timeTxt)
                    
                    return cell
                } else {
                    //앞 뒤가 같으면
                    if(beforeUUID == currentUUID){
                        let cell = tableView.dequeueReusableCell(withIdentifier: "oCell2", for: indexPath) as! ChatTableViewCellOther2
                        cell.setData(msg: message, time: timeTxt)
                        
                        return cell
                    } else { //다르면
                        let cell = tableView.dequeueReusableCell(withIdentifier: "oCell1", for: indexPath) as! ChatTableViewCellOther1
                        cell.setData(msg: message, nm: username, time: timeTxt)
                        
                        return cell
                    }
                }
            }
            //
        } else {
            if(isMe){
                if(!iconShow){ //콘솔
                    let cell = tableView.dequeueReusableCell(withIdentifier: "cCell1", for: indexPath) as! ConsoleTableViewCell1
                    cell.setData(msg: message, usernm: userNameAppendix+username!, time: timeTxt)
                    
                    return cell
                } else {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "sCell1", for: indexPath) as! ChatTableViewCellSelf1
                    cell.setData(msg: message, nm: username, time: timeTxt)
                    
                    return cell
                }
            } else {
                if(!iconShow){ //콘솔
                    let cell = tableView.dequeueReusableCell(withIdentifier: "cCell2", for: indexPath) as! ConsoleTableViewCell2
                    cell.setData(msg: message, usernm: username!+userNameAppendix, time: timeTxt)
                    
                    return cell
                } else {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "oCell1", for: indexPath) as! ChatTableViewCellOther1
                    cell.setData(msg: message, nm: username, time: timeTxt)
                    
                    return cell
                }
            }
        }
    }
    
    func getLineNo(message: String?, rowHeight:Int)->CGFloat?{
        if(message != nil){
            let lineNo = CGFloat(message!.characters.count) / 19
            if(lineNo > 1){
                return CGFloat((Int(lineNo)+1) * rowHeight)
            }
        }
        
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let isMe = (messageList[indexPath.row]["uuid"] as! String) == uuidStr
        let iconShow = userStyle != "1"
        let message = messageList[indexPath.row]["message"] as? String
        
        if(!iconShow){ //콘솔
            let lineNo = getLineNo(message: message, rowHeight: 25)
            if(lineNo != nil){
                return lineNo!
            }
            return 25
        }
        
        if(messageList.count > 1 && indexPath.row > 0){
            let bfIsMe = messageList[indexPath.row-1]["uuid"] as! String == uuidStr
            var rowHeight = 0
            
            // 지금 꺼가 내가 보낸 거면
            if(isMe){
                //앞 뒤가 같으면
                if(bfIsMe == isMe){
//                    return 35
                    rowHeight = 35
                } else { //다르면
//                    return 60
                    rowHeight = 60
                    /*
                     
                     */
                }
            } else {
                let currentUUID = messageList[indexPath.row]["uuid"] as! String
                let beforeUUID = messageList[indexPath.row-1]["uuid"] as! String
                
                //앞 뒤가 같으면
                if(beforeUUID == currentUUID){
//                    return 35
                    rowHeight = 35
                } else { //다르면
//                    return 60
                    rowHeight = 60
                }
            }
            
            let lineNo = getLineNo(message: message, rowHeight: rowHeight)
            if(lineNo != nil){
                return lineNo!
            } else {
                return CGFloat(rowHeight)
            }
            //
        } else {
            let lineNo = getLineNo(message: message, rowHeight: 60)
            if(lineNo != nil){
                return lineNo!
            } else {
                return 60
            }
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messageList.count
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if(!moving){
//            self.view.endEditing(true)
        }
    }
}

class ChatTableViewCellSelf1: UITableViewCell {
    @IBOutlet var userName: UILabel!
    @IBOutlet var whiteBox: UIView!
    @IBOutlet var message: UILabel!
    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var userIcon: UIImageView!
    
    func setData(msg: String?, nm: String?, time: String?){
        message.text = msg
        userName.text = nm
        timeLabel.text = time
        message.sizeToFit()
        userIcon.accessibilityLabel = "사용자아이콘"
    }
}

class ChatTableViewCellSelf2: UITableViewCell {
    @IBOutlet var whiteBox: UIView!
    @IBOutlet var message: UILabel!
    @IBOutlet var timeLabel: UILabel!
    
    func setData(msg: String?, time: String?){
        message.text = msg
        timeLabel.text = time
        message.sizeToFit()
    }
}

class ChatTableViewCellOther1: UITableViewCell {
    @IBOutlet var userIcon: UIImageView!
    @IBOutlet var userName: UILabel!
    @IBOutlet var whiteBox: UIView!
    @IBOutlet var message: UILabel!
    @IBOutlet var timeLabel: UILabel!
    
    func setData(msg: String?, nm: String?, time: String?){
        message.text = msg
        userName.text = nm
        timeLabel.text = time
        message.sizeToFit()
        userIcon.accessibilityLabel = "사용자아이콘"
    }
}

class ChatTableViewCellOther2: UITableViewCell {
    @IBOutlet var whiteBox: UIView!
    @IBOutlet var message: UILabel!
    @IBOutlet var timeLabel: UILabel!
    
    func setData(msg: String?, time: String?){
        message.text = msg
        timeLabel.text = time
        message.sizeToFit()
    }
}

//콘솔 스타일
class ConsoleTableViewCell1: UITableViewCell {
    @IBOutlet var userName: UILabel!
    @IBOutlet var message: UILabel!
    @IBOutlet var timeLabel: UILabel!
    
    func setData(msg: String?, usernm: String?, time: String?){
        message.text = msg
        userName.text = usernm
        timeLabel.text = time
        userName.sizeToFit()
        self.selectionStyle = .none
    }
    
    func updateColor(){
        message.textColor = UIColor.init(colorLiteralRed: 0/255, green: 132/255, blue: 4/255, alpha: 1)
    }
}
class ConsoleTableViewCell2: UITableViewCell {
    @IBOutlet var userName: UILabel!
    @IBOutlet var message: UILabel!
    @IBOutlet var timeLabel: UILabel!
    
    func setData(msg: String?, usernm: String?, time: String?){        
        message.text = msg
        userName.text = usernm
        timeLabel.text = time
        userName.sizeToFit()
        self.selectionStyle = .none
    }
    
    func updateColor(){
        message.textColor = UIColor.init(colorLiteralRed: 0/255, green: 132/255, blue: 4/255, alpha: 1)
    }
}
