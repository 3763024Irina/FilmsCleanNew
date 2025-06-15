//
//  enum MovieCategory.swift
//  FilmsApp
//
//  Created by Irina on 15/6/25.
//
import Foundation

enum MovieCategory: Int, CaseIterable {
    case popular = 0
    case nowPlaying
    case topRated
    case upcoming

    private var apiKey: String {
        return "ab3776f359fcef3b2030735ceea2eeaf"
    }

    private var language: String {
        return "ru-RU"
    }

    var urlString: String {
        let base = "https://api.themoviedb.org/3/movie/"
        let endpoint: String
        switch self {
        case .popular: endpoint = "popular"
        case .nowPlaying: endpoint = "now_playing"
        case .topRated: endpoint = "top_rated"
        case .upcoming: endpoint = "upcoming"
        }
        return "\(base)\(endpoint)?api_key=\(apiKey)&language=\(language)&page=1"
    }

    var title: String {
        switch self {
        case .popular: return "Популярные"
        case .nowPlaying: return "Сейчас"
        case .topRated: return "Оценённые"
        case .upcoming: return "Скоро"
        }
    }
}
