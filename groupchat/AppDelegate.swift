//
//  AppDelegate.swift
//  groupchat
//
//  Created by JangWooil on 2017. 6. 12..
//  Copyright © 2017년 test. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import UserNotifications
import CRToast

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, FIRMessagingDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        //Firebase.configure()
        FIRApp.configure()
        
        SessionManager.sharedSessionManager().loadingTag = 26 //로딩바 태그
        
        //Push 권한 요청
        if #available(iOS 10.0, *) {
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
            
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            // For iOS 10 data message (sent via FCM)
            FIRMessaging.messaging().remoteMessageDelegate = self
            
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        application.registerForRemoteNotifications()
        
        //토큰 생성 모니터링
        NotificationCenter.default.addObserver(self, selector: #selector(tokenRefreshNotification(_:)), name: NSNotification.Name.firInstanceIDTokenRefresh, object: nil)
        
        self.window = UIWindow.init(frame: UIScreen.main.bounds);
        self.window?.backgroundColor = UIColor.white;
        
        let st = UIStoryboard.init(name: "Main", bundle: nil)
        //let vc = st.instantiateViewController(withIdentifier: "ViewController")
        let vc = st.instantiateViewController(withIdentifier: "RAMAnimatedTabBarController")
            let nav = UINavigationController.init(rootViewController: vc)
            self.window?.rootViewController = nav;
            self.window?.makeKeyAndVisible()
        
        if let refreshedToken = FIRInstanceID.instanceID().token() {
            SessionManager.sharedSessionManager().pushToken = refreshedToken
        }
        
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        FIRInstanceID.instanceID().setAPNSToken(deviceToken, type: FIRInstanceIDAPNSTokenType.sandbox)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        // Print message ID.
//        if let messageID = userInfo[gcmMessageIDKey] {
//            print("Message ID: \(messageID)")
//        }
        
        // Print full message.
        print("didReceiveRemoteNotification1 \(userInfo)")
    }
    
    //앱이 실행중일 때 PUSH가 온 경우 또는 백그라운드에서 푸쉬를 클릭한 경우
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
//        if let messageID = userInfo[gcmMessageIDKey] {
//            print("Message ID: \(messageID)")
//        }
        
        //앱 실행 중 푸쉬
        if(application.applicationState == .active){
            print("Active")
            if let apsData = userInfo["aps"] as? NSDictionary {
                if let msg = apsData["alert"] as? String {
                    let options:[AnyHashable:Any]  = [
                        kCRToastTextKey : msg,
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
            }
        } else {
            print("Background")
        }
        
        // Print full message.
        print("didReceiveRemoteNotification2 \(userInfo)")
        
        completionHandler(UIBackgroundFetchResult.newData)
    }
    
    func applicationReceivedRemoteMessage(_ remoteMessage: FIRMessagingRemoteMessage) {
        print("applicationReceivedRemoteMessage [\(remoteMessage.appData)]")
    }
    
    func tokenRefreshNotification(_ notification: Notification) {
        if let refreshedToken = FIRInstanceID.instanceID().token() {
            SessionManager.sharedSessionManager().pushToken = refreshedToken
            //토큰 정보를 업데이트 한다.
            let ref = FIRDatabase.database().reference()
            ref.child("users").child(SessionManager.sharedSessionManager().uuid).updateChildValues(["token":refreshedToken])
        }
        
        // Connect to FCM since connection may have failed when attempted before having a token.
        connectToFcm()
    }
    
    func connectToFcm() {
        FIRMessaging.messaging().connect { (error) in
            if error != nil {
                print("Unable to connect with FCM. \(error)")
            } else {
                print("Connected to FCM.")
            }
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        FIRMessaging.messaging().disconnect()
        print("Disconnected from FCM.")
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

