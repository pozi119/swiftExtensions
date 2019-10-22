//
//  Constants.swift
//  ValoKit
//
//  Created by Valo on 2016/12/2.
//
//

import Foundation

#if os(iOS) || os(tvOS)
    struct Constants {
        struct `default` {
            static let cornerRadius = 3.0
            static let borderColor = UIColor(white: 0.784, alpha: 1.0)
            static let borderWidth = 1.0 / UIScreen.main.scale
        }

        static let screenBounds = UIScreen.main.bounds
        static let screenSize = UIScreen.main.bounds.size
        static let fontScale = screenSize.width > 320 ? screenSize.width / 320.0 : 1.0
    }
#endif
