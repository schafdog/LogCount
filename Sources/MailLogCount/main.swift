import Foundation
#if os(Linux)
import GLibc
#else
import Darwin
#endif
import Utility

var arguments = CommandLine.arguments;
let commandName = arguments.remove(at: 0);

enum TimePeriod: String {
    case Day
    case Hour
    case TenMin
    case TenMinute
    case Minute
}

var timeToLength = [ TimePeriod.Day: 6, TimePeriod.Hour: 9, TimePeriod.TenMin : 11, TimePeriod.TenMinute : 11, TimePeriod.Minute: 12]

extension TimePeriod: StringEnumArgument {
    static var completion: ShellCompletion {
        return .values([(TimePeriod.Day.rawValue,  ""),
                        (TimePeriod.Hour.rawValue, ""),
                        (TimePeriod.TenMin.rawValue,""),
                        (TimePeriod.TenMinute.rawValue,""),
                        (TimePeriod.Minute.rawValue,  ""),
                        ])
    }
}
var defaultTimePeriod : TimePeriod = TimePeriod.Minute
var parser = ArgumentParser(commandName: commandName,
                            usage: "\(commandName) [--min number] [--max number] --time [day|hour|10-minute,minute] regex",
    overview: "Simple event statistic over certain period with posibility to send mail alert when out of range",
    seeAlso: "Not sure")
var min : OptionArgument<Int> = parser.add(option: "--min",   shortName: "-l", kind: Int.self, usage: "minimal number of matches")
var max : OptionArgument<Int> = parser.add(option: "--max",   shortName: "-h", kind: Int.self, usage: "maximal number of matches")
var email : OptionArgument<String> = parser.add(option: "--email", shortName: "-e", kind: String.self, usage: "Email address")
var fileArg : OptionArgument<String> = parser.add(option: "--file", shortName: "-f", kind: String.self, usage: "Use file instead of stdin")
var timePeriod = parser.add(option: "--time", shortName: "-t", kind: TimePeriod.self, usage: "time periode")
var regexArg = parser.add(positional: "regex", kind: [String].self, usage: "A list of regex")
var upper = Int.max-1
var lower : Int = 0
var patternArray : Array<String> = []
var fileHandle = FileHandle.standardInput

do {
    let args = try parser.parse(arguments)
    if let paramTimePeriod = args.get(timePeriod) {
        defaultTimePeriod = paramTimePeriod
    }

    if let paramMin = args.get(min) {
        lower = paramMin
    }
    if let paramMax = args.get(max) {
        upper = paramMax
        print("--max \(upper)")
    }
    if let regexParams = args.get(regexArg) {
        patternArray = regexParams
    }
    if  (lower > 0 || upper < Int.max-1) {
        guard let paramEmail = args.get(email) else {
            print("email is not optional if alert is enabled by a min or max")
            exit(1)
        }
        print("Sending alerts to \(paramEmail) outside interval \(min) and \(max)")
        // No need for email
    }
    if let filename = args.get(fileArg) {
        let url = URL(fileURLWithPath: filename)
        do {
            fileHandle = try FileHandle(forReadingFrom: url)
            
        } catch let error as NSError {
            print("Failed to open \(filename). Error: \(error.localizedDescription) Exiting")
            exit(1)
        }
    }
} catch ArgumentParserError.expectedArguments(_, let args) {
    print("Missing arguments \(args)")
    exit(1)
}

func executeCommand(command: String, args: [String]) -> String {
    let task = Process();
    task.launchPath = command
    task.arguments = args

    let pipe = Pipe()
    task.standardOutput = pipe
    task.launch()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output: String = String(data: data, encoding: String.Encoding.utf8)!
    return output
}

var counter = 0
var total_count = 0;
var count = 0
var match_time = ""
guard let len = timeToLength[defaultTimePeriod] else {
    print("Failed to get length")
    exit(1)
}

func getDateFormatter() -> DateFormatter {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "MMM dd HH:mm:ss"
    return dateFormatter;
}

var ok_range = lower...upper


func sendAlarm(_ count: Int, _ at: String) -> Void {
    DispatchQueue(label: "mailsender").async {
        print(executeCommand(command: "/usr/bin/mail",
                             args: [ "dennis@schafroth.dk",
                                     "-s \"Alarm: \(count) at \(at) \(arguments[0]) \" "]))
    }
}

var regexArray : [NSRegularExpression] = [] 
for pat in patternArray {
    let regex = try! NSRegularExpression(pattern: pat, options: []);
    regexArray.append(regex)
}
var dateConv = DateConversion(df: getDateFormatter(), len: len)
var sr = StreamReader(fileHandle: fileHandle)
var old_time : DateGroup?
while let line = sr.nextLine() {
    total_count += 1
    let time = DateGroup(substr: line, dateConversion: dateConv)


    for regex in regexArray {
        count += regex.numberOfMatches(in: line, options: [],  range: NSRange(location: 0, length: line.count))
    }

    if old_time != nil {
        while time > old_time! {
            if !ok_range.contains(count) {
                sendAlarm(count, old_time!.getDateAsString());
            }
            print("\(count)\t\(old_time!.getDateAsString()) \(total_count) ");
            count = 0
            total_count = 0;
            old_time = old_time?.nextGroup()
        }
    }
    old_time = time;
}
