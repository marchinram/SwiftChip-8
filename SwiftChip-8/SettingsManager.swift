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
    
    public static let yellowishPixelColor = #colorLiteral(red: 1, green: 0.768627451, blue: 0, alpha: 1)
    
    public static let orangeBackgroundColor = #colorLiteral(red: 0.6901960784, green: 0.2901960784, blue: 0, alpha: 1)
    
    private init() {
        let pixelRGBA: (Float, Float, Float, Float) = SettingsManager.yellowishPixelColor.separate()
        let bgRGBA: (Float, Float, Float, Float) = SettingsManager.orangeBackgroundColor.separate()
        UserDefaults.standard.register(defaults:[
            "pixelColorR": pixelRGBA.0,
            "pixelColorG": pixelRGBA.1,
            "pixelColorB": pixelRGBA.2,
            "pixelColorA": pixelRGBA.3,
            "backgroundColorR": bgRGBA.0,
            "backgroundColorG": bgRGBA.1,
            "backgroundColorB": bgRGBA.2,
            "backgroundColorA": bgRGBA.3,
            "buzzerNote": Buzzer.Frequency.C4.rawValue,
            "buzzerVolume": 1.0
        ])
    }
    
    public var pixelColor: UIColor {
        get {
            let r = CGFloat(UserDefaults.standard.float(forKey: "pixelColorR"))
            let g = CGFloat(UserDefaults.standard.float(forKey: "pixelColorG"))
            let b = CGFloat(UserDefaults.standard.float(forKey: "pixelColorB"))
            let a = CGFloat(UserDefaults.standard.float(forKey: "pixelColorA"))
            return UIColor(red: r, green: g, blue: b, alpha: a)
        }
        set {
            let rgba: (CGFloat, CGFloat, CGFloat, CGFloat) = newValue.separate()
            UserDefaults.standard.set(rgba.0, forKey: "pixelColorR")
            UserDefaults.standard.set(rgba.1, forKey: "pixelColorG")
            UserDefaults.standard.set(rgba.2, forKey: "pixelColorB")
            UserDefaults.standard.set(rgba.3, forKey: "pixelColorA")
        }
    }
    
    public var backgroundColor: UIColor {
        get {
            let r = CGFloat(UserDefaults.standard.float(forKey: "backgroundColorR"))
            let g = CGFloat(UserDefaults.standard.float(forKey: "backgroundColorG"))
            let b = CGFloat(UserDefaults.standard.float(forKey: "backgroundColorB"))
            let a = CGFloat(UserDefaults.standard.float(forKey: "backgroundColorA"))
            return UIColor(red: r, green: g, blue: b, alpha: a)
        }
        set {
            let rgba: (CGFloat, CGFloat, CGFloat, CGFloat) = newValue.separate()
            UserDefaults.standard.set(rgba.0, forKey: "backgroundColorR")
            UserDefaults.standard.set(rgba.1, forKey: "backgroundColorG")
            UserDefaults.standard.set(rgba.2, forKey: "backgroundColorB")
            UserDefaults.standard.set(rgba.3, forKey: "backgroundColorA")
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
        let rgba: (Float, Float, Float, Float) = separate()
        return GLKVector4Make(rgba.0, rgba.1, rgba.2, rgba.3)
    }
    
    var floatTuple: (Float, Float, Float, Float) {
        return separate()
    }
    
    fileprivate func separate<T: BinaryFloatingPoint>() -> (T, T, T, T) {
        var r: CGFloat = 0.0
        var g: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 0.0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return (T(Float(r)), T(Float(g)), T(Float(b)), T(Float(a)))
    }
    
}
