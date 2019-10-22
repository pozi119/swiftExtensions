//
//  AnyExt.swift
//  ValoKit
//
//  Created by Valo on 2016/12/1.
//
//

import Foundation

/// Any类型的扩展
/// 在DataExt中添加了Data与UIColor,Date,UIImage的互转
public struct AnyExt {
    public var object: Any
    public init(_ object: Any) {
        self.object = object
    }

    public static func set(parameters: [String: Any]?, for object: AnyObject) {
        if parameters == nil {
            return
        }
        for (key, value) in parameters! {
            let sel = Selector(key)
            if object.responds(to: sel) {
                object.setValue(value, forKey: key)
            }
        }
    }
}

/// 根据类名,命名空间和.framework所在目录生成swift类,
/// - workspace中的framework项目,必须添加至 App Target->General->Embeded Binaries中
/// - 在framework项目中使用cocoapods导入了第三方库, App Target的Podfile也必须添加相同的第三方库
/// - 指定了framework文件但未指定命名空间, 命名空间默认为framework文件名,framework文件为NSHomeDirectory()下的相对路径.
/// - 未指定framework文件且未指定命名空间, 命名空间默认为当前项目Target名
/// - 未指定framework文件但指定了命名空间, 将在Bundle.main下的Frameworks文件夹中查找 命名空间.framework 文件
/// - parameter className: 类名,格式为 [framework文件/[命名空间.]]类名,
/// - returns: 类
public func swiftClass(from className: String) throws -> AnyClass {
    var fwk = "", ns = "", name = "", nsn = ""
    let arr1 = className.components(separatedBy: ".framework/")
    if arr1.count == 2 {
        fwk = arr1[0] + ".framework"
        nsn = arr1[1]
    } else {
        nsn = arr1[0]
    }
    let arr2 = nsn.components(separatedBy: ".")
    if arr2.count == 2 {
        ns = arr2[0]
        name = arr2[1]
    } else {
        name = arr2[0]
    }
    if fwk.count > 0 && ns.count == 0 {
        ns = NSString(string: NSString(string: fwk).lastPathComponent).deletingPathExtension
    }
    if ns.count == 0 {
        var appns: String? = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as! String?
        if appns != nil {
            appns = appns?.replacingOccurrences(of: ".", with: "_", options: NSString.CompareOptions.literal, range: nil)
            ns = appns!
        }
    }

    let clsname = ns.count == 0 ? name : "\(ns).\(name)"
    var cls: AnyClass? = NSClassFromString(clsname)
    if cls == nil {
        var path = ""
        if fwk.count > 0 {
            path = NSHomeDirectory() + "/" + fwk
        } else {
            path = Bundle.main.path(forResource: ns, ofType: "framework", inDirectory: "Frameworks") ?? ""
        }
        if path.count > 0 {
            let nspath = path + "/" + ns
            let handle = dlopen(nspath, RTLD_NOW)
            guard handle != nil else {
                throw NSError(domain: "com.valokit.anyext", code: -1, userInfo: ["code": -1, "message": String(cString: dlerror())])
            }
            cls = NSClassFromString(clsname)
            dlclose(handle)
        }
    }
    guard cls != nil else {
        throw NSError(domain: "com.valokit.anyext", code: -2, userInfo: ["code": -2, "message": "class not found,please check className and namespace"])
    }
    return cls!
}
