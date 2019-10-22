//
//  Constants.swift
//  ValoKit
//
//  Created by Valo on 2016/12/2.
//
//

import Foundation

#if os(iOS) || os(tvOS)
    public struct Constants {
        public struct `default` {
            public static let cornerRadius = 3.0
            public static let borderColor = UIColor(white: 0.784, alpha: 1.0)
            public static let borderWidth = 1.0 / UIScreen.main.scale
        }

        public static let screenBounds = UIScreen.main.bounds
        public static let screenSize = UIScreen.main.bounds.size
        public static let fontScale = screenSize.width > 320 ? screenSize.width / 320.0 : 1.0
    }
#endif
