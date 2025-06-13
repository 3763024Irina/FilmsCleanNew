import UIKit
import RealmSwift

class MainViewController: UIViewController {

    private var realm: Realm!
    private var notificationToken: NotificationToken?

    private var testArray: Results<Item>!
    private var filteredArray: Results<Item>!

    private var collectionView: UICollectionView!
    private var searchBar: UISearchBar!

    private var imageBaseURL: String = ""
    private var posterSize: String = "w500"

    private var showingLikedOnly = false

    private let apiKey = "eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiJhYjM3NzZmMzU5ZmNlZjNiMjAzMDczNWNlZWEyZWVhZiIsIm5iZiI6MTc0MzUyNTMxNy4yMjQsInN1YiI6IjY3ZWMxNWM1ZTE2YzYxZGE0NDQyYjFkNSIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.DMeofagrq7g5PKLJZxCre1RiVxScyuJcaDjIcGq8Mc8" 

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        setupRealm()
        setupSearchBar()
        setupCollectionView()
        setupNavigationBar()

        testArray = realm.objects(Item.self).sorted(byKeyPath: "id", ascending: true)
        filteredArray = testArray

        notificationToken = testArray.observe { [weak self] changes in
            guard let self = self else { return }
            switch changes {
            case .initial:
                self.collectionView.reloadData()
            case .update(_, let deletions, let insertions, let modifications):
                self.collectionView.performBatchUpdates {
                    self.collectionView.deleteItems(at: deletions.map { IndexPath(item: $0, section: 0) })
                    self.collectionView.insertItems(at: insertions.map { IndexPath(item: $0, section: 0) })
                    self.collectionView.reloadItems(at: modifications.map { IndexPath(item: $0, section: 0) })
                }
            case .error(let error):
                fatalError("\(error)")
            }
        }

        Task {
            await fetchTMDbConfiguration()
            await loadMoviesFromAPIIfNeeded()
        }
    }

    private func setupRealm() {
        let config = Realm.Configuration(
            schemaVersion: 3,
            migrationBlock: { migration, oldSchemaVersion in
                if oldSchemaVersion < 3 { }
            },
            deleteRealmIfMigrationNeeded: true
        )
        Realm.Configuration.defaultConfiguration = config

        do {
            realm = try Realm()
        } catch {
            fatalError("Ошибка инициализации Realm: \(error)")
        }
    }

    private func setupNavigationBar() {
        navigationController?.navigationBar.isHidden = false
        title = "Films"
        let heartButton = UIBarButtonItem(
            image: UIImage(systemName: "heart.fill"),
            style: .plain,
            target: self,
            action: #selector(showLikedMovies)
        )
        navigationItem.rightBarButtonItem = heartButton
    }

    @objc func showLikedMovies() {
        showingLikedOnly.toggle()
        updateFilteredArray()
    }

    private func updateFilteredArray() {
        if let text = searchBar.text, !text.isEmpty {
            if showingLikedOnly {
                filteredArray = testArray.filter("isLiked == true AND testTitle CONTAINS[c] %@", text)
            } else {
                filteredArray = testArray.filter("testTitle CONTAINS[c] %@", text)
            }
        } else {
            filteredArray = showingLikedOnly ? testArray.filter("isLiked == true") : testArray
        }
        collectionView.reloadData()
    }

    private func setupSearchBar() {
        searchBar = UISearchBar()
        searchBar.delegate = self
        searchBar.placeholder = "Search movies"
        navigationItem.titleView = searchBar
    }

    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 5
        layout.minimumLineSpacing = 5
        layout.sectionInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)

        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .white
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(MyCustomCell.self, forCellWithReuseIdentifier: "MyCustomCell")

        view.addSubview(collectionView)
    }

    private func fetchTMDbConfiguration() async {
        guard !apiKey.isEmpty else {
            print("API ключ не указан.")
            return
        }

        guard let url = URL(string: "https://api.themoviedb.org/3/configuration") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "accept")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let images = json["images"] as? [String: Any],
               let baseURL = images["secure_base_url"] as? String,
               let posterSizes = images["poster_sizes"] as? [String] {
                imageBaseURL = baseURL
                posterSize = posterSizes.contains("w500") ? "w500" : posterSizes.last ?? "w342"
            }
        } catch {
            print("Ошибка конфигурации TMDb:", error)
        }
    }

    private func loadMoviesFromAPIIfNeeded() async {
        if realm.objects(Item.self).isEmpty {
            await fetchPopularMovies()
        }
    }

    private func fetchPopularMovies() async {
        guard let url = URL(string: "https://api.themoviedb.org/3/movie/popular?language=ru-RU&page=1") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "accept")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let results = json["results"] as? [[String: Any]] {
                try realm.write {
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
                        realm.add(item, update: .modified)
                    }
                }

                DispatchQueue.main.async {
                    self.updateFilteredArray()
                }
            }
        } catch {
            print("Ошибка загрузки фильмов:", error)
        }
    }

    private func searchMovies(query: String) async {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://api.themoviedb.org/3/search/movie?query=\(encodedQuery)&language=ru-RU") else {
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "accept")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let results = json["results"] as? [[String: Any]] {
                try realm.write {
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
                        realm.add(item, update: .modified)
                    }
                }
                DispatchQueue.main.async {
                    self.updateFilteredArray()
                }
            }
        } catch {
            print("Ошибка поиска фильмов:", error)
        }
    }

}

// MARK: - UICollectionView

extension MainViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredArray.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MyCustomCell", for: indexPath) as? MyCustomCell else {
            return UICollectionViewCell()
        }

        let item = filteredArray[indexPath.item]
        cell.configure(with: item, imageBaseURL: imageBaseURL, posterSize: posterSize)
        cell.delegate = self
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.frame.width - 15) / 2
        return CGSize(width: width, height: width * 1.6)
    }
}

// MARK: - UISearchBarDelegate

extension MainViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        updateFilteredArray()

        if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            Task {
                await searchMovies(query: searchText)
            }
        }
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

// MARK: - MyCustomCellDelegate

extension MainViewController: MyCustomCellDelegate {
    func didTapLikeButton(on cell: MyCustomCell) {
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        let item = filteredArray[indexPath.item]

        do {
            try realm.write {
                item.isLiked.toggle()
            }
            updateFilteredArray()
        } catch {
            print("Ошибка при обновлении isLiked:", error)
        }
    }
}
