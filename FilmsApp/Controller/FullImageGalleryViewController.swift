import UIKit

class FullImageGalleryViewController: UIViewController {
    // Массив путей к изображениям, который передается извне
    var images: [String] = []
    var movieId: Int?
    var startingIndex: Int = 0
    
    // Внутренний массив, который используется для отображения
    private var imagePaths: [String] = []
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        layout.minimumLineSpacing = 8
        layout.minimumInteritemSpacing = 8
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.delegate = self
        cv.dataSource = self
        cv.register(ImageCell.self, forCellWithReuseIdentifier: ImageCell.identifier)
        cv.backgroundColor = .white
        cv.isScrollEnabled = true
        return cv
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        title = NSLocalizedString("Gallery", comment: "Заголовок экрана галереи")
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: NSLocalizedString("Close", comment: "Закрыть галерею"),
            style: .plain,
            target: self,
            action: #selector(closeTapped)
        )
        
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        if !images.isEmpty {
            self.imagePaths = images
            collectionView.reloadData()
            DispatchQueue.main.async {
                let indexPath = IndexPath(item: self.startingIndex, section: 0)
                self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
            }
        } else if let id = movieId {
            // Открываем галерею сразу, а загрузку делаем асинхронно
            collectionView.reloadData() // покажет пустой список или индикатор
            fetchImages(for: id)
        }
    }

    
    @objc private func closeTapped() {
        if let nav = navigationController, nav.viewControllers.first != self {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    private func fetchImages(for movieId: Int) {
        let apiKey = "ab3776f359fcef3b2030735ceea2eeaf"
        let urlString = "https://api.themoviedb.org/3/movie/\(movieId)/images?api_key=\(apiKey)"
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard
                let self = self,
                error == nil,
                let data = data,
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let backdrops = json["backdrops"] as? [[String: Any]]
            else {
                print("❌ Ошибка загрузки изображений")
                return
            }
            
            // Добавляем базовый путь
            let baseURL = "https://image.tmdb.org/t/p/w780"
            self.imagePaths = backdrops.compactMap {
                if let path = $0["file_path"] as? String {
                    return baseURL + path
                }
                return nil
            }
            
            print("✅ Загружено изображений: \(self.imagePaths.count)")
            print("📷 Первый путь: \(self.imagePaths.first ?? "nil")")
            
            DispatchQueue.main.async {
                self.collectionView.reloadData()
                if self.startingIndex < self.imagePaths.count {
                    let indexPath = IndexPath(item: self.startingIndex, section: 0)
                    self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
                }
            }
        }.resume()
    }
}

extension FullImageGalleryViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imagePaths.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageCell.identifier, for: indexPath) as? ImageCell
        else {
            return UICollectionViewCell()
        }
        
        let path = imagePaths[indexPath.item]
        cell.imageView.image = nil
        cell.activityIndicator.startAnimating()
        
        ImageLoader.shared.loadImage(from: path) { image, error in
            DispatchQueue.main.async {
                if let image = image {
                    cell.imageView.image = image
                } else {
                    cell.imageView.image = UIImage(named: "placeholder")
                }
                cell.activityIndicator.stopAnimating()
            }
        }
        
        return cell
    }
}

extension FullImageGalleryViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding: CGFloat = 8
        let itemsPerRow: CGFloat = 3
        let totalSpacing = padding * (itemsPerRow + 1)
        let width = (collectionView.bounds.width - totalSpacing) / itemsPerRow
        return CGSize(width: width, height: width * 1.5)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }
}

class ImageCell: UICollectionViewCell {
    static let identifier = "ImageCell"

    let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 8
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    let activityIndicator: UIActivityIndicatorView = {
        let ai = UIActivityIndicatorView(style: .large)
        ai.translatesAutoresizingMaskIntoConstraints = false
        ai.hidesWhenStopped = true
        return ai
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        contentView.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
