//
//  SettingsManager.swift
//  SwiftChip-8
//
//  Created by Brian Rojas on 8/24/17.
//  Copyright © 2017 Brian Rojas. All rights reserved.
//

import Foundation
import GLKit

class SettingsManager {
    
    public static let instance = SettingsManager()
    
    public static let yellowishPixelColor = UIColor(colorLiteralRed: 1.0, green: 196.0/255.0, blue: 0.0, alpha: 1.0)
    
    public static let orangeBackgroundColor = UIColor(colorLiteralRed: 176.0/255.0, green: 74.0/255.0, blue: 0.0, alpha: 1.0)
    
    private init() {
        var pixelRGBA = [CGFloat](repeating: 0.0, count: 4)
        SettingsManager.yellowishPixelColor.getRed(&pixelRGBA[0], green: &pixelRGBA[1], blue: &pixelRGBA[2], alpha: &pixelRGBA[3])
        var bgRGBA = [CGFloat](repeating: 0.0, count: 4)
        SettingsManager.orangeBackgroundColor.getRed(&bgRGBA[0], green: &bgRGBA[1], blue: &bgRGBA[2], alpha: &bgRGBA[3])
        UserDefaults.standard.register(defaults:[
            "pixelColorR": pixelRGBA[0],
            "pixelColorG": pixelRGBA[1],
            "pixelColorB": pixelRGBA[2],
            "pixelColorA": pixelRGBA[3],
            "backgroundColorR": bgRGBA[0],
            "backgroundColorG": bgRGBA[1],
            "backgroundColorB": bgRGBA[2],
            "backgroundColorA": bgRGBA[3],
            "buzzerNote": Buzzer.Frequency.C4.rawValue,
            "buzzerVolume": 1.0
        ])
    }
    
    public var pixelColor: UIColor {
        get {
            let r = UserDefaults.standard.float(forKey: "pixelColorR")
            let g = UserDefaults.standard.float(forKey: "pixelColorG")
            let b = UserDefaults.standard.float(forKey: "pixelColorB")
            let a = UserDefaults.standard.float(forKey: "pixelColorA")
            return UIColor(colorLiteralRed: r, green: g, blue: b, alpha: a)
        }
        set {
            var rgba = [CGFloat](repeating: 0.0, count: 4)
            newValue.getRed(&rgba[0], green: &rgba[1], blue: &rgba[2], alpha: &rgba[3])
            UserDefaults.standard.set(rgba[0], forKey: "pixelColorR")
            UserDefaults.standard.set(rgba[1], forKey: "pixelColorG")
            UserDefaults.standard.set(rgba[2], forKey: "pixelColorB")
            UserDefaults.standard.set(rgba[3], forKey: "pixelColorA")
        }
    }
    
    public var backgroundColor: UIColor {
        get {
            let r = UserDefaults.standard.float(forKey: "backgroundColorR")
            let g = UserDefaults.standard.float(forKey: "backgroundColorG")
            let b = UserDefaults.standard.float(forKey: "backgroundColorB")
            let a = UserDefaults.standard.float(forKey: "backgroundColorA")
            return UIColor(colorLiteralRed: r, green: g, blue: b, alpha: a)
        }
        set {
            var rgba = [CGFloat](repeating: 0.0, count: 4)
            newValue.getRed(&rgba[0], green: &rgba[1], blue: &rgba[2], alpha: &rgba[3])
            UserDefaults.standard.set(rgba[0], forKey: "backgroundColorR")
            UserDefaults.standard.set(rgba[1], forKey: "backgroundColorG")
            UserDefaults.standard.set(rgba[2], forKey: "backgroundColorB")
            UserDefaults.standard.set(rgba[3], forKey: "backgroundColorA")
        }
    }
    
    public var buzzerNote: Buzzer.Frequency {
        get {
            let rawValue = UserDefaults.standard.float(forKey: "buzzerNote")
            return Buzzer.Frequency(rawValue: rawValue) ?? Buzzer.Frequency.C4
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "buzzerNote")
        }
    }
    
    public var buzzerVolume: Float {
        get {
            return UserDefaults.standard.float(forKey: "buzzerVolume")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "buzzerVolume")
        }
    }
    
}

extension UIColor {
    
    var glkVector4: GLKVector4 {
        var rgba = [CGFloat](repeating: 0.0, count: 4)
        getRed(&rgba[0], green: &rgba[1], blue: &rgba[2], alpha: &rgba[3])
        return GLKVector4Make(Float(rgba[0]), Float(rgba[1]), Float(rgba[2]), Float(rgba[3]))
    }
    
    var floatTuple: (Float, Float, Float, Float) {
        var rgba = [CGFloat](repeating: 0.0, count: 4)
        getRed(&rgba[0], green: &rgba[1], blue: &rgba[2], alpha: &rgba[3])
        return (Float(rgba[0]), Float(rgba[1]), Float(rgba[2]), Float(rgba[3]))
    }
    
}
