import Foundation
import Glibc

// Use enums to enforce uniqueness of option labels.
enum LongLabel: String {
case FileType           = "filetype"
case PresetName         = "preset"
case DeleteExistingFile = "replace"
case LogEverything      = "verbose"
case TrimStartTime      = "trim-start-time"
case TrimEndTime        = "trim-end-time"
case FilterMetadata     = "filter-metadata"
case InjectMetadata     = "inject-metadata"
}

enum ShortLabel: String {
case FileType           = "f"
case PresetName         = "p"
case DeleteExistingFile = "r"
case LogEverything      = "v"
}

var arguments = CommandLine.arguments;
print("Arguments: \(arguments.count) \(arguments.remove(at: 0)) ");

if arguments.count < 4 {
   print("MailCountLog ciffers min max text \n")
   exit(1)
}
var len = 9;
if let optlen = Int(arguments[0]) {
   len = optlen;
   arguments.remove(at:0);
}
guard let lower = Int(arguments[0]) else {
  print("Missing lower")
  exit(1)
}
arguments.remove(at:0)

guard let upper = Int(arguments[0]) else {
  print("Missing upper")
  exit(1)
}
arguments.remove(at:0);

if arguments.count == 0 {
   print("Group by text required");
   exit(1)
}
var counter = 0
func updateCounter() {
    counter += 1;
    print("tick tack");
}

var SwiftTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { arg in 
    print("tick tock");
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

/*
print("Before run loop");
dispatchMain()
print("After run loop");
*/

var total_count = 0;
var old_time = ""
var count = 0
var match_time = ""

/*
  dateFormatter.setFormat("MMM dd HH:mm")


  var currentDate = Date()
  let newFormatter = DateFormatter()
  newFormatter.dateFormat = "yyyy"

  let YearString = newFormatter.string(from: currentDate)
  let newDateString = String(YearString + " " + dateString)
  print ("full date string: \(newDateString) \(newDateString!.characters.count) " )
*/

func getDateFormatter(_ len: Int) -> DateFormatter {
  let dateFormatter = DateFormatter()
  dateFormatter.dateFormat = "MMM dd HH:mm:ss"
  return dateFormatter;
}
  
var interval_str = [ 9 : ":00", 11 : "0", 12 : ""]
var ok_range = lower...upper

func dateConv(_ dateString: String, len : Int) -> Double? {
  let dateFormatter = getDateFormatter(len)
  let format = dateFormatter.dateFormat!
  dateFormatter.dateFormat = String(format[..<format.index(format.startIndex, offsetBy: len)])
  if let date = dateFormatter.date(from: dateString + interval_str[len]!) {
    return date.timeIntervalSince1970
  }
  return 0.0
}

func dateFormat(_ date: Date, len : Int) -> String {
  let dateFormatter = getDateFormatter(len)
  let ds = dateFormatter.string(from: date)
  return String(ds[..<ds.index(ds.startIndex, offsetBy: len)])
}

func sendAlarm(_ count: Int, _ at: String) -> Void {
  let child = fork();
  if child == 0 {
    close(0);
    close(1);
    // print("Alarm: Outside range: \(count)")
    print(executeCommand(command: "/usr/bin/mail", args: [ "dennis@schafroth.dk", "-s \"Alarm: \(count) at \(at) " + arguments[0] + "\""]))
    close(0);
    close(1);
    exit(0);
  }
  else {
    print("Child process: \(child) ");
    let ptr = UnsafeMutablePointer<Int32>.allocate(capacity: 1);
    let pid = wait(ptr);
    let rc = ptr.pointee;
    print("Child \(pid) ended with status \(rc) ");
    ptr.deallocate(capacity: 1);
  }
}

var interval_dict = [ 9 : 3600.0, 11 : 600.0, 12 : 60.0]
while let line = readLine(strippingNewline: true) {
  total_count += 1
  let end = line.index(line.startIndex, offsetBy: len)
  let time = String(line[..<end])

/*
  let end_full   = line.index(line.startIndex, offsetBy: 12)
  let time_full  = String(line[..<end_full])
  if let timeInterval = dateConv(time_full, len: 12) {
     print ("epoch: \(timeInterval) ") 
  }
*/

  for argument in arguments {
    if line.range(of: argument, options: .regularExpression) != nil {
      count += 1
    }
    else {

    }
  }
  if old_time != "" {
    let current_time = dateConv(time, len: len)!
    var old_time_val = dateConv(old_time, len: len)!
    while current_time > old_time_val {
      if !ok_range.contains(count) {
	sendAlarm(count, old_time);
      }
      print("\(count)\t\(old_time) \(total_count) ");
      count = 0
      total_count = 0;
      old_time_val += interval_dict[len]!
      // Convert old_time_val back to string
      old_time = dateFormat(Date(timeIntervalSince1970: old_time_val),len: len)
    }
  }
  old_time = time;
}
