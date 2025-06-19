import UIKit
import RealmSwift

class MainViewController: UIViewController, MyCustomCellDelegate {

    // MARK: - Properties
    private var roundingTransitionDelegate: RoundingTransitionDelegate?
    private static let imageCache = NSCache<NSString, UIImage>()

    private var segmentedControl: UISegmentedControl!
    private var selectedCategory: MovieCategory = .popular
    private var currentPage = 1
    private var isLoading = false
    private var hasMorePages = true

    private var realm: Realm!
    private var notificationToken: NotificationToken?

    private var allItems: Results<Item>!
    private var filteredItems: Results<Item>!

    private var collectionView: UICollectionView!
    private var searchBar: UISearchBar!
    private var activityIndicator: UIActivityIndicatorView!

    private var imageBaseURL: String = ""
    private var posterSize: String = "w780"

    private var showingLikedOnly = false

    private let apiKey = "ab3776f359fcef3b2030735ceea2eeaf"

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Фильмы"

        setupRealm()
        setupSegmentedControl()
        setupSearchBar()
        setupCollectionView()
        setupNavigationBar()
        setupActivityIndicator()

        // Загрузка всех элементов и установка фильтра (пока без фильтрации)
        allItems = realm.objects(Item.self).sorted(byKeyPath: "id", ascending: true)
        filteredItems = allItems

        observeRealmChanges()

        Task {
            await fetchTMDbConfiguration()
            await loadMovies(category: selectedCategory, page: currentPage)
        }
    }

    deinit {
        notificationToken?.invalidate()
    }

    // MARK: - Setup Methods

    private func setupRealm() {
        let config = Realm.Configuration(
            schemaVersion: 4,
            migrationBlock: { _, oldSchemaVersion in
                if oldSchemaVersion < 4 {
                    // Здесь можно добавить миграции Realm, если нужно
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

    private func setupSegmentedControl() {
        let items = [
            "Популярные",
            "Сейчас в кино",
            "Рейтинги",
            "Скоро"
        ]

        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 0
        control.addTarget(self, action: #selector(categoryChanged(_:)), for: .valueChanged)
        segmentedControl = control

        if let nav = navigationController {
            nav.navigationBar.isHidden = false
            navigationItem.titleView = segmentedControl
        } else {
            print("⚠️ Warning: navigationController is nil — не удалось установить titleView.")
        }
    }

    private func setupSearchBar() {
        searchBar = UISearchBar()
        searchBar.delegate = self
        searchBar.placeholder = "Поиск фильмов"
        searchBar.showsCancelButton = true
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBar)

        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            searchBar.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .white
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(MyCustomCell.self, forCellWithReuseIdentifier: "MyCustomCell")
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshMovies), for: .valueChanged)
        collectionView.refreshControl = refreshControl

        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupNavigationBar() {
        guard let navigationController = self.navigationController else { return }

        navigationController.navigationBar.isHidden = false
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

    @objc private func categoryChanged(_ sender: UISegmentedControl) {
        guard let category = MovieCategory(rawValue: sender.selectedSegmentIndex) else { return }
        selectedCategory = category
        currentPage = 1
        hasMorePages = true
        Task {
            await loadMovies(category: category, page: currentPage)
        }
    }

    @objc private func showLikedMovies() {
        showingLikedOnly.toggle()
        updateFilteredItems()
    }

    @objc private func refreshMovies() {
        currentPage = 1
        hasMorePages = true
        Task {
            await loadMovies(category: selectedCategory, page: currentPage)
            DispatchQueue.main.async {
                self.collectionView.refreshControl?.endRefreshing()
            }
        }
    }

    private func updateFilteredItems() {
        if let text = searchBar.text, !text.isEmpty {
            if showingLikedOnly {
                filteredItems = allItems.filter("isLiked == true AND testTitle CONTAINS[c] %@", text)
            } else {
                filteredItems = allItems.filter("testTitle CONTAINS[c] %@", text)
            }
        } else {
            filteredItems = showingLikedOnly ? allItems.filter("isLiked == true") : allItems
        }
        collectionView.reloadData()
    }



    private func fetchTMDbConfiguration() async {
        guard !apiKey.isEmpty else {
            print("API ключ не указан.")
            return
        }

        guard let url = URL(string: "https://api.themoviedb.org/3/configuration?api_key=\(apiKey)") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "accept")

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

    private func loadMovies(category: MovieCategory, page: Int) async {
        guard !isLoading, hasMorePages else { return }
        isLoading = true
        DispatchQueue.main.async { self.activityIndicator.startAnimating() }
        
        let urlString = category.urlString(page: page) // используем правильный URL
        
        print("Загрузка фильмов с URL: \(urlString)") // для отладки
        
        NetworkManager.shared.dataRequest(urlString: urlString) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let data):
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let results = json["results"] as? [[String: Any]] {
                        
                        DispatchQueue.main.async {
                            do {
                                try self.realm.write {
                                    if page == 1 {
                                        self.realm.delete(self.realm.objects(Item.self))
                                    }
                                    for movie in results {
                                        let id = movie["id"] as? Int ?? 0
                                        if let existing = self.realm.object(ofType: Item.self, forPrimaryKey: id) {
                                            existing.update(from: movie)
                                        } else {
                                            let item = Item()
                                            item.id = id
                                            item.update(from: movie)
                                            self.realm.add(item, update: .modified)
                                        }
                                    }
                                }
                                self.currentPage += 1
                                self.updateFilteredItems()
                            } catch {
                                self.showErrorAlert(message: "Ошибка при записи в Realm: \(error.localizedDescription)")
                            }
                            self.activityIndicator.stopAnimating()
                            self.isLoading = false
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.showErrorAlert(message: "Ошибка парсинга фильмов: \(error.localizedDescription)")
                        self.activityIndicator.stopAnimating()
                        self.isLoading = false
                    }
                }
                
            case .failure(let error):
                DispatchQueue.main.async {
                    self.showErrorAlert(message: "Ошибка загрузки фильмов: \(error.localizedDescription)")
                    self.activityIndicator.stopAnimating()
                    self.isLoading = false
                }
            }
        }
    }
    // MARK: - Alerts

    private func showErrorAlert(message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "ОК", style: .default))
            self.present(alert, animated: true)
        }
    }

    // MARK: - Realm Notifications

    private func observeRealmChanges() {
        notificationToken = allItems.observe { [weak self] changes in
            guard let self = self else { return }
            switch changes {
            case .initial:
                self.updateFilteredItems()
            case .update(_, let deletions, let insertions, let modifications):
                // Обновляем только если фильтр показывает все элементы без поиска,
                // т.к. фильтрация выполняется в updateFilteredItems.
                self.updateFilteredItems()
            case .error(let error):
                self.showErrorAlert(message: "Realm notification error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - MyCustomCellDelegate

    func didTapLikeButton(on cell: MyCustomCell) {
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        let item = filteredItems[indexPath.item]

        do {
            try realm.write {
                item.isLiked.toggle()
            }
        } catch {
            print("Ошибка записи в Realm: \(error)")
        }

        // Обновляем конкретную ячейку
        collectionView.reloadItems(at: [indexPath])
    }

    func didTapCell(_ cell: MyCustomCell) {
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        let item = filteredItems[indexPath.item]

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let detailVC = storyboard.instantiateViewController(withIdentifier: "DetailFilmViewController") as? DetailFilmViewController {
            detailVC.item = item
            detailVC.modalPresentationStyle = .custom

            let transitionDelegate = RoundingTransitionDelegate()

            // Определяем стартовую точку анимации — центр ячейки
            if let cellFrame = collectionView.layoutAttributesForItem(at: indexPath)?.frame {
                let cellRectInSuperview = collectionView.convert(cellFrame, to: collectionView.superview)
                transitionDelegate.startPoint = CGPoint(x: cellRectInSuperview.midX, y: cellRectInSuperview.midY)
            } else {
                transitionDelegate.startPoint = view.center
            }

            detailVC.transitioningDelegate = transitionDelegate

            // Сохраняем делегат, чтобы он не удалился сразу
            self.roundingTransitionDelegate = transitionDelegate

            present(detailVC, animated: true)
        }
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegateFlowLayout

extension MainViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

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
        // Используем делегат ячейки, чтобы не дублировать код:
        if let cell = collectionView.cellForItem(at: indexPath) as? MyCustomCell {
            didTapCell(cell)
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding: CGFloat = 16 // sectionInsets left+right
        let minimumInteritemSpacing: CGFloat = 8
        let numberOfItemsPerRow: CGFloat = 2

        let availableWidth = collectionView.frame.width - padding - (minimumInteritemSpacing * (numberOfItemsPerRow - 1))
        let widthPerItem = availableWidth / numberOfItemsPerRow
        let heightPerItem = widthPerItem * 1.5 // примерно пропорция постера

        return CGSize(width: widthPerItem, height: heightPerItem)
    }
}

// MARK: - UISearchBarDelegate

extension MainViewController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        updateFilteredItems()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        updateFilteredItems()
    }
}
extension MainViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let frameHeight = scrollView.frame.size.height

        if offsetY > contentHeight - frameHeight * 1.5 {
            Task {
                await loadMovies(category: selectedCategory, page: currentPage)
            }
        }
    }
}

