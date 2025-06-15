import Foundation
class TMDbAPI {
   
    private let apiKey = "ab3776f359fcef3b2030735ceea2eeaf"

    
    private let baseURL = "https://api.themoviedb.org/3/movie"

   
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

   
    func fetchLatest(completion: @escaping (Result<[String: Any], Error>) -> Void) {
        
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
