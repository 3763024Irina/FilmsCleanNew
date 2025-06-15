import Foundation

class TMDbAPI {
   
    private let apiKey = "ab3776f359fcef3b2030735ceea2eeaf"
    private let baseURL = "https://api.themoviedb.org/3/movie"
    private let language = "ru-RU"

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

    // fetchLatest вызывает dataRequest с endpoint "latest"
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
}
