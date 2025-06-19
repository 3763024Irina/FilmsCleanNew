import Foundation

enum MovieCategory: Int, CaseIterable {
    case popular = 0
    case nowPlaying
    case topRated
    case upcoming

    private var apiKey: String {
        return "ab3776f359fcef3b2030735ceea2eeaf"
    }

    private var language: String {
        return "fr-FR"
    }

    // Генерация URL с использованием URLComponents
    func urlString(page: Int = 1) -> String {
        let base = "https://api.themoviedb.org/3/movie/"
        let endpoint: String
        
        switch self {
        case .popular: endpoint = "popular"
        case .nowPlaying: endpoint = "now_playing"
        case .topRated: endpoint = "top_rated"
        case .upcoming: endpoint = "upcoming"
        }
        
        // Создаем URL с параметрами
        var components = URLComponents(string: base + endpoint)
        components?.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "language", value: language),
            URLQueryItem(name: "page", value: "\(page)")
        ]
        
        return components?.url?.absoluteString ?? ""
    }

    var title: String {
        switch self {
        case .popular: return "Популярные"
        case .nowPlaying: return "Сейчас"
        case .topRated: return "Оценённые"
        case .upcoming: return "Скоро"
        }
    }
}
