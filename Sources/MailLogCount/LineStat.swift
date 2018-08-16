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
        total = 0
        matched = 0
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
        print(description + "\t" + string)
    }
}

class PercentLineStat : LineStat {
    
    override func printStat(_ string : String) {
        let percent = total != 0 ? String((100*matched/total)) + "%"  : "-"
        print(percent + "\t" + string)
    }

}
