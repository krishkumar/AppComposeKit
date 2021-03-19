import XCTest
@testable import AppComposeKit

let postsRequest = URLRequest(url: URL(string: "https://jsonplaceholder.typicode.com/posts")!)

final class AppComposeKitTests: XCTestCase {
    var remote: Remote<Post> {
        let request = postsRequest
        return Remote<Post>(url: request)
    }
    
    // MARK: Test ValueFetcher
    // Tests for ValueFetcher
    func testValueFetcher() {
        let exp = expectation(description: "Loading Posts")
        var expBody = ""
        let _ = ValueFetcher(remote: remote) { value in
            if let v = value {
                print(v.body)
                expBody = v.body
                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 25.0)
        XCTAssertEqual("quia et suscipit\nsuscipit recusandae consequuntur expedita et cum\nreprehenderit molestiae ut ut quas totam\nnostrum rerum est autem sunt rem eveniet architecto", expBody, "Loaded posts successfully!")
    }

    static var allTests = [
        ("testValueFetcher", testValueFetcher),
    ]
}

