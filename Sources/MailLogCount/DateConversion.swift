//
//  DateConversion.swift
//  Basic
//
//  Created by Dennis Schafroth on 16/08/2018.
//

import Foundation
import Utility

public enum TimePeriod: String {
    case Day
    case Hour
    case TenMin
    case TenMinute
    case Minute
}

extension TimePeriod: StringEnumArgument {
    public static var completion: ShellCompletion {
        return .values([(TimePeriod.Day.rawValue,  ""),
                        (TimePeriod.Hour.rawValue, ""),
                        (TimePeriod.TenMin.rawValue,""),
                        (TimePeriod.TenMinute.rawValue,""),
                        (TimePeriod.Minute.rawValue,  ""),
                        ])
    }
}

class DateConversion {

    var timeToLength = [ TimePeriod.Day: 6, TimePeriod.Hour: 9, TimePeriod.TenMin : 11, TimePeriod.TenMinute : 11, TimePeriod.Minute: 12]
    
    private let interval_str = [6: "", 9 : ":00", 10: ":0", 11 : "0", 12 : ""]
    var interval_dict = [ 6: 24*3600.0, 9 : 3600.0, 11 : 600.0, 12 : 60.0]
    private var df : DateFormatter;
    public var len : Int
    
    init(df: DateFormatter, time: TimePeriod) {
        self.df = df
        self.len = timeToLength[ time]!
        let format = df.dateFormat!
        df.dateFormat = String(format[..<format.index(format.startIndex, offsetBy: len)])
        print(df.dateFormat)
    }
    
    public func convert(_ dateString: String) -> Double {
        let newTime = dateString + interval_str[len]!
        if let date = df.date(from: dateString) {
            return date.timeIntervalSince1970
        }
        print("convert: Failure: \(newTime) using formatter \(df.dateFormat!) ")
        return 0.0
    }
    
    func dateFormat(_ date: Date) -> String {
        let ds = df.string(from: date)
        
        let dateStr =  String(ds[..<ds.index(ds.startIndex, offsetBy: len)])
        // Fix log files uses single digit day of month with double space
        let index = dateStr.index(dateStr.startIndex, offsetBy: 4)
        if dateStr[index] == "0" {
            return dateStr.replacingCharacters(in: index...index, with: " ")
        }
        return dateStr
    }

    func getEpochInterval() -> Double {
        return interval_dict[len]!
    }

    func substr(_ line : String) -> String {
        let end = line.index(line.startIndex, offsetBy: len)
        return String(line[..<end])
    }
}

class DateGroup {
    private var dc : DateConversion
    private var epoch : Double
    private var asString : String;

    init(date: Date, dateConversion : DateConversion) {
        dc = dateConversion
        self.epoch = date.timeIntervalSince1970
        self.asString = dc.dateFormat(date)
    }

    init(string: String, dateConversion : DateConversion) {
        dc = dateConversion
        self.epoch =  dc.convert(string)
        self.asString = string
    }

    init(substr: String, dateConversion : DateConversion) {
        dc = dateConversion
        self.asString = dc.substr(substr)
        self.epoch =  dc.convert(self.asString)
    }

    public func getDateAsEpoch() -> Double {
        return epoch
    }

    public func getDateAsString() -> String {
        return asString
    }
    
    public func nextGroup() -> DateGroup {
        return DateGroup(date: Date(timeIntervalSince1970: self.getDateAsEpoch() + self.dc.getEpochInterval()),  dateConversion : dc)
    }

}

extension DateGroup {
    static func > (left: DateGroup, right: DateGroup) -> Bool {
        return  left.getDateAsEpoch() > right.getDateAsEpoch()
    }
}
