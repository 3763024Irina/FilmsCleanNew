//
//  NetworkManagerTests.swift
//  FilmsAppTests
//
//  Created by Irina on 15/6/25.
//
import XCTest
@testable import FilmsApp  // Замени на имя твоего основного модуля

final class NetworkManagerTests: XCTestCase {
    func testDataRequestSuccess() {
        // Ожидаемость для асинхронного теста
        let expectation = self.expectation(description: "Request completes")

        // Пример валидного URL (например, открытый API)
        let urlString = "https://jsonplaceholder.typicode.com/posts/1"

        NetworkManager.shared.dataRequest(urlString: urlString) { result in
            switch result {
            case .success(let data):
                XCTAssertFalse(data.isEmpty, "Данные не должны быть пустыми")
            case .failure(let error):
                XCTFail("Запрос не должен был завершиться ошибкой: \(error)")
            }
            expectation .fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testDataRequestInvalidURL() {
        let expectation = self.expectation(description: "Invalid URL fails")

        let invalidURL = "invalid url"

        NetworkManager.shared.dataRequest(urlString: invalidURL) { result in
            switch result {
            case .success:
                XCTFail("Запрос с некорректным URL не должен был пройти")
            case .failure:
                // Ожидаем ошибку
                XCTAssertTrue(true)
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }
}
