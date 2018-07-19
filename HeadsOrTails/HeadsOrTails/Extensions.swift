//
//  Extensions.swift
//  HeadsOrTails
//
//  Created by Matheus Garcia on 19/07/18.
//  Copyright © 2018 Matheus Garcia. All rights reserved.
//

import Foundation
import ARKit
import UIKit

extension float4x4 {
    var translation: float3 {
        let translation = self.columns.3
        return float3(translation.x, translation.y, translation.z)
    }
}

extension UIColor {
    open class var transparentLightBlue: UIColor {
        return UIColor(red: 90/255, green: 200/255, blue: 250/255, alpha: 0.50)
    }
}
