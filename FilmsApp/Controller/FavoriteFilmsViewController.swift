//
//  FavoriteFilmsViewController.swift
//  FilmsApp
//
//  Created by Kirill Timanovsky on 29.07.2021.
//
import UIKit

class LikedFilmsViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    var likedFilms: [Item] = []
    private let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Liked Films"

        setupCollectionView()
    }

    private func setupCollectionView() {
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)

        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .white

        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 20, left: 10, bottom: 20, right: 10)
        layout.scrollDirection = .vertical
        collectionView.setCollectionViewLayout(layout, animated: false)

        let nib = UINib(nibName: "MyCustomCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: "MyCustomCell")

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return likedFilms.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MyCustomCell", for: indexPath) as? MyCustomCell else {
            return UICollectionViewCell()
        }

        let item = likedFilms[indexPath.item]
        cell.configure(with: item, isImageOnly: false)

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let layout = collectionViewLayout as! UICollectionViewFlowLayout
        let insets = layout.sectionInset
        let spacing = layout.minimumInteritemSpacing
        let totalSpacing = insets.left + insets.right + spacing
        let itemWidth = (collectionView.frame.width - totalSpacing) / 2
        return CGSize(width: itemWidth, height: 250)
    }
}
