//
//  DateHelpers.swift
//  FilmsApp
//
//  Created by Irina on 1/7/25.
//
import Foundation

/// Возвращает год из строки даты "yyyy-MM-dd" или "dd-MM-yyyy".
func year(from releaseDate: String) -> Int {
  let formatter = DateFormatter()
  formatter.locale = Locale(identifier: "en_US_POSIX")

  // Пробуем формат ISO: "yyyy-MM-dd"
  formatter.dateFormat = "yyyy-MM-dd"
  if let date = formatter.date(from: releaseDate) {
    return Calendar.current.component(.year, from: date)
  }

  // Пробуем европейский: "dd-MM-yyyy"
  formatter.dateFormat = "dd-MM-yyyy"
  if let date = formatter.date(from: releaseDate) {
    return Calendar.current.component(.year, from: date)
  }

  return 0
}
