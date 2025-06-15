//
//  MoviesViewController.swift
//  FilmsApp
//
//  Created by Irina on 15/6/25.
//

import Foundation
import UIKit

class MoviesViewController: UIViewController {

    private var movies: [[String: Any]] = []
    private let api = TMDbAPI()

    private let tableView = UITableView()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Фильмы Сейчас в кино"
        view.backgroundColor = .white

        setupTableView()
        loadNowPlaying()
    }

    private func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }

    private func loadNowPlaying() {
        api.fetchNowPlaying { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let json):
                    if let results = json["results"] as? [[String: Any]] {
                        self?.movies = results
                        self?.tableView.reloadData()
                    }
                case .failure(let error):
                    print("Ошибка загрузки: \(error.localizedDescription)")
                }
            }
        }
    }
}

extension MoviesViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return movies.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let movie = movies[indexPath.row]
        cell.textLabel?.text = movie["title"] as? String ?? "Без названия"
        return cell
    }
}
