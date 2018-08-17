//
//  LineStat.swift
//  Basic
//
//  Created by Dennis Schafroth on 16/08/2018.
//

import Foundation


class LineStat : CustomStringConvertible {
    var total = 0
    var matched = 0
    
    var description : String {
        var description = ""
        description += "\(self.matched)\t"
        description += "\(self.total)"
        return description
    }

    init() {
        reset()
    }

    func reset() {
        total = 0
        matched = 0
    }

    public func incTotal() {
        total += 1
    }

    public func getTotal() -> Int {
        return total
    }

    public func addMatches(_ match : Int) {
        matched  += match
    }

    public func getMatched() -> Int {
        return matched
    }

    public func printStat(_ string : String) {
        print(description + "[\(getPercent())]\t" + string)
    }

    public func in_range(_ range :ClosedRange<Int>) -> Bool {
        return range.contains(getMatched())
    }

    func getPercent() -> Int {
        return total > 0 ? 100*matched/total : -1
    }

}

class PercentLineStat : LineStat {
    
    override func printStat(_ string : String) {
        let percentNum = getPercent()
        let percentStr = percentNum != -1 ? String(percentNum) + "%"  : "N/A"
        print(percentStr + " \(matched)/\(total)\t" + string)
    }
    
    override public func in_range(_ range :ClosedRange<Int>) -> Bool {
        return range.contains(getPercent())
    }

}
