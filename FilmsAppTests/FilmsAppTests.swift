
//
//Этот метод testExample() — чисто проверочный шаблон от Xcode и не тестирует никакую логику вашего приложения. Он просто делает XCTAssertEqual(1 + 1, 2), чтобы убедиться, что механизм тестирования работает:

//Если тест запускается и проходит, значит тестовая инфраструктура настроена верно.
import Foundation
import XCTest
@testable import FilmsApp

final class FilmsAppTests: XCTestCase {

    func testExample() throws {
        XCTAssertEqual(1 + 1, 2)
    }
}
