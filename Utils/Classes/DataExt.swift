//
//  DataExt.swift
//  ValoKit
//
//  Created by Valo on 2016/12/1.
//
//

#if os(iOS) || os(tvOS)

    import Foundation

    extension Data {
        func toString() -> String {
            let s = String(data: self, encoding: .utf8)
            return s == nil ? "" : s!
        }

        func toDate() -> Date? {
            let s = String(data: self, encoding: .utf8)
            var d = s?.toDate()
            if d == nil {
                d = s?.toDateTime()
            }
            return d
        }

        func toColor() -> UIColor {
            let s = String(data: self, encoding: .utf8)
            return UIColor(hex: s == nil ? "" : s!)
        }

        func toImage() -> UIImage? {
            return UIImage(data: self)
        }
    }

    /// 与Data的转换
    extension AnyExt {
        /// 对象类型
        enum `Type`: String {
            case data = "a"
            case bool = "b"
            case number = "n"
            case string = "s"
            case color = "c"
            case date = "d"
            case image = "i"
            case unknown = "u"
        }

        /// 获取对象的类型
        var type: Type {
            switch object {
            case _ as Data:
                return .data
            case _ as Bool:
                return .bool
            case _ as NSNumber:
                return .number
            case _ as String:
                return .string
            case _ as UIColor:
                return .color
            case _ as UIImage:
                return .image
            case _ as Date:
                return .date
            default:
                return .unknown
            }
        }

        /// 将对象转换为Data
        var data: Data {
            var data: Data?
            switch object {
            case let a as Data:
                data = a
            case let b as Bool:
                data = b.description.data(using: .utf8)
            case let n as NSNumber:
                data = n.stringValue.data(using: .utf8)
            case let s as String:
                data = s.data(using: .utf8)
            case let c as UIColor:
                data = c.hexString().data(using: .utf8)
            case let i as UIImage:
                data = i.pngData()
                if data == nil {
                    data = i.jpegData(compressionQuality: 1.0)
                }
            case let d as Date:
                data = d.toString().data(using: .utf8)
            default: break
            }
            if data == nil {
                data = Data()
            }
            return data!
        }
    }
#endif
