//
//  StyleView.swift
//  SocialPocket
//
//  Created by Danny Luong on 7/26/17.
//  Copyright © 2017 dnylng. All rights reserved.
//

import UIKit

class StyleView: UIView {

    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Adds a shadow
        layer.shadowColor = UIColor(red: SHADOW_GRAY, green: SHADOW_GRAY, blue: SHADOW_GRAY, alpha: 0.6).cgColor
        layer.shadowOpacity = 0.8
        layer.shadowRadius = 5.0
        layer.shadowOffset = CGSize(width: 1.0, height: 1.0)
        layer.cornerRadius = 4.0
    }

}
