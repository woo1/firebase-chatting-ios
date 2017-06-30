//
//  Extensions.swift
//  groupchat
//
//  Created by JangWooil on 2017. 6. 14..
//  Copyright © 2017년 test. All rights reserved.
//

import UIKit

extension UIViewController {
    func getUUID()->String? {
        let uuidStr = UIDevice.current.identifierForVendor
        return uuidStr?.uuidString.replacingOccurrences(of: "-", with: "")
    }
    
    func getFormatDt()->String{
        let date = Date.init()
        let formatter = DateFormatter.init()
        formatter.dateFormat = "yyyyMMddHHmmss"
        let formatted = formatter.string(from: date)
        
        return formatted
    }
        
    func getLoadingType()->NVActivityIndicatorType{
        return NVActivityIndicatorType(rawValue: SessionManager.sharedSessionManager().loadingTag)!
    }
    
    func getLoadingMsg()->String {
        return "Loading..."
    }
    
    func getLoadingSize()->CGSize {
        return CGSize(width: 30, height: 30)
    }
    
    func showAlert(msg: String, complete:((Void)->Void)?){
        let ac = UIAlertController.init(title: "알림", message: msg, preferredStyle: .alert)
        let action = UIAlertAction.init(title: "확인", style: .cancel, handler: {
            _ in
            if complete != nil {
                complete!()
            }
        })
        ac.addAction(action)
        
        self.present(ac, animated: true, completion: nil)
    }
    
    func showAlert2(msg: String, complete:((Void)->Void)?){
        let ac = UIAlertController.init(title: "알림", message: msg, preferredStyle: .alert)
        let action1 = UIAlertAction.init(title: "취소", style: .cancel, handler: {
            _ in
        })
        let action2 = UIAlertAction.init(title: "확인", style: .default, handler: {
            _ in
            if complete != nil {
                complete!()
            }
        })
        ac.addAction(action1)
        ac.addAction(action2)
        
        self.present(ac, animated: true, completion: nil)
    }
    
    //세션의 채팅방 정보를 업데이트 한다
    func updateChatRInfo(message: String, time: String, roomId: String){
        if(SessionManager.sharedSessionManager().chatrooms.count > 0){
            for i in 0..<SessionManager.sharedSessionManager().chatrooms.count {
                if let oRoomId = SessionManager.sharedSessionManager().chatrooms[i]["roomId"] {
                    if(oRoomId == roomId){
                        SessionManager.sharedSessionManager().chatrooms[i]["lastTime"] = time
                        SessionManager.sharedSessionManager().chatrooms[i]["lastMessage"] = message
                        break
                    }
                }
            }
        }
    }
    
}

extension String {
    //인덱스로 string 자르기
    func substring(startIdx: Int, endIdx:Int)->String{
        if(startIdx == 0){
            let range1 = Range<String.Index>((self.startIndex) ..< (self.index((self.startIndex), offsetBy: endIdx+1)))
            return self.substring(with: range1)
        } else {
            let range1 = Range<String.Index>(self.index(self.startIndex, offsetBy: startIdx) ..< (self.index(self.startIndex, offsetBy: endIdx+1)))
            return self.substring(with: range1)
        }
    }
    
    func toMMSS()->String?{
        if(self.characters.count < 12){
            return nil
        } else {
            return self.substring(startIdx: 8, endIdx: 9) + ":" + self.substring(startIdx: 10, endIdx: 11)
        }
    }
}
