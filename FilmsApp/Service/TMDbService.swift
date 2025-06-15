import Foundation
import RealmSwift

class TMDbService {
    static let shared = TMDbService()
    
    private let bearerToken = "eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiJhYjM3NzZmMzU5ZmNlZjNiMjAzMDczNWNlZWEyZWVhZiIsIm5iZiI6MTc0MzUyNTMxNy4yMjQsInN1YiI6IjY3ZWMxNWM1ZTE2YzYxZGE0NDQyYjFkNSIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.DMeofagrq7g5PKLJZxCre1RiVxScyuJcaDjIcGq8Mc8"
    
    private let baseImageURL = "https://image.tmdb.org/t/p/w780"
    
    private init() {}
    
    func fetchPopularMovies(page: Int) async throws -> [Item] {
        guard let url = URL(string: "https://api.themoviedb.org/3/movie/popular?language=ru-RU&page=\(page)") else {
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
        
        for movieDict in results {
            let item = Item()
            
            item.id = movieDict["id"] as? Int ?? 0
            
            if let title = movieDict["title"] as? String {
                item.testTitle = title
            } else if let originalTitle = movieDict["original_title"] as? String {
                item.testTitle = originalTitle
            } else {
                item.testTitle = "Без названия"
            }
            
            if let releaseDate = movieDict["release_date"] as? String, releaseDate.count >= 4 {
                item.testYeah = String(releaseDate.prefix(4))
            } else {
                item.testYeah = "Неизвестно"
            }
            
            if let voteAverage = movieDict["vote_average"] as? Double {
                item.testRating = String(format: "%.1f", voteAverage)
            } else {
                item.testRating = "0.0"
            }
            
            if let posterPath = movieDict["poster_path"] as? String {
                // Важно: posterPath уже начинается с "/" — просто добавляем baseImageURL + posterPath
                item.testPic = baseImageURL + posterPath
            } else {
                item.testPic = ""
            }
            
            items.append(item)
        }
        
        return items
    }
}
