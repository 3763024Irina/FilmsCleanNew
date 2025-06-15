import Foundation

// Класс для запросов к TMDb API
class TMDbAPI {
    // Вставь сюда свой API ключ (лучше хранить отдельно и безопасно)
    private let apiKey = "ВАШ_API_КЛЮЧ"

    // Базовый URL для запросов фильмов
    private let baseURL = "https://api.themoviedb.org/3/movie"

    // Универсальный метод для запросов с конечной точкой (endpoint)
    func dataRequest(endpoint: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        let urlString = "\(baseURL)/\(endpoint)?api_key=\(apiKey)&language=ru-RU&page=1"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "URL Error", code: 0)))
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "Data Error", code: 0)))
                return
            }

            do {
                // Парсим JSON в словарь
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    completion(.success(json))
                } else {
                    completion(.failure(NSError(domain: "Parsing Error", code: 0)))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    // Специальный метод для получения последнего фильма
    func fetchLatest(completion: @escaping (Result<[String: Any], Error>) -> Void) {
        // У latest особый формат URL без пагинации
        let urlString = "\(baseURL)/latest?api_key=\(apiKey)&language=ru-RU"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "URL Error", code: 0)))
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "Data Error", code: 0)))
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    completion(.success(json))
                } else {
                    completion(.failure(NSError(domain: "Parsing Error", code: 0)))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    // Остальные категории фильмов
    func fetchNowPlaying(completion: @escaping (Result<[String: Any], Error>) -> Void) {
        dataRequest(endpoint: "now_playing", completion: completion)
    }

    func fetchTopRated(completion: @escaping (Result<[String: Any], Error>) -> Void) {
        dataRequest(endpoint: "top_rated", completion: completion)
    }

    func fetchUpcoming(completion: @escaping (Result<[String: Any], Error>) -> Void) {
        dataRequest(endpoint: "upcoming", completion: completion)
    }
}
