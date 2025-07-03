//  Created by Irina on 15/6/25.
//Эти два теста проверяют поведение метода dataRequest(urlString:session:completion:) из вашего NetworkManager в двух ключевых сценариях:

//testDataRequestSuccess

//Что делает: отправляет настоящий HTTP-запрос по адресу "https://jsonplaceholder.typicode.com/posts/1".

//Ожидаемый результат: в колбэке приходит .success(data) с непустым Data.

//Зачем: убеждаемся, что при корректном URL и рабочем интернет-соединении ваш метод умеет получать и возвращать данные без ошибок.

//testDataRequestInvalidURL

/*Что делает: вызывает dataRequest с некорректной строкой URL ("invalid url").

Ожидаемый результат: сразу возвращается .failure(error), и .success не вызывается.

Зачем: проверяем, что при неверном формате URL ваш метод корректно обрабатывает ошибку и не пытается делать сетевой запрос.

Вместе эти тесты покрывают две важные ветки кода:

Успешный путь (валидный URL → данные)

Путь ошибки (невалидный URL → мгновенная ошибка)*/
import XCTest
@testable import FilmsApp

final class NetworkManagerTests: XCTestCase {
    func testDataRequestSuccess() {
      
        let expectation = self.expectation(description: "Request completes")

      
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
