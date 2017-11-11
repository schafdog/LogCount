import XCTest
@testable import MailLogCount

class MailLogCountTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(MailLogCount().text, "Hello, World!")
    }


    static var allTests = [
        ("testExample", testExample),
    ]
}
