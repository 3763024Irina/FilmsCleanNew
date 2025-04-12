import UIKit

class MainViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UISearchBarDelegate {
    
    private var testArray: [TestModel] = []
    private var filteredArray: [TestModel] = []
    private var isFiltering = false
    
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 10 // Отступ между ячейками по горизонтали
        layout.minimumLineSpacing = 10 // Отступ между строками
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
        setupSearchBar()
        setupCollectionView()
    
            testArray = [
                TestModel(testPic: "image1", testTitle: "Inception", testYeah: "2010", testRating: "8.8"),
                TestModel(testPic: "image2", testTitle: "Titanic", testYeah: "1997", testRating: "7.8"),
                TestModel(testPic: "image3", testTitle: "Avatar", testYeah: "2009", testRating: "7.9"),
                TestModel(testPic: "image4", testTitle: "The Dark Knight", testYeah: "2008", testRating: "9.0"),
                TestModel(testPic: "image5", testTitle: "Forrest Gump", testYeah: "1994", testRating: "8.8"),
                TestModel(testPic: "image6", testTitle: "The Matrix", testYeah: "1999", testRating: "8.7"),
                TestModel(testPic: "image7", testTitle: "The Shawshank Redemption", testYeah: "1994", testRating: "9.3"),
                TestModel(testPic: "image8", testTitle: "Gladiator", testYeah: "2000", testRating: "8.5"),
                TestModel(testPic: "image9", testTitle: "The Godfather", testYeah: "1972", testRating: "9.2"),
                TestModel(testPic: "image10", testTitle: "The Lion King", testYeah: "1994", testRating: "8.5"),
                TestModel(testPic: "image11", testTitle: "Pulp Fiction", testYeah: "1994", testRating: "8.9"),
                TestModel(testPic: "image12", testTitle: "Fight Club", testYeah: "1999", testRating: "8.8"),
                TestModel(testPic: "image13", testTitle: "Interstellar", testYeah: "2014", testRating: "8.6")
            ]

        
        filteredArray = testArray
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
        
        // Зарегистрировать вашу кастомную ячейку
        collectionView.register(MyCustomCell.self, forCellWithReuseIdentifier: "MyCustomCell")
        
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - UICollectionView DataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return isFiltering ? filteredArray.count : testArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MyCustomCell", for: indexPath) as! MyCustomCell
        let model = isFiltering ? filteredArray[indexPath.row] : testArray[indexPath.row]
        
        if let filmTitle = model.testTitle, let releaseYear = model.testYeah, let rating = model.testRating, let posterPreview = model.testPic {
            let isImageOnly = posterPreview.isEmpty
            
            let myModel = MyCustomCell.MyModel(filmTitle: filmTitle, releaseYeah: releaseYear, rating: rating, posterPreview: posterPreview, isImageOnly: isImageOnly)
            cell.configure(with: myModel)
        }
        
        return cell
    }
    
    // MARK: - UICollectionView DelegateFlowLayout
    
    // Размеры для ячеек
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.frame.width / 2 - 15 // 50% ширины экрана минус отступ
        let height: CGFloat = 250 // Можно настроить высоту ячеек
        return CGSize(width: width, height: height)
    }
    
    // MARK: - SearchBar Delegate
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        isFiltering = !searchText.isEmpty
        
        if isFiltering {
            filteredArray = testArray.filter { model in
                return model.testTitle?.lowercased().contains(searchText.lowercased()) ?? false
            }
        } else {
            filteredArray = testArray
        }
        
        collectionView.reloadData()
    }
}
