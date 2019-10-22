//
//  StringExt.swift
//  ValoKit
//
//  Created by Valo on 21/11/2016.
//  Copyright © 2016 Valo. All rights reserved.
//

public extension String {
    func between(left: String, _ right: String) -> String? {
        guard let leftRange = range(of: left),
            let rightRange = range(of: right, options: .backwards),
            leftRange.upperBound < rightRange.lowerBound else { return nil }
        return String(self[leftRange.upperBound ..< rightRange.lowerBound])
    }

    func camelize() -> String {
        let source = clean(with: " ", allOf: "-", "_")
        if source.contains(" ") {
            let first = source[startIndex ..< index(source.startIndex, offsetBy: 1)]
            let cammel = source.capitalized.replacingOccurrences(of: " ", with: "", options: [], range: nil)
            let rest = String(cammel.dropFirst())
            return "\(first)\(rest)"
        } else {
            let first = source.lowercased()[startIndex ..< index(source.startIndex, offsetBy: 1)]
            let rest = String(source.dropFirst())
            return "\(first)\(rest)"
        }
    }

    func left(of string: String) -> String {
        if let range = range(of: string) {
            if range.upperBound <= endIndex {
                return String(self[startIndex ..< range.lowerBound])
            }
        }
        return ""
    }

    func right(of string: String) -> String {
        if let range = range(of: string, options: .backwards) {
            if range.upperBound <= endIndex {
                return String(self[range.upperBound ..< endIndex])
            }
        }
        return ""
    }

    func chompLeft(_ prefix: String) -> String {
        if let prefixRange = range(of: prefix) {
            if prefixRange.upperBound >= endIndex {
                return String(self[startIndex ..< prefixRange.lowerBound])
            } else {
                return String(self[prefixRange.upperBound ..< endIndex])
            }
        }
        return self
    }

    func chompRight(_ suffix: String) -> String {
        if let suffixRange = range(of: suffix, options: .backwards) {
            if suffixRange.upperBound >= endIndex {
                return String(self[startIndex ..< suffixRange.lowerBound])
            } else {
                return String(self[suffixRange.upperBound ..< endIndex])
            }
        }
        return self
    }

    func collapseWhitespace() -> String {
        let components = self.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        return components.joined(separator: " ")
    }

    func clean(with: String, allOf: String...) -> String {
        var string = self
        for target in allOf {
            string = string.replacingOccurrences(of: target, with: with)
        }
        return string
    }

    func count(_ substring: String) -> Int {
        return components(separatedBy: substring).count - 1
    }

    func ensureLeft(prefix: String) -> String {
        if hasPrefix(prefix) {
            return self
        } else {
            return "\(prefix)\(self)"
        }
    }

    func ensureRight(suffix: String) -> String {
        if hasSuffix(suffix) {
            return self
        } else {
            return "\(self)\(suffix)"
        }
    }

    func indexOf(_ substring: String) -> Int? {
        if let range = range(of: substring) {
            return distance(from: startIndex, to: range.lowerBound)
        }
        return nil
    }

    func initials() -> String {
        let words = components(separatedBy: " ")
        return words.reduce("", { (result, current) -> String in
            result + current[startIndex ..< index(after: current.startIndex)]
        })
    }

    func initialsFirstAndLast() -> String {
        let words = components(separatedBy: " ")
        return words.reduce("", { (result, current) -> String in
            let s = String(current[startIndex ..< index(after: current.startIndex)])
            if result == "" {
                return s
            }
            if current == words.last {
                return result + s
            }
            return result
        })
    }

    func isAlpha() -> Bool {
        for chr in self {
            if !(chr >= "a" && chr <= "z") && !(chr >= "A" && chr <= "Z") {
                return false
            }
        }
        return true
    }

    func isAlphaNumeric() -> Bool {
        let alphaNumeric = CharacterSet.alphanumerics
        return components(separatedBy: alphaNumeric).joined(separator: "").length == 0
    }

    func isEmpty() -> Bool {
        return trimmingCharacters(in: .whitespacesAndNewlines).length == 0
    }

    func isNumeric() -> Bool {
        if let _ = defaultNumberFormatter().number(from: self) {
            return true
        }
        return false
    }

    func join<S: Sequence>(_ elements: S) -> String {
        return elements.map { "\($0)" }.joined(separator: self)
    }

    func latinize() -> String {
        return folding(options: .diacriticInsensitive, locale: Locale.current)
    }

    func lines() -> [String] {
        return components(separatedBy: .newlines)
    }

    var length: Int {
        return count
    }

    func pad(_ n: Int, _ string: String = " ") -> String {
        return "".join([string.times(n), self, string.times(n)])
    }

    func padLeft(_ n: Int, _ string: String = " ") -> String {
        return "".join([string.times(n), self])
    }

    func padRight(_ n: Int, _ string: String = " ") -> String {
        return "".join([self, string.times(n)])
    }

    func slugify(withSeparator separator: Character = "-") -> String {
        let slugSet = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789\(separator)")
        return latinize().lowercased()
            .components(separatedBy: slugSet.inverted)
            .filter { $0 != "" }
            .joined(separator: "\(separator)")
    }

//    func split(_ separator: Character) -> [String] {
//        return characters.split { $0 == separator }.map(String.init)
//    }

    func stripPunctuation() -> String {
        return components(separatedBy: .punctuationCharacters)
            .joined(separator: "")
            .components(separatedBy: " ")
            .filter { $0 != "" }
            .joined(separator: " ")
    }

    func times(_ n: Int) -> String {
        return Array(repeating: self, count: n).joined(separator: "")
    }

    func toFloat() -> Float? {
        if let number = defaultNumberFormatter().number(from: self) {
            return number.floatValue
        }
        return nil
    }

    func toInt() -> Int? {
        if let number = defaultNumberFormatter().number(from: self) {
            return number.intValue
        }
        return nil
    }

    func toDouble(_ locale: Locale = Locale.current) -> Double? {
        let nf = localeNumberFormatter(locale)

        if let number = nf.number(from: self) {
            return number.doubleValue
        }
        return nil
    }

    func toBool() -> Bool? {
        let trimmed = self.trimmed().lowercased()
        if trimmed == "true" || trimmed == "false" {
            return (trimmed as NSString).boolValue
        }
        return nil
    }

    func toDate(_ format: String = "yyyy-MM-dd") -> Date? {
        return dateFormatter(format).date(from: self)
    }

    func toDateTime(_ format: String = "yyyy-MM-dd HH:mm:ss") -> Date? {
        return toDate(format)
    }

    func trimmedLeft() -> String {
        if let range = rangeOfCharacter(from: CharacterSet.whitespacesAndNewlines.inverted) {
            return String(self[range.lowerBound ..< endIndex])
        }
        return self
    }

    func trimmedRight() -> String {
        if let range = rangeOfCharacter(from: CharacterSet.whitespacesAndNewlines.inverted, options: .backwards) {
            return String(self[startIndex ..< range.upperBound])
        }
        return self
    }

    func trimmed() -> String {
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }

    subscript(r: Range<Int>) -> String {
        let startIndex = index(self.startIndex, offsetBy: r.lowerBound)
        let endIndex = index(self.startIndex, offsetBy: r.upperBound - r.lowerBound)
        return String(self[startIndex ..< endIndex])
    }

    func substring(_ startIndex: Int, length: Int) -> String {
        let start = index(self.startIndex, offsetBy: startIndex)
        let end = index(self.startIndex, offsetBy: startIndex + length)
        return String(self[start ..< end])
    }

    subscript(i: Int) -> Character {
        let index = self.index(startIndex, offsetBy: i)
        return self[index]
    }

//    func containsEmoji() -> Bool {
//        return isMatch("[\\ud83c\\udc00-\\ud83c\\udfff]|[\\ud83d\\udc00-\\ud83d\\udfff]|[\\u2600-\\u27ff]".toRx())
//    }

    func subrange(_ startIndex: Int, length: Int) -> Range<String.Index> {
        let start = index(self.startIndex, offsetBy: startIndex)
        let end = index(self.startIndex, offsetBy: startIndex + length)
        return start ..< end
    }

    func checkingResults() -> [NSTextCheckingResult] {
        do {
            let detector = try NSDataDetector(types: NSTextCheckingAllTypes)
            return detector.matches(in: self, options: .reportCompletion, range: NSMakeRange(0, length))
        } catch {}
        return []
    }

    func checkingTypes() -> [NSTextCheckingResult.CheckingType] {
        let results = checkingResults()
        let selfRange = NSMakeRange(0, length)
        var types: Array<NSTextCheckingResult.CheckingType> = []
        for result in results {
            if NSEqualRanges(result.range, selfRange) {
                types.append(result.resultType)
            }
        }
        return types
    }

    func escapeUnicode() -> String {
        var escaped = self
        escaped = escaped.replacingOccurrences(of: "\\U", with: "\\u", options: [], range: nil)
        let transform: CFString = "Any-Hex/Java" as CFString
        let mutable = NSMutableString(string: escaped) as CFMutableString
        CFStringTransform(mutable, nil, transform, true)
        return mutable as String
    }

    func subEmojiString(with range: Range<String.Index>) -> String {
        let r = rangeOfComposedCharacterSequences(for: range)
        return String(self[r])
    }

    func subEmojiString(from index: Int) -> String {
        let r = subrange(index, length: length - index)
        return subEmojiString(with: r)
    }

    func subEmojiString(to index: Int) -> String {
        let r = subrange(index, length: length - index)
        return subEmojiString(with: r)
    }
}

public extension Character {
    func toInt() -> Int {
        var intFromCharacter: Int = 0
        for scalar in String(self).unicodeScalars {
            intFromCharacter = Int(scalar.value)
        }
        return intFromCharacter
    }
}

public extension Date {
    func toString(_ format: String = "yyyy-MM-dd HH:mm:ss") -> String {
        return dateFormatter(format).string(from: self)
    }
}

private enum ThreadLocalIdentifier {
    case dateFormatter(String)

    case defaultNumberFormatter
    case localeNumberFormatter(Locale)

    var objcDictKey: String {
        switch self {
        case let .dateFormatter(format):
            return "SS\(self)\(format)"
        case let .localeNumberFormatter(l):
            return "SS\(self)\(l.identifier)"
        default:
            return "SS\(self)"
        }
    }
}

private func threadLocalInstance<T: AnyObject>(_ identifier: ThreadLocalIdentifier, initialValue: @autoclosure () -> T) -> T {
    let storage = Thread.current.threadDictionary
    let k = identifier.objcDictKey

    let instance: T = storage[k] as? T ?? initialValue()
    if storage[k] == nil {
        storage[k] = instance
    }
    return instance
}

private func dateFormatter(_ format: String) -> DateFormatter {
    return threadLocalInstance(.dateFormatter(format), initialValue: {
        let df = DateFormatter()
        df.dateFormat = format
        return df
    }())
}

private func defaultNumberFormatter() -> NumberFormatter {
    return threadLocalInstance(.defaultNumberFormatter, initialValue: NumberFormatter())
}

private func localeNumberFormatter(_ locale: Locale) -> NumberFormatter {
    return threadLocalInstance(.localeNumberFormatter(locale), initialValue: {
        let nf = NumberFormatter()
        nf.locale = locale
        return nf
    }())
}
