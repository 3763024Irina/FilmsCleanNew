//
//  DateParsingTests.swift
//  FilmsAppTests
//
//  Created by Irina on 1/7/25.
//
//Эти три теста проверяют функцию year(from:), которая извлекает год из строки даты, в разных сценариях
import Foundation
import XCTest
@testable import FilmsApp

final class DateParsingTests: XCTestCase {

  func testYearFromISOFormat() {
    XCTAssertEqual(year(from: "2021-10-10"), 2021)
  }

  func testYearFromEuropeanFormat() {
    XCTAssertEqual(year(from: "10-10-2021"), 2021)
  }

  func testYearFromBadString() {
    XCTAssertEqual(year(from: "invalid"), 0)
  }

}
