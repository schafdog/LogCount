import Foundation
#if os(Linux)
import GLibc
#else
import Darwin
#endif
import Utility

var arguments = CommandLine.arguments;
let commandName = arguments.remove(at: 0);


func getDateFormatter() -> DateFormatter {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "MMM dd HH:mm:ss"
    return dateFormatter;
}

var defaultTimePeriod : TimePeriod = TimePeriod.Minute
var fileHandle = FileHandle.standardInput
var old_time : DateGroup?
var lineStat = LineStat();
var parser = ArgumentParser(commandName: commandName,
                            usage: "\(commandName) [--min number] [--max number] --time [day|hour|10-minute,minute] regex",
    overview: "Simple event statistic over certain period with posibility to send mail alert when out of range",
    seeAlso: "Not sure")
var minArg : OptionArgument<Int> = parser.add(option: "--min",
                                           shortName: "-l",
                                           kind: Int.self,
                                           usage: "minimal number of matches")
var maxArg : OptionArgument<Int> = parser.add(option: "--max",
                                           shortName: "-h",
                                           kind: Int.self,
                                           usage: "maximal number of matches")
var emailArg : OptionArgument<String> = parser.add(option: "--email",
                                                shortName: "-e",
                                                kind: String.self,
                                                usage: "Email address")
var fileArg : OptionArgument<String> = parser.add(option: "--file",
                                                  shortName: "-f",
                                                  kind: String.self,
                                                  usage: "Use file instead of stdin")
var timePeriod = parser.add(option: "--time", shortName: "-t",
                            kind: TimePeriod.self, usage: "time periode")
var statArg = parser.add(option: "--stat", shortName: "-s", kind: String.self, usage: "Alternative Stat")
var regexArg = parser.add(positional: "regex", kind: [String].self, usage: "A list of regex")
var upper = Int.max-1
var lower : Int = 0
var patternArray : Array<String> = []
var emailAddress = ""
do {
    let args = try parser.parse(arguments)
    if let paramTimePeriod = args.get(timePeriod) {
        defaultTimePeriod = paramTimePeriod
    }
    
    if let min = args.get(minArg) {
        lower = min
        print("--min \(lower)")
    }
    if let max = args.get(maxArg) {
        upper = max
        print("--max \(upper)")
    }
    if let regexParams = args.get(regexArg) {
        patternArray = regexParams
    }
    if  (lower > 0 || upper < Int.max-1) {
        guard let paramEmail = args.get(emailArg) else {
            print("email is not optional if alert is enabled by a min or max")
            exit(1)
        }
        emailAddress = paramEmail
        print("Sending alerts to \(emailAddress) outside interval \(lower) and \(upper)")
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
    if let _ = args.get(statArg) {
        lineStat = PercentLineStat();
    }
} catch ArgumentParserError.expectedArguments(_, let args) {
    print("Missing arguments \(args)")
    exit(1)
}

func executeCommand(command: String, args: [String]) -> String? {
    let task = Process();
    task.launchPath = command
    task.arguments = args
    let procInfo = ProcessInfo()
    var env = procInfo.environment;
    env["REPLYTO"] = "MailLogCount <postmaster@schafroth.dk>"
    task.environment = env;
    let resultPipe = Pipe()
    let inputPipe = Pipe()
    task.standardInput = inputPipe
    task.standardOutput = resultPipe
    let mailBody = inputPipe.fileHandleForWriting
    mailBody.write(String("Empty Body").data(using: String.Encoding.utf8)!)
    mailBody.closeFile()
    task.launch()
    let data = resultPipe.fileHandleForReading.readDataToEndOfFile()
    if !data.isEmpty {
        let output: String = String(data: data, encoding: String.Encoding.utf8)!
        return output
    }
    return nil;
}

var ok_range = lower...upper


func sendAlarm(_ count: Int, _ at: String) -> Void {
    DispatchQueue(label: "mailsender").async {
        if let result = executeCommand(command: "/usr/bin/mail",
                                       args: [ "-s \"Alarm: \(count) at \(at) \" ", emailAddress]) {
            print("executeCommand result: \(result) ")
        }
    }
}

var regexArray : [NSRegularExpression] = [] 
for pat in patternArray {
    let regex = try! NSRegularExpression(pattern: pat, options: []);
    regexArray.append(regex)
}

var dateConv = DateConversion(df: getDateFormatter(), time: defaultTimePeriod)
var sr = StreamReader(fileHandle: fileHandle)
while let line = sr.nextLine() {
    lineStat.incTotal()
    let time = DateGroup(substr: line, dateConversion: dateConv)
    
    for regex in regexArray {
        lineStat.addMatches(regex.numberOfMatches(in: line, options: [],  range: NSRange(location: 0, length: line.count)))
    }
    
    if old_time != nil {
        while time > old_time! {
            if !lineStat.in_range(ok_range) {
                sendAlarm(lineStat.getMatched(), old_time!.getDateAsString());
            }
            lineStat.printStat(old_time!.getDateAsString());
            lineStat.reset()
            old_time = old_time?.nextGroup()
        }
    }
    old_time = time;
}
if (lineStat.getTotal() > 0) {
    lineStat.printStat(old_time!.getDateAsString());
}
