//
//  FlatSeekerTests.swift
//  FlatSeekerTests
//
//  Created by Aleksei Muraveinik on 23.05.23.
//

@testable import FlatSeeker
import XCTest

final class FlatSeekerTests: XCTestCase {
    private let parser = PriceParser()
    
    func test450() throws {
        let expected = 450
        let test = makeTest(for: parser, expected: expected)
        
        [
            "450$",
            "450 $",
            "$450",
            "$ 450",
            "450 долларов",
            "Цена 450",
            "450 💵",
            "💵4️⃣5️⃣0️⃣💲"
        ]
        .forEach(test)
    }
    
    func test1100() throws {
        let expected = 1100
        let test = makeTest(for: parser, expected: expected)
        
        [
            "1100$"
        ]
        .forEach(test)
    }
}

private func makeTest(for parser: PriceParser, expected: Int) -> (String) -> Void {
    { text in
        test(text, expected: expected, in: parser)
    }
}

private func test(_ text: String, expected: Int, in parser: PriceParser) {
    let price = parser.parsePrice(from: text)
    XCTAssertEqual(price, expected)
}
