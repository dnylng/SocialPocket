//
//  CircleView.swift
//  SocialPocket
//
//  Created by Danny Luong on 7/27/17.
//  Copyright © 2017 dnylng. All rights reserved.
//

import UIKit

class RoundView: UIImageView {

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layer.cornerRadius = self.frame.width / 2
    }

}
