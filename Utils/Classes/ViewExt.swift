//
//  UIViewExt.swift
//  ValoKit
//
//  Created by Valo on 2016/12/2.
//
//

import Foundation
#if os(iOS) || os(tvOS)
    public extension UIView {
        func trim(corner radius: Float = 0.0, border width: Float = 0.0, _ color: UIColor = UIColor.clear) {
            layer.masksToBounds = true
            if radius > 0 {
                layer.cornerRadius = CGFloat(radius)
            }
            if width > 0 {
                layer.borderWidth = CGFloat(width)
                layer.borderColor = color.cgColor
            }
        }

        class func trim(views: Array<UIView>, corner radius: Float = 0.0, border width: Float = 0.0, _ color: UIColor = UIColor.clear) {
            for view in views {
                view.trim(corner: radius, border: width, color)
            }
        }

        func capture(with color: UIColor = UIColor.clear, size: CGSize) -> UIImage? {
            let rect: CGRect = CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height)
            UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
            let context = UIGraphicsGetCurrentContext()
            context?.setFillColor(color.cgColor)
            context?.fill(rect)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return image
        }
    }

    public extension UIView {
        // MARK: - Basic Properties

        /// X Axis value of UIView.
        var x: CGFloat {
            set { frame = CGRect(x: _pixelIntegral(newValue), y: y, width: width, height: height) }
            get { return frame.origin.x }
        }

        /// Y Axis value of UIView.
        var y: CGFloat {
            set { frame = CGRect(x: x, y: _pixelIntegral(newValue), width: width, height: height) }
            get { return frame.origin.y }
        }

        /// Width of view.
        var width: CGFloat {
            set { frame = CGRect(x: x, y: y, width: _pixelIntegral(newValue), height: height) }
            get { return frame.size.width }
        }

        /// Height of view.
        var height: CGFloat {
            set { frame = CGRect(x: x, y: y, width: width, height: _pixelIntegral(newValue)) }
            get { return frame.size.height }
        }

        // MARK: - Origin and Size

        /// View's origin point.
        var origin: CGPoint {
            set { frame = CGRect(x: _pixelIntegral(newValue.x), y: _pixelIntegral(newValue.y), width: width, height: height) }
            get { return frame.origin }
        }

        /// View's size.
        var size: CGSize {
            set { frame = CGRect(x: x, y: y, width: _pixelIntegral(newValue.width), height: _pixelIntegral(newValue.height)) }
            get { return frame.size }
        }

        // MARK: - Extra Properties

        /// View's right side (x + width).
        var right: CGFloat {
            set { x = newValue - width }
            get { return x + width }
        }

        /// View's bottom (y + height).
        var bottom: CGFloat {
            set { y = newValue - height }
            get { return y + height }
        }

        /// View's top (y).
        var top: CGFloat {
            set { y = newValue }
            get { return y }
        }

        /// View's left side (x).
        var left: CGFloat {
            set { x = newValue }
            get { return x }
        }

        /// View's center X value (center.x).
        var centerX: CGFloat {
            set { center = CGPoint(x: newValue, y: centerY) }
            get { return center.x }
        }

        /// View's center Y value (center.y).
        var centerY: CGFloat {
            set { center = CGPoint(x: centerX, y: newValue) }
            get { return center.y }
        }

        /// Last subview on X Axis.
        var lastSubviewOnX: UIView? {
            var outView: UIView = subviews[0] as UIView

            for v in subviews as [UIView] {
                if v.x > outView.x { outView = v }
            }

            return outView
        }

        /// Last subview on Y Axis.
        var lastSubviewOnY: UIView? {
            var outView: UIView = subviews[0] as UIView

            for v in subviews as [UIView] {
                if v.y > outView.y { outView = v }
            }

            return outView
        }

        // MARK: - Bounds Methods

        /// X value of bounds (bounds.origin.x).
        var boundsX: CGFloat {
            set { bounds = CGRect(x: _pixelIntegral(newValue), y: boundsY, width: boundsWidth, height: boundsHeight) }
            get { return bounds.origin.x }
        }

        /// Y value of bounds (bounds.origin.y).
        var boundsY: CGFloat {
            set { frame = CGRect(x: boundsX, y: _pixelIntegral(newValue), width: boundsWidth, height: boundsHeight) }
            get { return bounds.origin.y }
        }

        /// Width of bounds (bounds.size.width).
        var boundsWidth: CGFloat {
            set { frame = CGRect(x: boundsX, y: boundsY, width: _pixelIntegral(newValue), height: boundsHeight) }
            get { return bounds.size.width }
        }

        /// Height of bounds (bounds.size.height).
        var boundsHeight: CGFloat {
            set { frame = CGRect(x: boundsX, y: boundsY, width: boundsWidth, height: _pixelIntegral(newValue)) }
            get { return bounds.size.height }
        }

        // MARK: - Useful Methods

        /// Center view to it's parent view.
        func centerToParent() {
            if superview != nil {
                switch UIApplication.shared.statusBarOrientation {
                case .landscapeLeft:
                    fallthrough
                case .landscapeRight:
                    origin = CGPoint(x: (superview!.height / 2) - (width / 2),
                                     y: (superview!.width / 2) - (height / 2))
                case .portrait:
                    fallthrough
                case .portraitUpsideDown:
                    origin = CGPoint(x: (superview!.width / 2) - (width / 2),
                                     y: (superview!.height / 2) - (height / 2))
                case .unknown: break
                @unknown default:
                    fatalError()
                }
            }
        }

        // MARK: - view searching

        func firstMatch(where: (UIView) -> Bool) -> UIView? {
            if `where`(self) {
                return self
            }
            for sub in subviews {
                let match = sub.firstMatch(where: `where`)
                if match != nil { return match }
            }
            return nil
        }

        func firstSubview(of viewClass: AnyClass) -> UIView? {
            return firstMatch(where: { $0.isKind(of: viewClass) })
        }

        func firstSubview(of viewClass: AnyClass, tag: Int) -> UIView? {
            return firstMatch(where: { $0.tag == tag && $0.isKind(of: viewClass) })
        }

        func matching(where: (UIView) -> Bool) -> [UIView] {
            var views = [UIView]()
            if `where`(self) {
                views.append(self)
            }
            for sub in subviews {
                views.append(contentsOf: sub.matching(where: `where`))
            }
            return views
        }

        func views(with tag: Int) -> [UIView] {
            return matching(where: { $0.tag == tag })
        }

        func views(of viewClass: AnyClass) -> [UIView] {
            return matching(where: { $0.isKind(of: viewClass) })
        }

        func views(of viewClass: AnyClass, tag: Int) -> [UIView] {
            return matching(where: { $0.tag == tag && $0.isKind(of: viewClass) })
        }

        func viewOrAnySuperviewMatch(where: (UIView) -> Bool) -> UIView? {
            if `where`(self) {
                return self
            }
            if superview == nil { return nil }
            return superview!.viewOrAnySuperviewMatch(where: `where`)
        }

        func firstSuperview(with tag: Int) -> UIView? {
            return viewOrAnySuperviewMatch(where: { $0.tag == tag })
        }

        func firstSuperview(of viewClass: AnyClass) -> UIView? {
            return viewOrAnySuperviewMatch(where: { $0.isKind(of: viewClass) })
        }

        func firstSuperview(of viewClass: AnyClass, tag: Int) -> UIView? {
            return viewOrAnySuperviewMatch(where: { $0.tag == tag && $0.isKind(of: viewClass) })
        }

        func isSuperview(of view: UIView) -> Bool {
            var sup = view.superview
            while sup != nil && sup != self {
                sup = sup?.superview
            }
            return sup != nil
        }

        func isSubview(of view: UIView) -> Bool {
            return view.isSuperview(of: self)
        }

        // MARK: responder chain

        func firstViewController() -> UIViewController? {
            var responder: UIResponder? = self
            while responder != nil && !responder!.isKind(of: UIViewController.self) {
                responder = responder!.next
            }
            return responder as? UIViewController
        }

        func firstResponder() -> UIView? {
            return firstMatch(where: { $0.isFirstResponder })
        }

        // MARK: - Private Methods

        private func _pixelIntegral(_ pointValue: CGFloat) -> CGFloat {
            let scale = UIScreen.main.scale
            return (round(pointValue * scale) / scale)
        }
    }
#endif
