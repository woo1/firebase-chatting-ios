//
//  Transaction.swift
//  groupchat
//
//  Created by JangWooil on 2017. 6. 15..
//  Copyright © 2017년 test. All rights reserved.
//

import UIKit
import FirebaseDatabase

class Transaction: NSObject {
    var receivedData : NSMutableData? = nil
    var response     : URLResponse? = nil
    
    //그룹으로 푸쉬 전송(채팅방)
    func sendPushRequest(room: String, message: String){
        let ref = FIRDatabase.database().reference()
        ref.child("chatNoti").child(room).observeSingleEvent(of: .value, with: { (snapshot) in
            // Get user value
            if let postDict = snapshot.valueInExportFormat() as? NSDictionary {
                for key in postDict.allKeys {
                    if let token = postDict[key] as? String {
                        self.sendToPush(to: token, message: message)
                    }
                }
            }
        })
    }
    
    func sendToPush(to:String, message: String){
        let inputDic = ["to":to, "notification":["title":"", "text":message]] as NSDictionary
        
        sendRequest(inputDic: inputDic, header: nil, serverKey:"[YOUR_KEY]", block: nil)
    }
    
    //기기 그룹 만들기
    func sendNewGroup(groupNm: String, userToken: String, completeBlock:((Void)->Void)?){
        //채팅방 그룹 - 사용자 토큰 정보를 담은 데이터를 만든다.
        let ref = FIRDatabase.database().reference()
        ref.child("chatNoti").child(groupNm).updateChildValues([SessionManager.sharedSessionManager().uuid : userToken], withCompletionBlock: {
            err, ref in
            if(completeBlock != nil){
                completeBlock!()
            }
        })
    }
    
    //기기 그룹에 사용자 추가
    func addToGroup(groupNm: String, userToken: String, completeBlock:((Void)->Void)?){
        sendNewGroup(groupNm: groupNm, userToken: userToken, completeBlock: completeBlock)
        //채팅방 그룹 - 사용자 토큰 정보를 담은 데이터를 만든다.
//        let ref = FIRDatabase.database().reference()
//        ref.child("chatNoti").child(groupNm).updateChildValues([SessionManager.sharedSessionManager().uuid : userToken], withCompletionBlock: {
//            err, ref in
//            if(completeBlock != nil){
//                completeBlock!()
//            }
//        })
    }
    
    func sendRequest(inputDic : NSDictionary, header:Dictionary<String, String>?, serverKey:String, block:((NSDictionary)->Void)?){
        if let url = URL.init(string: "https://fcm.googleapis.com/fcm/send") {
            do {
                let inputData = try JSONSerialization.data(withJSONObject: inputDic, options: [])
                print(String.init(data: inputData, encoding: .utf8)!)
                
                var req = URLRequest.init(url: url)
                req.httpMethod = "POST"
                req.setValue("key=\(serverKey)", forHTTPHeaderField: "Authorization")
                req.setValue("application/json", forHTTPHeaderField: "Content-Type")
                req.httpBody = inputData
                
                let queue = OperationQueue.main
                
                NSURLConnection.sendAsynchronousRequest(req, queue: queue, completionHandler: {
                    (response: URLResponse?, data: Data?, error: Error?) in
                    do {
                        if let rtnHtml = String.init(data: data!, encoding: .utf8) {
                            print("rtnHtml \(rtnHtml)")
                        }
                        if let jsonResult = try JSONSerialization.jsonObject(with: data!, options: []) as? NSDictionary {
                            print("sendAsynchronousRequest \(jsonResult)")
                            if(block != nil){
                                block!(jsonResult)
                            }
                        }
                    } catch let error as NSError {
                        print("에러 발생1 \(error.localizedDescription)")
                    }
                })
            } catch let error as NSError {
                print("에러 발생2 \(error.localizedDescription)")
            }
            
        }
    }
    
}
