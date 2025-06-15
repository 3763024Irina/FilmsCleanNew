import UIKit
import RealmSwift

class MainViewController: UIViewController, UIViewControllerTransitioningDelegate {

    // MARK: - Properties

    private let roundingTransition = RoundingTransition()
    private var transitionStartPoint: CGPoint = .zero

    private var currentPage = 1
    private var isLoading = false
    private var hasMorePages = true

    private var realm: Realm!
    private var notificationToken: NotificationToken?

    private var testArray: Results<Item>!
    private var filteredItems: Results<Item>!

    private var collectionView: UICollectionView!
    private var searchBar: UISearchBar!
    private var activityIndicator: UIActivityIndicatorView!

    private var imageBaseURL: String = ""
    private var posterSize: String = "w780"

    private var showingLikedOnly = false

    private let apiKey = "eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiJhYjM3NzZmMzU5ZmNlZjNiMjAzMDczNWNlZWEyZWVhZiIsIm5iZiI6MTc0MzUyNTMxNy4yMjQsInN1YiI6IjY3ZWMxNWM1ZTE2YzYxZGE0NDQyYjFkNSIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.DMeofagrq7g5PKLJZxCre1RiVxScyuJcaDjIcGq8Mc8"

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Фильмы"
        view.backgroundColor = .systemBackground

        setupRealm()
        setupSearchBar()
        setupCollectionView()
        setupNavigationBar()
        setupActivityIndicator()

        testArray = realm.objects(Item.self).sorted(byKeyPath: "id", ascending: true)
        filteredItems = testArray

        observeRealmChanges()

        Task {
            await fetchTMDbConfiguration()
            await fetchPopularMovies(page: currentPage)
        }
    }

    deinit {
        notificationToken?.invalidate()
    }

    // MARK: - Setup Methods

    private func setupRealm() {
        let config = Realm.Configuration(
            schemaVersion: 3,
            migrationBlock: { _, oldSchemaVersion in
                if oldSchemaVersion < 3 {
                    // Добавь миграцию при необходимости
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

    private func observeRealmChanges() {
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
    }

    private func setupNavigationBar() {
        navigationController?.navigationBar.isHidden = false
        title = "Фильмы"
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

    private func setupSearchBar() {
        searchBar = UISearchBar()
        searchBar.delegate = self
        searchBar.placeholder = "Поиск фильмов"
        navigationItem.titleView = searchBar
    }

    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)

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

    // MARK: - Actions

    @objc private func showLikedMovies() {
        showingLikedOnly.toggle()
        updateFilteredItems()
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

    // MARK: - Filtering & Updating

    private func updateFilteredItems() {
        DispatchQueue.main.async {
            if let text = self.searchBar.text, !text.isEmpty {
                if self.showingLikedOnly {
                    self.filteredItems = self.testArray.filter("isLiked == true AND testTitle CONTAINS[c] %@", text)
                } else {
                    self.filteredItems = self.testArray.filter("testTitle CONTAINS[c] %@", text)
                }
            } else {
                self.filteredItems = self.showingLikedOnly ? self.testArray.filter("isLiked == true") : self.testArray
            }
            self.collectionView.reloadData()
        }
    }

    // MARK: - Network Requests

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
                updateFilteredItems()
            }
        } catch {
            showErrorAlert(message: "Ошибка загрузки фильмов: \(error.localizedDescription)")
        }

        isLoading = false
        DispatchQueue.main.async { self.activityIndicator.stopAnimating() }
    }

    private func searchMovies(query: String) async {
        guard !query.isEmpty else {
            updateFilteredItems()
            return
        }

        DispatchQueue.main.async { self.activityIndicator.startAnimating() }

        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            DispatchQueue.main.async { self.activityIndicator.stopAnimating() }
            return
        }

        guard let url = URL(string: "https://api.themoviedb.org/3/search/movie?query=\(encodedQuery)&language=ru-RU") else {
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

                try realm.write {
                    realm.delete(realm.objects(Item.self))
                    for movie in results {
                        let id = movie["id"] as? Int ?? 0
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

                currentPage = 2
                hasMorePages = true
                updateFilteredItems()
            }
        } catch {
            showErrorAlert(message: "Ошибка поиска фильмов: \(error.localizedDescription)")
        }

        DispatchQueue.main.async { self.activityIndicator.stopAnimating() }
    }

    // MARK: - Alerts

    private func showErrorAlert(message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "ОК", style: .default))
            self.present(alert, animated: true)
        }
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, MyCustomCellDelegate

extension MainViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, MyCustomCellDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        filteredItems.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MyCustomCell", for: indexPath) as? MyCustomCell else {
            return UICollectionViewCell()
        }
        let item = filteredItems[indexPath.item]
        cell.configure(with: item, imageBaseURL: imageBaseURL, posterSize: posterSize)
        cell.delegate = self
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedItem = filteredItems[indexPath.item]
        let detailVC = DetailFilmViewController()
        detailVC.item = selectedItem
        navigationController?.pushViewController(detailVC, animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding: CGFloat = 16 // sectionInsets left+right
        let interItemSpacing: CGFloat = 8
        let availableWidth = collectionView.bounds.width - padding - interItemSpacing
        let width = availableWidth / 2
        return CGSize(width: width, height: width * 1.6)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let height = scrollView.frame.size.height

        if offsetY > contentHeight - height * 2 && !isLoading && !showingLikedOnly && (searchBar.text?.isEmpty ?? true) {
            Task {
                await fetchPopularMovies(page: currentPage)
            }
        }
    }

    // MARK: - MyCustomCellDelegate

    func didTapLikeButton(on cell: MyCustomCell) {
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        let item = filteredItems[indexPath.item]

        try? realm.write {
            item.isLiked.toggle()
        }

        if showingLikedOnly {
            updateFilteredItems()
        } else {
            collectionView.reloadItems(at: [indexPath])
        }
    }

    func didTapCell(_ cell: MyCustomCell) {
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        let selectedItem = filteredItems[indexPath.item]
        let detailVC = DetailFilmViewController()
        detailVC.item = selectedItem
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

// MARK: - UISearchBarDelegate

extension MainViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            updateFilteredItems()
        } else {
            Task {
                await searchMovies(query: searchText)
            }
        }
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        updateFilteredItems()
        searchBar.resignFirstResponder()
    }
}
