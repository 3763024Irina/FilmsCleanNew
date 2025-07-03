/*утечка памяти:

Типичные причины:

Сессии URLSession не инвалидируются и держат вложенные замыкания с сильными ссылками на self.

Нотификации / KVO: забыли отписаться от NotificationCenter/Realm notifications.

Timers: таймеры (DispatchSourceTimer, CADisplayLink) продолжают жить после ухода контроллера.

Realm: объекты-токены подписки (NotificationToken) не invalid().

Способ решения

В местах, где запускаются асинхронные работы (URLSession.dataTask, Realm observation, Timer), добавьте …{ [weak self] … } и инвалидировать/отписать в deinit или viewWillDisappear.

swift

После этих правок ещё раз профилирую Allocations + Leaks, чтобы убедиться, что «Persistent» аллокации не растут бесконечно.

Как убедиться, что утечка исправлена

Запустить с чистого старта Instruments, собрать пару циклов переходов между экранами.

Убедиться, что после закрытия экрана объём «Persistent» памяти возвращается примерно к исходному уровню.

*/

import Foundation

class TMDbAPI {
    
    private let apiKey = "ab3776f359fcef3b2030735ceea2eeaf"
    private let baseURL = "https://api.themoviedb.org/3/movie"
    private let language = "fr-FR"
    
    // Универсальный метод запроса
    func dataRequest(endpoint: String, page: Int = 1, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        var components = URLComponents(string: "\(baseURL)/\(endpoint)")
        components?.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "language", value: language),
            URLQueryItem(name: "page", value: "\(page)")
        ]
        
        guard let url = components?.url else {
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

    // MARK: - Стандартные категории
    func fetchLatest(completion: @escaping (Result<[String: Any], Error>) -> Void) {
        dataRequest(endpoint: "latest", page: 1, completion: completion)
    }

    func fetchNowPlaying(completion: @escaping (Result<[String: Any], Error>) -> Void) {
        dataRequest(endpoint: "now_playing", completion: completion)
    }

    func fetchTopRated(completion: @escaping (Result<[String: Any], Error>) -> Void) {
        dataRequest(endpoint: "top_rated", completion: completion)
    }

    func fetchUpcoming(completion: @escaping (Result<[String: Any], Error>) -> Void) {
        dataRequest(endpoint: "upcoming", completion: completion)
    }

    // MARK: - Загрузка preview-изображений
    func fetchImages(forMovieId id: Int, completion: @escaping (Result<[String], Error>) -> Void) {
        var components = URLComponents(string: "\(baseURL)/\(id)/images")
        components?.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey)
        ]

        guard let url = components?.url else {
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
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let backdrops = json["backdrops"] as? [[String: Any]] {

                    let imageURLs: [String] = backdrops.prefix(5).compactMap { dict in
                        if let path = dict["file_path"] as? String {
                            return "https://image.tmdb.org/t/p/w780\(path)"
                        }
                        return nil
                    }

                    completion(.success(imageURLs))
                } else {
                    completion(.failure(NSError(domain: "Parsing Error", code: 0)))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
