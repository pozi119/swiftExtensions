//
//  RegExpresionExt.swift
//  ValoKit
//
//  Created by Valo on 2016/12/2.
//
//

import Foundation

struct RxMatch {
    var value = ""
    /* The substring that matched the expression. */
    var range = NSRange()
    /* The range of the original string that was matched. */
    var groups = [Any]()
    /* Each object is an RxMatchGroup. */
    var original = ""
}

struct RxMatchGroup {
    var value = ""
    var range = NSRange()
}

extension NSRegularExpression {
    func isMatch(_ matchee: String) -> Bool {
        return numberOfMatches(in: matchee, options: [], range: NSRange(location: 0, length: matchee.length)) > 0
    }

    func index(of matchee: String) -> Int {
        let range = rangeOfFirstMatch(in: matchee, options: [], range: NSRange(location: 0, length: matchee.length))
        return range.location == NSNotFound ? -1 : range.location
    }

    func split(_ string: String) -> Array<String> {
        let range = NSRange(location: 0, length: string.length)
        var matchingRanges: Array<NSRange> = []
        let matches = self.matches(in: string, options: [], range: range)
        for match in matches {
            matchingRanges.append(match.range)
        }

        if matchingRanges.count == 0 {
            return [string]
        }

        var pieceRanges: Array<NSRange> = []

        var pos: Int = 0
        for r in matchingRanges {
            let pr = NSRange(location: pos, length: r.location - pos)
            if pr.length > 0 {
                pieceRanges.append(pr)
            }
            pos = r.location
        }

        var pieces: Array<String> = []
        for r in pieceRanges {
            let s = string.substring(r.location, length: r.length)
            pieces.append(s)
        }
        return pieces
    }

    func replace(_ string: String, with relpacement: String) -> String {
        return stringByReplacingMatches(in: string, options: [], range: NSMakeRange(0, string.length), withTemplate: relpacement)
    }

    func replace(_ string: String, withReplacer replacer: (String) -> String) -> String {
        var result = string
        let matches = self.matches(in: string, options: [], range: NSMakeRange(0, string.length))
        var i = Int(matches.count) - 1
        while i >= 0 {
            let match = matches[i]
            let r = result.subrange(match.range.location, length: match.range.length)
            let matchStr = String(string[r])
            let replacement = replacer(matchStr)
            result = result.replacingCharacters(in: r, with: replacement)
            i -= 1
        }
        return result
    }

    func replace(_ string: String, withDetails replacer: (RxMatch) -> String) -> String {
        // copy the string so we can replace subsections
        var replaced = string
        // get matches
        let matches = self.matches(in: string, options: [], range: NSRange(location: 0, length: string.count))
        // replace each match (right to left so indexing doesn't get messed up)
        var i = Int(matches.count) - 1
        while i >= 0 {
            let result = matches[i]
            let match = self.result(toMatch: result, original: string)
            let replacement = replacer(match)
            let r = string.subrange(result.range.location, length: result.range.length)
            replaced = replaced.replacingCharacters(in: r, with: replacement)
            i -= 1
        }
        return replaced
    }

    func matches(_ string: String) -> [String] {
        var matches = [String]()
        let results = self.matches(in: string, options: [], range: NSMakeRange(0, string.length))
        for result in results {
            let r = string.subrange(result.range.location, length: result.range.length)
            matches.append(String(string[r]))
        }
        return matches
    }

    func firstMatch(_ string: String) -> String? {
        let match = firstMatch(in: string, options: [], range: NSMakeRange(0, string.length))
        if match == nil {
            return nil
        }
        let r = string.subrange(match!.range.location, length: match!.range.length)
        return String(string[r])
    }

    func result(toMatch result: NSTextCheckingResult, original: String) -> RxMatch {
        var match = RxMatch()
        match.original = original
        match.range = result.range
        let r = original.subrange(result.range.location, length: result.range.length)
        match.value = result.range.length > 0 ? String(original[r]) : ""
        // groups
        var groups = [Any]()
        for i in 0 ..< result.numberOfRanges {
            var group = RxMatchGroup()
            group.range = result.range(at: i)
            let r = original.subrange(group.range.location, length: group.range.length)
            group.value = group.range.length > 0 ? String(original[r]) : ""
            groups.append(group)
        }
        match.groups = groups
        return match
    }

    func matches(withDetails str: String) -> [RxMatch] {
        var matches = [RxMatch]()
        let results = self.matches(in: str, options: [], range: NSMakeRange(0, str.length))
        for result: NSTextCheckingResult in results {
            matches.append(self.result(toMatch: result, original: str))
        }
        return matches
    }

    func firstMatch(withDetails str: String) -> RxMatch? {
        let results = matches(in: str, options: [], range: NSMakeRange(0, str.length))
        if results.count == 0 {
            return nil
        }
        return result(toMatch: results[0], original: str)
    }
}

extension String {
    func toRx() -> NSRegularExpression {
        return try! NSRegularExpression(pattern: self)
    }

    func toRxIgnoreCase(_ ignoreCase: Bool) -> NSRegularExpression {
        return try! NSRegularExpression(pattern: self, options: [.caseInsensitive])
    }

    func toRx(with options: NSRegularExpression.Options) -> NSRegularExpression {
        return try! NSRegularExpression(pattern: self, options: options)
    }

    func isMatch(_ rx: NSRegularExpression) -> Bool {
        return rx.isMatch(self)
    }

    func index(of rx: NSRegularExpression) -> Int {
        return rx.index(of: self)
    }

    func split(with rx: NSRegularExpression) -> [Any] {
        return rx.split(self)
    }

    func replace(_ rx: NSRegularExpression, with replacement: String) -> String {
        return rx.replace(self, with: replacement)
    }

    func replace(_ rx: NSRegularExpression, withReplacer replacer: (String) -> String) -> String {
        return rx.replace(self, withReplacer: replacer)
    }

    func replace(_ rx: NSRegularExpression, withDetails replacer: (RxMatch) -> String) -> String {
        return rx.replace(self, withDetails: replacer)
    }

    func matches(_ rx: NSRegularExpression) -> [String] {
        return rx.matches(self)
    }

    func firstMatch(_ rx: NSRegularExpression) -> String? {
        return rx.firstMatch(self)
    }

    func matches(withDetails rx: NSRegularExpression) -> [RxMatch] {
        return rx.matches(withDetails: self)
    }

    func firstMatch(withDetails rx: NSRegularExpression) -> RxMatch? {
        return rx.firstMatch(withDetails: self)
    }

    func isMatch(wildcard: String) -> Bool {
        var rx = wildcard.replacingOccurrences(of: "?", with: ".{1}")
        rx = rx.replacingOccurrences(of: "*", with: ".*")
        return isMatch(rx.toRx())
    }
}
