//
//  SettingViewController.swift
//  groupchat
//
//  Created by JangWooil on 2017. 6. 20..
//  Copyright © 2017년 test. All rights reserved.
//

import UIKit

class SettingViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet var sTableView: UITableView!
    private var dataList: [NSDictionary] = [["title":"스타일 설정"]]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //MARK: UITableViewDelegate
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! SettingTableCell
        
        cell.selectionStyle = .none
        cell.label1.text = dataList[indexPath.row]["title"] as? String
        
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataList.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if(indexPath.row == 0){ //스타일 설정
            self.performSegue(withIdentifier: "style", sender: nil)
        }
    }
}

class SettingTableCell: UITableViewCell {
    @IBOutlet var label1: UILabel!
    
}
