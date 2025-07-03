/*
 1. Проблема: RealmSwift подключается через CocoaPods как XCFramework, и его бинарники (по 60–100 МБ каждый) резко раздувают вес приложения и историю Git, из-за чего GitHub отказывается принимать пуши.
 Решение:

 Добавила папку Pods/ в .gitignore и выполнила git rm -r --cached Pods, чтобы исключить большие файлы из индекса.

 Перезаписала историю репозитория через git filter-branch (или BFG Repo-Cleaner), чтобы «очистить» прошлые коммиты от тяжёлых артефактов.

 
 Аргумент невозможности полного решения: без CocoaPods или без Realm нам бы пришлось отказываться от удобного ORM и работы с базой, поэтому проблемы веса лишь минимизируются, но не исчезают полностью.
 
 2. Настройка модульного тестирования (@testable import)
 Проблема: при попытке писать unit-тесты Xcode выдавал ошибку

 Module 'FilmsApp' was not compiled for testing
 — тесты не видели внутренние (internal) свойства приложения, потому что приложение собиралось без флага -enable-testing.
 Решение:

 В Build Settings таргета FilmsApp для конфигурации Debug включили Enable Testability = Yes.

 Перешла на рабочую область .xcworkspace, чтобы CocoaPods-схемы корректно подхватились.

 В схеме Edit Scheme → Test убедилась, что Build Configuration стоит Debug, и что оба таргета (FilmsApp и FilmsAppTests) участвуют в сборке и в тестах.
 Аргумент невозможности полного решения: без включения тестируемости нельзя использовать @testable import и покрывать код internal-методами, поэтому этот шаг обязателен для любых unit-тестов.

*/
import Foundation


final class NetworkManager {
    static let shared = NetworkManager()
    private init() {}

    func dataRequest(urlString: String,
                     session: URLSession = .shared,
                     completion: @escaping (Result<Data, Error>) -> Void) {

        guard let url = URL(string: urlString) else {
            let error = NSError(domain: "NetworkManager", code: 1001, userInfo: [
                NSLocalizedDescriptionKey: "Неверный URL: \(urlString)"
            ])
            completion(.failure(error))
            return
        }

        print("➡️ Запрос: \(urlString)")

        let task = session.dataTask(with: url) { data, response, error in

            if let error = error {
                print("⛔️ Ошибка запроса: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                let error = NSError(domain: "NetworkManager", code: 1002, userInfo: [
                    NSLocalizedDescriptionKey: "Некорректный ответ от сервера"
                ])
                completion(.failure(error))
                return
            }

            print("📡 HTTP статус: \(httpResponse.statusCode)")

            guard (200...299).contains(httpResponse.statusCode) else {
                let error = NSError(domain: "NetworkManager", code: httpResponse.statusCode, userInfo: [
                    NSLocalizedDescriptionKey: "Ошибка ответа сервера: \(httpResponse.statusCode)"
                ])
                completion(.failure(error))
                return
            }

            guard let data = data else {
                let error = NSError(domain: "NetworkManager", code: 1003, userInfo: [
                    NSLocalizedDescriptionKey: "Сервер вернул пустой ответ"
                ])
                completion(.failure(error))
                return
            }

            completion(.success(data))
        }

        task.resume()
    }
}
