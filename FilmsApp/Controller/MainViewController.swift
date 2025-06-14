import UIKit
import RealmSwift

class MainViewController: UIViewController {
    private var currentPage = 1
    private var isLoading = false
    private var hasMorePages = true

    private var realm: Realm!
    private var notificationToken: NotificationToken?

    private var testArray: Results<Item>!
    private var filteredArray: Results<Item>!

    private var collectionView: UICollectionView!
    private var searchBar: UISearchBar!
    private var activityIndicator: UIActivityIndicatorView!

    private var imageBaseURL: String = ""
    private var posterSize: String = "w780"

    private var showingLikedOnly = false

    private let apiKey = "eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiJhYjM3NzZmMzU5ZmNlZjNiMjAzMDczNWNlZWEyZWVhZiIsIm5iZiI6MTc0MzUyNTMxNy4yMjQsInN1YiI6IjY3ZWMxNWM1ZTE2YzYxZGE0NDQyYjFkNSIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.DMeofagrq7g5PKLJZxCre1RiVxScyuJcaDjIcGq8Mc8"

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        setupRealm()
        setupSearchBar()
        setupCollectionView()
        setupNavigationBar()
        setupActivityIndicator()

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
                self.showErrorAlert(message: "Realm notification error: \(error.localizedDescription)")
            }
        }
        
        Task {
            await fetchTMDbConfiguration()
            await fetchPopularMovies(page: currentPage)
        }
    }

    private func setupRealm() {
        let config = Realm.Configuration(
            schemaVersion: 3,
            migrationBlock: { migration, oldSchemaVersion in
                if oldSchemaVersion < 3 {
                    // Миграции при необходимости
                }
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

    private func setupActivityIndicator() {
        activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.hidesWhenStopped = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: activityIndicator)
    }

    @objc func showLikedMovies() {
        showingLikedOnly.toggle()
        updateFilteredArray()
    }

    private func updateFilteredArray() {
        DispatchQueue.main.async {
            if let text = self.searchBar.text, !text.isEmpty {
                if self.showingLikedOnly {
                    self.filteredArray = self.testArray.filter("isLiked == true AND testTitle CONTAINS[c] %@", text)
                } else {
                    self.filteredArray = self.testArray.filter("testTitle CONTAINS[c] %@", text)
                }
            } else {
                self.filteredArray = self.showingLikedOnly ? self.testArray.filter("isLiked == true") : self.testArray
            }
            self.collectionView.reloadData()
        }
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

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshMovies), for: .valueChanged)
        collectionView.refreshControl = refreshControl

        view.addSubview(collectionView)
    }

    @objc private func refreshMovies() {
        currentPage = 1
        hasMorePages = true
        Task {
            await fetchPopularMovies(page: currentPage)
            DispatchQueue.main.async {
                self.collectionView.refreshControl?.endRefreshing()
            }
        }
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
            DispatchQueue.main.async { self.activityIndicator.startAnimating() }

            let (data, _) = try await URLSession.shared.data(for: request)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let images = json["images"] as? [String: Any],
               let baseURL = images["secure_base_url"] as? String,
               let posterSizes = images["poster_sizes"] as? [String] {
                imageBaseURL = baseURL
                posterSize = posterSizes.contains("w780") ? "w780" : posterSizes.last ?? "w342"
            }
        } catch {
            showErrorAlert(message: "Ошибка конфигурации TMDb: \(error.localizedDescription)")
        }

        DispatchQueue.main.async { self.activityIndicator.stopAnimating() }
    }

    private func fetchPopularMovies(page: Int = 1) async {
        guard !isLoading, hasMorePages else { return }
        isLoading = true
        DispatchQueue.main.async { self.activityIndicator.startAnimating() }

        guard let url = URL(string: "https://api.themoviedb.org/3/movie/popular?language=ru-RU&page=\(page)") else {
            isLoading = false
            DispatchQueue.main.async { self.activityIndicator.stopAnimating() }
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

                if results.isEmpty {
                    hasMorePages = false
                } else {
                    try realm.write {
                        if page == 1 {
                            realm.delete(realm.objects(Item.self))
                        }
                        for movie in results {
                            let id = movie["id"] as? Int ?? 0
                            if let existing = realm.object(ofType: Item.self, forPrimaryKey: id) {
                                existing.update(from: movie)
                            } else {
                                let item = Item()
                                item.id = id
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
                    }
                    currentPage += 1
                }
                updateFilteredArray()
            }
        } catch {
            showErrorAlert(message: "Ошибка загрузки фильмов: \(error.localizedDescription)")
        }
        isLoading = false
        DispatchQueue.main.async { self.activityIndicator.stopAnimating() }
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
            DispatchQueue.main.async { self.activityIndicator.startAnimating() }

            let (data, _) = try await URLSession.shared.data(for: request)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let results = json["results"] as? [[String: Any]] {
                try realm.write {
                    for movie in results {
                        let id = movie["id"] as? Int ?? 0
                        if let existing = realm.object(ofType: Item.self, forPrimaryKey: id) {
                            existing.update(from: movie)
                        } else {
                            let item = Item()
                            item.id = id
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
                }
                updateFilteredArray()
            }
        } catch {
            showErrorAlert(message: "Ошибка поиска фильмов: \(error.localizedDescription)")
        }
        DispatchQueue.main.async { self.activityIndicator.stopAnimating() }
    }

    private func showErrorAlert(message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "ОК", style: .default))
            self.present(alert, animated: true)
        }
    }
}

// MARK: - UICollectionView

extension MainViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        filteredArray.count
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let frameHeight = scrollView.frame.size.height
        
        if offsetY > contentHeight - frameHeight * 1.5 {
            Task {
                await fetchPopularMovies(page: currentPage)
            }
        }
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
            showErrorAlert(message: "Ошибка при обновлении isLiked: \(error.localizedDescription)")
        }
    }

    func didTapCell(_ cell: MyCustomCell) {
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        let selectedFilm = filteredArray[indexPath.item]

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let detailVC = storyboard.instantiateViewController(withIdentifier: "DetailFilmViewController") as? DetailFilmViewController {
            detailVC.film = selectedFilm
            detailVC.delegate = self
            navigationController?.pushViewController(detailVC, animated: true)
        }
    }
}

// MARK: - DetailFilmViewControllerDelegate

extension MainViewController: DetailFilmViewControllerDelegate {
    func didUpdateFilm(_ film: Item) {
        for (index, item) in filteredArray.enumerated() {
            if item.id == film.id {
                collectionView.reloadItems(at: [IndexPath(item: index, section: 0)])
                break
            }
        }
    }
}
