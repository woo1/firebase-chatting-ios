//
//  HeaderView.swift
//  groupchat
//
//  Created by JangWooil on 2017. 6. 16..
//  Copyright © 2017년 test. All rights reserved.
//

import UIKit

class HeaderView: UIView {
    @IBOutlet var textMsg: UILabel!

    convenience init(){
        self.init(frame: CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 40))
        
        if let nibsView = Bundle.main.loadNibNamed("HeaderView", owner: self, options: nil) as? [UIView] {
            let nibRoot = nibsView[0]
            self.addSubview(nibRoot)
            nibRoot.frame = self.bounds
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
