//
//  MovieResponseParsingTests.swift
//  FilmsAppTests
//
//  Created by Irina on 1/7/25.
//
//Тест    Проверяет
//testDecodeMovieResponseSuccess    Всё корректно декодируется из полного JSON
//testDecodeMovieResponseMissingFields    Ошибка, если обязательные поля отсутствуют
//testDecodeMovieResponseOptionalPosterPath    poster_path: null корректно парсится в nil
import Foundation
import XCTest
@testable import FilmsApp

final class MovieResponseParsingTests: XCTestCase {

    func testDecodeMovieResponseSuccess() throws {
        let json = """
        {
          "results": [
            {
              "id": 101,
              "title": "Interstellar",
              "release_date": "2014-11-07",
              "vote_average": 8.6,
              "poster_path": "/poster.jpg"
            }
          ]
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(MovieResponse.self, from: json)
        XCTAssertEqual(response.results.count, 1)

        let movie = response.results[0]
        XCTAssertEqual(movie.id, 101)
        XCTAssertEqual(movie.title, "Interstellar")
        XCTAssertEqual(movie.releaseDate, "2014-11-07")
        XCTAssertEqual(movie.voteAverage, 8.6)
        XCTAssertEqual(movie.posterPath, "/poster.jpg")
    }

    func testDecodeMovieResponseMissingFields() {
        let json = """
        {
          "results": [
            {
              "id": 102,
              "title": "No Vote"
              // release_date, vote_average, poster_path отсутствуют
            }
          ]
        }
        """.data(using: .utf8)!

        XCTAssertThrowsError(try JSONDecoder().decode(MovieResponse.self, from: json))
    }

    func testDecodeMovieResponseOptionalPosterPath() throws {
        let json = """
        {
          "results": [
            {
              "id": 103,
              "title": "No Poster",
              "release_date": "2020-01-01",
              "vote_average": 7.0,
              "poster_path": null
            }
          ]
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(MovieResponse.self, from: json)
        let movie = response.results[0]
        XCTAssertNil(movie.posterPath)
    }
}
