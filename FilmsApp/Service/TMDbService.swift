import Foundation
import RealmSwift

class TMDbService {
    static let shared = TMDbService()
    
    private let bearerToken = "eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiJhYjM3NzZmMzU5ZmNlZjNiMjAzMDczNWNlZWEyZWVhZiIsIm5iZiI6MTc0MzUyNTMxNy4yMjQsInN1YiI6IjY3ZWMxNWM1ZTE2YzYxZGE0NDQyYjFkNSIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.DMeofagrq7g5PKLJZxCre1RiVxScyuJcaDjIcGq8Mc8"
    
    private init() {}
    
    func fetchPopularMovies() async throws -> [Item] {
        guard let url = URL(string: "https://api.themoviedb.org/3/movie/popular?language=ru-RU&page=1") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "accept")
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let results = json["results"] as? [[String: Any]] else {
            throw NSError(domain: "ParsingError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON structure"])
        }
        
        var items: [Item] = []
        
        for movie in results {
            let item = Item()
            item.id = movie["id"] as? Int ?? 0
            item.testTitle = (movie["title"] as? String) ?? ""
            
            if let date = movie["release_date"] as? String, date.count >= 4 {
                item.testYeah = String(date.prefix(4))
            } else {
                item.testYeah = ""
            }
            
            if let rating = movie["vote_average"] as? Double {
                item.testRating = String(format: "%.1f", rating)
            } else {
                item.testRating = ""
            }
            
            item.testPic = (movie["poster_path"] as? String) ?? ""
            items.append(item)
        }
        
        return items
    }
}
