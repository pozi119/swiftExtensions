//
//  ColorExt.swift
//  ValoKit
//
//  Created by Valo on 2016/11/17.
//
//

import Foundation
#if os(iOS) || os(tvOS)
    import UIKit
    public typealias Color = UIColor
#else
    import AppKit
    public typealias Color = NSColor
#endif

public extension Color {
    // MARK: - Closure

    typealias TransformBlock = (CGFloat) -> CGFloat

    // MARK: - Enums

    enum ColorScheme: Int {
        case analagous = 0, monochromatic, triad, complementary
    }

    enum ColorFormulation: Int {
        case rgba = 0, hsba, lab, cmyk
    }

    enum ColorDistance: Int {
        case cie76 = 0, cie94, cie2000
    }

    enum ColorComparison: Int {
        case darkness = 0, lightness, desaturated, saturated, red, green, blue
    }

    // MARK: - Color from Hex/RGBA/HSBA/CIE_LAB/CMYK

    convenience init(hex: String) {
        var rgbInt: UInt64 = 0
        let newHex = hex.replacingOccurrences(of: "#", with: "")
        let scanner = Scanner(string: newHex)
        scanner.scanHexInt64(&rgbInt)
        let r: CGFloat = CGFloat((rgbInt & 0xFF0000) >> 16) / 255.0
        let g: CGFloat = CGFloat((rgbInt & 0x00FF00) >> 8) / 255.0
        let b: CGFloat = CGFloat(rgbInt & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }

    convenience init(rgba: (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat)) {
        self.init(red: rgba.r, green: rgba.g, blue: rgba.b, alpha: rgba.a)
    }

    fileprivate convenience init(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        self.init(red: r, green: g, blue: b, alpha: a)
    }

    convenience init(hsba: (h: CGFloat, s: CGFloat, b: CGFloat, a: CGFloat)) {
        self.init(hue: hsba.h, saturation: hsba.s, brightness: hsba.b, alpha: hsba.a)
    }

    convenience init(CIE_LAB: (l: CGFloat, a: CGFloat, b: CGFloat, alpha: CGFloat)) {
        // Set Up
        var Y = (CIE_LAB.l + 16.0) / 116.0
        var X = CIE_LAB.a / 500 + Y
        var Z = Y - CIE_LAB.b / 200

        // Transform XYZ
        let deltaXYZ: TransformBlock = { k in
            (pow(k, 3.0) > 0.008856) ? pow(k, 3.0) : (k - 4 / 29.0) / 7.787
        }
        X = deltaXYZ(X) * 0.95047
        Y = deltaXYZ(Y) * 1.000
        Z = deltaXYZ(Z) * 1.08883

        // Convert XYZ to RGB
        let R = X * 3.2406 + (Y * -1.5372) + (Z * -0.4986)
        let G = (X * -0.9689) + Y * 1.8758 + Z * 0.0415
        let B = X * 0.0557 + (Y * -0.2040) + Z * 1.0570
        let deltaRGB: TransformBlock = { k in
            (k > 0.0031308) ? 1.055 * pow(k, 1 / 2.4) - 0.055 : k * 12.92
        }

        self.init(rgba: (deltaRGB(R), deltaRGB(G), deltaRGB(B), CIE_LAB.alpha))
    }

    convenience init(cmyk: (c: CGFloat, m: CGFloat, y: CGFloat, k: CGFloat)) {
        let cmyTransform: TransformBlock = { x in
            x * (1 - cmyk.k) + cmyk.k
        }
        let C = cmyTransform(cmyk.c)
        let M = cmyTransform(cmyk.m)
        let Y = cmyTransform(cmyk.y)
        self.init(rgba: (1 - C, 1 - M, 1 - Y, 1.0))
    }

    // MARK: - Color to Hex/RGBA/HSBA/CIE_LAB/CMYK

    func hexString() -> String {
        let rgbaT = rgba()
        let r: Int = Int(rgbaT.r * 255)
        let g: Int = Int(rgbaT.g * 255)
        let b: Int = Int(rgbaT.b * 255)
        let red = NSString(format: "%02x", r)
        let green = NSString(format: "%02x", g)
        let blue = NSString(format: "%02x", b)
        return "#\(red)\(green)\(blue)"
    }

    func rgba() -> (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        let components = cgColor.components
        let numberOfComponents = cgColor.numberOfComponents

        switch numberOfComponents {
        case 4:
            return (components![0], components![1], components![2], components![3])
        case 2:
            return (components![0], components![0], components![0], components![1])
        default:
            // FIXME: Fallback to black
            return (0, 0, 0, 1)
        }
    }

    func hsba() -> (h: CGFloat, s: CGFloat, b: CGFloat, a: CGFloat) {
        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        if responds(to: #selector(getHue(_:saturation:brightness:alpha:))) && cgColor.numberOfComponents == 4 {
            self.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        }

        return (h, s, b, a)
    }

    func CIE_LAB() -> (l: CGFloat, a: CGFloat, b: CGFloat, alpha: CGFloat) {
        // Get XYZ
        let xyzT = xyz()
        let x = xyzT.x / 95.047
        let y = xyzT.y / 100.000
        let z = xyzT.z / 108.883

        // Transfrom XYZ to L*a*b
        let deltaF: TransformBlock = { f in
            if f > pow(6.0 / 29.0, 3.0) {
                return pow(f, 1.0 / 3.0)
            }
            return pow(29.0 / 6.0, 2.0) * f / 3.0 + 4 / 29.0
        }
        let X = deltaF(x)
        let Y = deltaF(y)
        let Z = deltaF(z)
        let L = 116 * Y - 16
        let a = 500 * (X - Y)
        let b = 200 * (Y - Z)

        return (L, a, b, xyzT.alpha)
    }

    func xyz() -> (x: CGFloat, y: CGFloat, z: CGFloat, alpha: CGFloat) {
        // Get RGBA values
        let rgbaT = rgba()

        // Transfrom values to XYZ
        let deltaR: TransformBlock = { R in
            (R > 0.04045) ? pow((R + 0.055) / 1.055, 2.40) : (R / 12.92)
        }
        let R = deltaR(rgbaT.r)
        let G = deltaR(rgbaT.g)
        let B = deltaR(rgbaT.b)
        let X = (R * 41.24 + G * 35.76 + B * 18.05)
        let Y = (R * 21.26 + G * 71.52 + B * 7.22)
        let Z = (R * 1.93 + G * 11.92 + B * 95.05)

        return (X, Y, Z, rgbaT.a)
    }

    func cmyk() -> (c: CGFloat, m: CGFloat, y: CGFloat, k: CGFloat) {
        // Convert RGB to CMY
        let rgbaT = rgba()
        let C = 1 - rgbaT.r
        let M = 1 - rgbaT.g
        let Y = 1 - rgbaT.b

        // Find K
        let K = min(1, min(C, min(Y, M)))
        if K == 1 {
            return (0, 0, 0, 1)
        }

        // Convert cmyk
        let newCMYK: TransformBlock = { x in
            (x - K) / (1 - K)
        }
        return (newCMYK(C), newCMYK(M), newCMYK(Y), K)
    }

    // MARK: - Color Components

    func red() -> CGFloat {
        return rgba().r
    }

    func green() -> CGFloat {
        return rgba().g
    }

    func blue() -> CGFloat {
        return rgba().b
    }

    func alpha() -> CGFloat {
        return rgba().a
    }

    func hue() -> CGFloat {
        return hsba().h
    }

    func saturation() -> CGFloat {
        return hsba().s
    }

    func brightness() -> CGFloat {
        return hsba().b
    }

    func CIE_Lightness() -> CGFloat {
        return CIE_LAB().l
    }

    func CIE_a() -> CGFloat {
        return CIE_LAB().a
    }

    func CIE_b() -> CGFloat {
        return CIE_LAB().b
    }

    func cyan() -> CGFloat {
        return cmyk().c
    }

    func magenta() -> CGFloat {
        return cmyk().m
    }

    func yellow() -> CGFloat {
        return cmyk().y
    }

    func keyBlack() -> CGFloat {
        return cmyk().k
    }

    // MARK: - Lighten/Darken Color

    func lightenedColor(_ percentage: CGFloat) -> Color {
        return modifiedColor(percentage + 1.0)
    }

    func darkenedColor(_ percentage: CGFloat) -> Color {
        return modifiedColor(1.0 - percentage)
    }

    fileprivate func modifiedColor(_ percentage: CGFloat) -> Color {
        let hsbaT = hsba()
        return Color(hsba: (hsbaT.h, hsbaT.s, hsbaT.b * percentage, hsbaT.a))
    }

    // MARK: - Contrasting Color

    func blackOrWhiteContrastingColor() -> Color {
        let rgbaT = rgba()
        let value = 1 - ((0.299 * rgbaT.r) + (0.587 * rgbaT.g) + (0.114 * rgbaT.b))
        return value < 0.5 ? Color.black : Color.white
    }

    // MARK: - Complementary Color

    func complementaryColor() -> Color {
        let hsbaT = hsba()
        let newH = Color.addDegree(180.0, staticDegree: hsbaT.h * 360.0)
        return Color(hsba: (newH, hsbaT.s, hsbaT.b, hsbaT.a))
    }

    // MARK: - Color Scheme

    func colorScheme(_ type: ColorScheme) -> [Color] {
        switch type {
        case .analagous:
            return Color.analgousColors(hsba())
        case .monochromatic:
            return Color.monochromaticColors(hsba())
        case .triad:
            return Color.triadColors(hsba())
        default:
            return Color.complementaryColors(hsba())
        }
    }

    fileprivate class func analgousColors(_ hsbaT: (h: CGFloat, s: CGFloat, b: CGFloat, a: CGFloat)) -> [Color] {
        return [Color(hsba: (self.addDegree(30, staticDegree: hsbaT.h * 360) / 360.0, hsbaT.s - 0.05, hsbaT.b - 0.1, hsbaT.a)),
                Color(hsba: (self.addDegree(15, staticDegree: hsbaT.h * 360) / 360.0, hsbaT.s - 0.05, hsbaT.b - 0.05, hsbaT.a)),
                Color(hsba: (self.addDegree(-15, staticDegree: hsbaT.h * 360) / 360.0, hsbaT.s - 0.05, hsbaT.b - 0.05, hsbaT.a)),
                Color(hsba: (self.addDegree(-30, staticDegree: hsbaT.h * 360) / 360.0, hsbaT.s - 0.05, hsbaT.b - 0.1, hsbaT.a))]
    }

    fileprivate class func monochromaticColors(_ hsbaT: (h: CGFloat, s: CGFloat, b: CGFloat, a: CGFloat)) -> [Color] {
        return [Color(hsba: (hsbaT.h, hsbaT.s / 2, hsbaT.b / 3, hsbaT.a)),
                Color(hsba: (hsbaT.h, hsbaT.s, hsbaT.b / 2, hsbaT.a)),
                Color(hsba: (hsbaT.h, hsbaT.s / 3, 2 * hsbaT.b / 3, hsbaT.a)),
                Color(hsba: (hsbaT.h, hsbaT.s, 4 * hsbaT.b / 5, hsbaT.a))]
    }

    fileprivate class func triadColors(_ hsbaT: (h: CGFloat, s: CGFloat, b: CGFloat, a: CGFloat)) -> [Color] {
        return [Color(hsba: (self.addDegree(120, staticDegree: hsbaT.h * 360) / 360.0, 2 * hsbaT.s / 3, hsbaT.b - 0.05, hsbaT.a)),
                Color(hsba: (self.addDegree(120, staticDegree: hsbaT.h * 360) / 360.0, hsbaT.s, hsbaT.b, hsbaT.a)),
                Color(hsba: (self.addDegree(240, staticDegree: hsbaT.h * 360) / 360.0, hsbaT.s, hsbaT.b, hsbaT.a)),
                Color(hsba: (self.addDegree(240, staticDegree: hsbaT.h * 360) / 360.0, 2 * hsbaT.s / 3, hsbaT.b - 0.05, hsbaT.a))]
    }

    fileprivate class func complementaryColors(_ hsbaT: (h: CGFloat, s: CGFloat, b: CGFloat, a: CGFloat)) -> [Color] {
        return [Color(hsba: (hsbaT.h, hsbaT.s, 4 * hsbaT.b / 5, hsbaT.a)),
                Color(hsba: (hsbaT.h, 5 * hsbaT.s / 7, hsbaT.b, hsbaT.a)),
                Color(hsba: (self.addDegree(180, staticDegree: hsbaT.h * 360) / 360.0, hsbaT.s, hsbaT.b, hsbaT.a)),
                Color(hsba: (self.addDegree(180, staticDegree: hsbaT.h * 360) / 360.0, 5 * hsbaT.s / 7, hsbaT.b, hsbaT.a))]
    }

    // MARK: - Predefined Colors

    // MARK: -

    // MARK: System Colors

    var infoBlue: Color {
        return Color(r: 47, g: 112, b: 225, a: 1.0)
    }

    var success: Color {
        return Color(r: 83, g: 215, b: 106, a: 1.0)
    }

    var warningColor: Color {
        return Color(r: 221, g: 170, b: 59, a: 1.0)
    }

    var danger: Color {
        return Color(r: 229, g: 0, b: 15, a: 1.0)
    }

    // MARK: Whites

    var antiqueWhite: Color {
        return Color(r: 250, g: 235, b: 215, a: 1.0)
    }

    var oldLace: Color {
        return Color(r: 253, g: 245, b: 230, a: 1.0)
    }

    var ivory: Color {
        return Color(r: 255, g: 255, b: 240, a: 1.0)
    }

    var seashell: Color {
        return Color(r: 255, g: 245, b: 238, a: 1.0)
    }

    var ghostWhite: Color {
        return Color(r: 248, g: 248, b: 255, a: 1.0)
    }

    var snow: Color {
        return Color(r: 255, g: 250, b: 250, a: 1.0)
    }

    var linen: Color {
        return Color(r: 250, g: 240, b: 230, a: 1.0)
    }

    // MARK: Grays

    var black25Percent: Color {
        return Color(white: 0.25, alpha: 1.0)
    }

    var black50Percent: Color {
        return Color(white: 0.5, alpha: 1.0)
    }

    var black75Percent: Color {
        return Color(white: 0.75, alpha: 1.0)
    }

    var warmGray: Color {
        return Color(r: 133, g: 117, b: 112, a: 1.0)
    }

    var coolGray: Color {
        return Color(r: 118, g: 122, b: 133, a: 1.0)
    }

    var charcoal: Color {
        return Color(r: 34, g: 34, b: 34, a: 1.0)
    }

    // MARK: Blues

    var teal: Color {
        return Color(r: 28, g: 160, b: 170, a: 1.0)
    }

    var steelBlue: Color {
        return Color(r: 103, g: 153, b: 170, a: 1.0)
    }

    var robinEgg: Color {
        return Color(r: 141, g: 218, b: 247, a: 1.0)
    }

    var pastelBlue: Color {
        return Color(r: 99, g: 161, b: 247, a: 1.0)
    }

    var turquoise: Color {
        return Color(r: 112, g: 219, b: 219, a: 1.0)
    }

    var skyBlue: Color {
        return Color(r: 0, g: 178, b: 238, a: 1.0)
    }

    var indigo: Color {
        return Color(r: 13, g: 79, b: 139, a: 1.0)
    }

    var denim: Color {
        return Color(r: 67, g: 114, b: 170, a: 1.0)
    }

    var blueberry: Color {
        return Color(r: 89, g: 113, b: 173, a: 1.0)
    }

    var cornflower: Color {
        return Color(r: 100, g: 149, b: 237, a: 1.0)
    }

    var babyBlue: Color {
        return Color(r: 190, g: 220, b: 230, a: 1.0)
    }

    var midnightBlue: Color {
        return Color(r: 13, g: 26, b: 35, a: 1.0)
    }

    var fadedBlue: Color {
        return Color(r: 23, g: 137, b: 155, a: 1.0)
    }

    var iceberg: Color {
        return Color(r: 200, g: 213, b: 219, a: 1.0)
    }

    var wave: Color {
        return Color(r: 102, g: 169, b: 251, a: 1.0)
    }

    // MARK: Greens

    var emerald: Color {
        return Color(r: 1, g: 152, b: 117, a: 1.0)
    }

    var grass: Color {
        return Color(r: 99, g: 214, b: 74, a: 1.0)
    }

    var pastelGreen: Color {
        return Color(r: 126, g: 242, b: 124, a: 1.0)
    }

    var seafoam: Color {
        return Color(r: 77, g: 226, b: 140, a: 1.0)
    }

    var paleGreen: Color {
        return Color(r: 176, g: 226, b: 172, a: 1.0)
    }

    var cactusGreen: Color {
        return Color(r: 99, g: 111, b: 87, a: 1.0)
    }

    var chartreuse: Color {
        return Color(r: 69, g: 139, b: 0, a: 1.0)
    }

    var hollyGreen: Color {
        return Color(r: 32, g: 87, b: 14, a: 1.0)
    }

    var olive: Color {
        return Color(r: 91, g: 114, b: 34, a: 1.0)
    }

    var oliveDrab: Color {
        return Color(r: 107, g: 142, b: 35, a: 1.0)
    }

    var moneyGreen: Color {
        return Color(r: 134, g: 198, b: 124, a: 1.0)
    }

    var honeydew: Color {
        return Color(r: 216, g: 255, b: 231, a: 1.0)
    }

    var lime: Color {
        return Color(r: 56, g: 237, b: 56, a: 1.0)
    }

    var cardTable: Color {
        return Color(r: 87, g: 121, b: 107, a: 1.0)
    }

    // MARK: Reds

    var salmon: Color {
        return Color(r: 233, g: 87, b: 95, a: 1.0)
    }

    var brickRed: Color {
        return Color(r: 151, g: 27, b: 16, a: 1.0)
    }

    var easterPink: Color {
        return Color(r: 241, g: 167, b: 162, a: 1.0)
    }

    var grapefruit: Color {
        return Color(r: 228, g: 31, b: 54, a: 1.0)
    }

    var pink: Color {
        return Color(r: 255, g: 95, b: 154, a: 1.0)
    }

    var indianRed: Color {
        return Color(r: 205, g: 92, b: 92, a: 1.0)
    }

    var strawberry: Color {
        return Color(r: 190, g: 38, b: 37, a: 1.0)
    }

    var coral: Color {
        return Color(r: 240, g: 128, b: 128, a: 1.0)
    }

    var maroon: Color {
        return Color(r: 80, g: 4, b: 28, a: 1.0)
    }

    var watermelon: Color {
        return Color(r: 242, g: 71, b: 63, a: 1.0)
    }

    var tomato: Color {
        return Color(r: 255, g: 99, b: 71, a: 1.0)
    }

    var pinkLipstick: Color {
        return Color(r: 255, g: 105, b: 180, a: 1.0)
    }

    var paleRose: Color {
        return Color(r: 255, g: 228, b: 225, a: 1.0)
    }

    var crimson: Color {
        return Color(r: 187, g: 18, b: 36, a: 1.0)
    }

    // MARK: Purples

    var eggplant: Color {
        return Color(r: 105, g: 5, b: 98, a: 1.0)
    }

    var pastelPurple: Color {
        return Color(r: 207, g: 100, b: 235, a: 1.0)
    }

    var palePurple: Color {
        return Color(r: 229, g: 180, b: 235, a: 1.0)
    }

    var coolPurple: Color {
        return Color(r: 140, g: 93, b: 228, a: 1.0)
    }

    var violet: Color {
        return Color(r: 191, g: 95, b: 255, a: 1.0)
    }

    var plum: Color {
        return Color(r: 139, g: 102, b: 139, a: 1.0)
    }

    var lavender: Color {
        return Color(r: 204, g: 153, b: 204, a: 1.0)
    }

    var raspberry: Color {
        return Color(r: 135, g: 38, b: 87, a: 1.0)
    }

    var fuschia: Color {
        return Color(r: 255, g: 20, b: 147, a: 1.0)
    }

    var grape: Color {
        return Color(r: 54, g: 11, b: 88, a: 1.0)
    }

    var periwinkle: Color {
        return Color(r: 135, g: 159, b: 237, a: 1.0)
    }

    var orchid: Color {
        return Color(r: 218, g: 112, b: 214, a: 1.0)
    }

    // MARK: Yellows

    var goldenrod: Color {
        return Color(r: 215, g: 170, b: 51, a: 1.0)
    }

    var yellowGreen: Color {
        return Color(r: 192, g: 242, b: 39, a: 1.0)
    }

    var banana: Color {
        return Color(r: 229, g: 227, b: 58, a: 1.0)
    }

    var mustard: Color {
        return Color(r: 205, g: 171, b: 45, a: 1.0)
    }

    var buttermilk: Color {
        return Color(r: 254, g: 241, b: 181, a: 1.0)
    }

    var gold: Color {
        return Color(r: 139, g: 117, b: 18, a: 1.0)
    }

    var cream: Color {
        return Color(r: 240, g: 226, b: 187, a: 1.0)
    }

    var lightCream: Color {
        return Color(r: 240, g: 238, b: 215, a: 1.0)
    }

    var wheat: Color {
        return Color(r: 240, g: 238, b: 215, a: 1.0)
    }

    var beige: Color {
        return Color(r: 245, g: 245, b: 220, a: 1.0)
    }

    // MARK: Oranges

    var peach: Color {
        return Color(r: 242, g: 187, b: 97, a: 1.0)
    }

    var burntOrange: Color {
        return Color(r: 184, g: 102, b: 37, a: 1.0)
    }

    var pastelOrange: Color {
        return Color(r: 248, g: 197, b: 143, a: 1.0)
    }

    var cantaloupe: Color {
        return Color(r: 250, g: 154, b: 79, a: 1.0)
    }

    var carrot: Color {
        return Color(r: 237, g: 145, b: 33, a: 1.0)
    }

    var mandarin: Color {
        return Color(r: 247, g: 145, b: 55, a: 1.0)
    }

    // MARK: Browns

    var chiliPowder: Color {
        return Color(r: 199, g: 63, b: 23, a: 1.0)
    }

    var burntSienna: Color {
        return Color(r: 138, g: 54, b: 15, a: 1.0)
    }

    var chocolate: Color {
        return Color(r: 94, g: 38, b: 5, a: 1.0)
    }

    var coffee: Color {
        return Color(r: 141, g: 60, b: 15, a: 1.0)
    }

    var cinnamon: Color {
        return Color(r: 123, g: 63, b: 9, a: 1.0)
    }

    var almond: Color {
        return Color(r: 196, g: 142, b: 72, a: 1.0)
    }

    var eggshell: Color {
        return Color(r: 252, g: 230, b: 201, a: 1.0)
    }

    var sand: Color {
        return Color(r: 222, g: 182, b: 151, a: 1.0)
    }

    var mud: Color {
        return Color(r: 70, g: 45, b: 29, a: 1.0)
    }

    var sienna: Color {
        return Color(r: 160, g: 82, b: 45, a: 1.0)
    }

    var dust: Color {
        return Color(r: 236, g: 214, b: 197, a: 1.0)
    }

    // MARK: - Private Helpers

    fileprivate class func addDegree(_ addDegree: CGFloat, staticDegree: CGFloat) -> CGFloat {
        let s = staticDegree + addDegree
        if s > 360 {
            return s - 360
        } else if s < 0 {
            return -1 * s
        } else {
            return s
        }
    }
}
