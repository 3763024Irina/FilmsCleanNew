import UIKit

class MainViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, MyCustomCellDelegate {

    private var testArray: [Item] = []
    private var filteredArray: [Item] = []
    private var isFiltering: Bool = false
    private var showingOnlyLiked: Bool = false
    private var selectedStartPoint: CGPoint = .zero

    private let model = Model()

    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 20, left: 10, bottom: 20, right: 10)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .white
        return collectionView
    }()

    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.placeholder = "Search films"
        return searchBar
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        navigationController?.navigationBar.isHidden = false
        title = "Films"

        // Данные
        testArray = model.testArray
        filteredArray = testArray

        setupSearchBar()
        setupCollectionView()

        // Кнопка-сердечко
        let heartButton = UIBarButtonItem(
            image: UIImage(systemName: "heart.fill"),
            style: .plain,
            target: self,
            action: #selector(showLikedMovies)
        )
        navigationItem.rightBarButtonItem = heartButton
    }

    @objc func showLikedMovies() {
        let likedVC = LikedFilmsViewController()
        likedVC.likedFilms = testArray.filter { $0.isLiked }
        navigationController?.pushViewController(likedVC, animated: true)
    }


    private func setupSearchBar() {
        searchBar.delegate = self
        view.addSubview(searchBar)

        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self

        let nib = UINib(nibName: "MyCustomCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: "MyCustomCell")

        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - UICollectionViewDataSource, Delegate & FlowLayout

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return isFiltering ? filteredArray.count : testArray.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MyCustomCell", for: indexPath) as? MyCustomCell else {
            return UICollectionViewCell()
        }

        let item = isFiltering ? filteredArray[indexPath.item] : testArray[indexPath.item]
        _ = indexPath.item == 0
        cell.configure(with: item, isImageOnly: false)
        cell.delegate = self

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedFilm = isFiltering ? filteredArray[indexPath.item] : testArray[indexPath.item]

        let detailVC = DetailFilmViewController()
        detailVC.film = selectedFilm

        if let cell = collectionView.cellForItem(at: indexPath) {
            let center = cell.center
            selectedStartPoint = collectionView.convert(center, to: view)
        }

        detailVC.start = selectedStartPoint
        detailVC.modalPresentationStyle = .custom
        detailVC.transitioningDelegate = self
        present(detailVC, animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let layout = collectionViewLayout as! UICollectionViewFlowLayout
        let insets = layout.sectionInset
        let spacing = layout.minimumInteritemSpacing
        let totalSpacing = insets.left + insets.right + spacing
        let itemWidth = (collectionView.frame.width - totalSpacing) / 2
        return CGSize(width: itemWidth, height: 250)
    }

    // MARK: - MyCustomCellDelegate

    func didDoubleTapPoster(for item: Item, startPoint: CGPoint) {
        guard let index = testArray.firstIndex(where: { $0.id == item.id }) else { return }
        testArray[index].isLiked.toggle()

        if isFiltering {
            filteredArray = testArray.filter { $0.isLiked }
        }

        let indexPath = IndexPath(item: index, section: 0)
        collectionView.reloadItems(at: [indexPath])

        let fullscreenVC = ImageFullscreenViewController()
        fullscreenVC.image = UIImage(named: item.testPic ?? "") ?? UIImage(named: "placeholder")
        fullscreenVC.startPoint = startPoint
        selectedStartPoint = startPoint

        fullscreenVC.modalPresentationStyle = .custom
        fullscreenVC.transitioningDelegate = self
        present(fullscreenVC, animated: true)
    }

    func didTapLikeButton(for item: Item) {
        guard let index = testArray.firstIndex(where: { $0.id == item.id }) else { return }
        testArray[index].isLiked.toggle()

        if isFiltering {
            filteredArray = showingOnlyLiked
                ? testArray.filter { $0.isLiked }
                : testArray
        }

        let indexPath = IndexPath(item: index, section: 0)
        collectionView.reloadItems(at: [indexPath])
    }
}

// MARK: - UISearchBarDelegate
extension MainViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        isFiltering = !searchText.isEmpty || showingOnlyLiked

        if showingOnlyLiked {
            filteredArray = testArray.filter {
                $0.isLiked && ($0.testTitle?.lowercased().contains(searchText.lowercased()) ?? false)
            }
        } else if !searchText.isEmpty {
            filteredArray = testArray.filter {
                $0.testTitle?.lowercased().contains(searchText.lowercased()) ?? false
            }
        } else {
            filteredArray = testArray
        }

        collectionView.reloadData()
    }
}

// MARK: - UIViewControllerTransitioningDelegate
extension MainViewController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let transition = RoundingTransition()
        transition.transitionProfile = .show
        transition.start = selectedStartPoint
        return transition
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let transition = RoundingTransition()
        transition.transitionProfile = .pop
        transition.start = selectedStartPoint
        return transition
    }
}
