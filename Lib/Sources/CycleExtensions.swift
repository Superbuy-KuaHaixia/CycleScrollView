//
//  CycleExtensions.swift
//  CycleExtensions
//
//  Created by wood on 2020/3/26.
//  Copyright © 2020 wood. All rights reserved.
//

import UIKit

// MARK: Frame
extension UIView {
    public var cycle_x: CGFloat {
        get {
            return self.frame.origin.x
        }
        set(value) {
            self.frame = CGRect(x: value, y: self.cycle_y, width: self.cycle_width, height: self.cycle_height)
        }
    }
    
    public var cycle_y: CGFloat {
        get {
            return self.frame.origin.y
        }
        set(value) {
            self.frame = CGRect(x: self.cycle_x, y: value, width: self.cycle_width, height: self.cycle_height)
        }
    }
    
    public var cycle_width: CGFloat {
        get {
            return self.frame.size.width
        } set(value) {
            self.frame = CGRect(x: self.cycle_x, y: self.cycle_y, width: value, height: self.cycle_height)
        }
    }
    
    public var cycle_height: CGFloat {
        get {
            return self.frame.size.height
        } set(value) {
            self.frame = CGRect(x: self.cycle_x, y: self.cycle_y, width: self.cycle_width, height: value)
        }
    }
}
