//
//  SessionManager.swift
//  groupchat
//
//  Created by JangWooil on 2017. 6. 14..
//  Copyright © 2017년 test. All rights reserved.
//

import Foundation

class SessionManager: NSObject {
    var chatrooms : [Dictionary<String, String>] = []
    var userName : String = ""
    var uuid    = ""
    var pushToken = ""
    var loadingTag = 26
    var chatUserList : [Dictionary<String, String>] = []
    var skin = ""
    
    struct SessionInstance {
        static var sharedSession : SessionManager? = nil
    }
    
    class func sharedSessionManager() -> SessionManager{
        if(SessionInstance.sharedSession == nil){
            SessionInstance.sharedSession = SessionManager()
        }
        
        return SessionInstance.sharedSession!
    }

    /**
     채팅방 데이터를 추가한다.
     */
    func addChatRoom(roomName: String, roomId: String){
        chatrooms.append(["roomName":roomName, "roomId":roomId, "lastTime":"", "lastMessage":"", "alarmYN":"Y"])
    }
    
    func removeChatRoom(index: Int){
        chatrooms.remove(at: index)
    }
}
