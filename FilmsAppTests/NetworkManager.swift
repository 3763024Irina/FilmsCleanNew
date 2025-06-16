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
