import Foundation
import RealmSwift

class Model {
    var testArray: Results<Item>?
    
    func fetchMoviesFromAPI() {
        guard let url = URL(string: "https://api.themoviedb.org/3/movie/popular?language=en-US&page=1") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiJhYjM3NzZmMzU5ZmNlZjNiMjAzMDczNWNlZWEyZWVhZiIsIm5iZiI6MTc0MzUyNTMxNy4yMjQsInN1YiI6IjY3ZWMxNWM1ZTE2YzYxZGE0NDQyYjFkNSIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.DMeofagrq7g5PKLJZxCre1RiVxScyuJcaDjIcGq8Mc8", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "accept")
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, error == nil else {
                print("Ошибка загрузки: \(error?.localizedDescription ?? "Нет данных")")
                return
            }

            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(MovieResponse.self, from: data)
                
                let movies = response.results
                
                let realm = try Realm()
                try realm.write {
                    // Удалим старые данные (по желанию)
                    realm.delete(realm.objects(Item.self))
                    
                    for movie in movies {
                        let item = Item()
                        item.id = movie.id
                        item.testTitle = movie.title
                        let y = year(from: movie.releaseDate)
                        item.testYeah = "\(y)"

                        item.testRating = String(movie.voteAverage)
                        item.testPic = movie.posterPath ?? ""
                        item.isLiked = false
                        realm.add(item)
                    }
                }
                
                DispatchQueue.main.async {
                    self.testArray = realm.objects(Item.self).sorted(byKeyPath: "id", ascending: true)
                }
                
            } catch {
                print("Ошибка при парсинге данных: \(error)")
            }
        }.resume()
    }
}
