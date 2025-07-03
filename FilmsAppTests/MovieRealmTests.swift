//
//  MovieRealmTests.swift
//  FilmsAppTests
//
//  Created by Irina on 1/7/25.
//
//Тесты покажут:

//Тест    Что проверяет
//testSaveMovie    Что объект сохраняется и доступен по ID
//testUpdateMovie    Что можно изменить поле и оно обновляется
//testPreventDuplicatePrimaryKey    Что primaryKey обновляет существующий объект

import Foundation
import XCTest
import RealmSwift
@testable import FilmsApp
final class MovieRealmTests: XCTestCase {
    var realm: Realm!

    override func setUp() {
        super.setUp()
        let config = Realm.Configuration(inMemoryIdentifier: self.name)
        realm = try! Realm(configuration: config)
    }

    override func tearDown() {
        try! realm.write { realm.deleteAll() }
        realm = nil
        super.tearDown()
    }

    func testSaveMovie() {
        let movie = MovieObject()
        movie.id = 1
        movie.title = "Inception"
        movie.year = 2010

        try! realm.write {
            realm.add(movie)
        }

        let savedMovie = realm.object(ofType: MovieObject.self, forPrimaryKey: 1)
        XCTAssertNotNil(savedMovie)
        XCTAssertEqual(savedMovie?.title, "Inception")
        XCTAssertEqual(savedMovie?.year, 2010)
    }

    func testUpdateMovie() {
        let movie = MovieObject()
        movie.id = 2
        movie.title = "Old Title"
        movie.year = 2000

        try! realm.write {
            realm.add(movie)
        }

        try! realm.write {
            movie.title = "New Title"
        }

        let updated = realm.object(ofType: MovieObject.self, forPrimaryKey: 2)
        XCTAssertEqual(updated?.title, "New Title")
    }

    func testPreventDuplicatePrimaryKey() {
        let movie1 = MovieObject()
        movie1.id = 3
        movie1.title = "Movie A"

        let movie2 = MovieObject()
        movie2.id = 3
        movie2.title = "Movie B"

        try! realm.write {
            realm.add(movie1)
            realm.add(movie2, update: .modified) // или .all
        }

        let stored = realm.object(ofType: MovieObject.self, forPrimaryKey: 3)
        XCTAssertEqual(stored?.title, "Movie B") // обновился
    }
}
