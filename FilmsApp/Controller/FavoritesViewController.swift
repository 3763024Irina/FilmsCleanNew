import UIKit
import RealmSwift

class FavoritesViewController: UIViewController {

    private var collectionView: UICollectionView!
    private var favoriteItems: [Item] = []
    private var favoriteResults: Results<Item>?
    private var notificationToken: NotificationToken?

    private let realm: Realm = {
        let config = Realm.Configuration(
            schemaVersion: 4,
            migrationBlock: { migration, oldSchemaVersion in
                if oldSchemaVersion < 4 {
                    // миграции если нужны
                }
            }
        )
        Realm.Configuration.defaultConfiguration = config
        
        do {
            return try Realm()
        } catch {
            fatalError("❌ Ошибка инициализации Realm: \(error)")
        }
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadFavorites()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    deinit {
        notificationToken?.invalidate()
    }

    private func setupUI() {
        title = "Избранное"
        view.backgroundColor = .systemBackground

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        layout.minimumLineSpacing = 16
        layout.itemSize = CGSize(width: view.frame.width - 32, height: 240)

        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemBackground
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(MyCustomCell.self, forCellWithReuseIdentifier: "MyCustomCell")
        collectionView.delegate = self
        collectionView.dataSource = self

        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func loadFavorites() {
        favoriteResults = realm.objects(Item.self).filter("isLiked == true")
        
        // Отменяем старый наблюдатель (если был)
        notificationToken?.invalidate()
        
        // Добавляем новый наблюдатель на результаты Realm
        notificationToken = favoriteResults?.observe { [weak self] changes in
            guard let self = self else { return }
            switch changes {
            case .initial(let collection):
                self.favoriteItems = Array(collection)
                self.collectionView.reloadData()
            case .update(let collection, _, _, _):
                self.favoriteItems = Array(collection)
                self.collectionView.reloadData()
            case .error(let error):
                print("❌ Ошибка Realm: \(error)")
            }
        }
    }
}

extension FavoritesViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return favoriteItems.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MyCustomCell", for: indexPath) as? MyCustomCell else {
            return UICollectionViewCell()
        }
        let item = favoriteItems[indexPath.item]
        cell.configure(with: item)
        cell.delegate = self
        return cell
    }
}

extension FavoritesViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = favoriteItems[indexPath.item]

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let detailVC = storyboard.instantiateViewController(withIdentifier: "DetailFilmViewController") as? DetailFilmViewController {
            detailVC.film = item
            navigationController?.pushViewController(detailVC, animated: true)
        }
    }
}

extension FavoritesViewController: MyCustomCellDelegate {
    func didTapLikeButton(on cell: MyCustomCell) {
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        let item = favoriteItems[indexPath.item]
        
        do {
            try realm.write {
                item.isLiked.toggle()
            }
        } catch {
            print("❌ Ошибка при сохранении лайка: \(error)")
        }
   
    }

    func didTapCell(_ cell: MyCustomCell) {
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        let item = favoriteItems[indexPath.item]

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let detailVC = storyboard.instantiateViewController(withIdentifier: "DetailFilmViewController") as? DetailFilmViewController {
            detailVC.film = item
            navigationController?.pushViewController(detailVC, animated: true)
        }
    }
}
