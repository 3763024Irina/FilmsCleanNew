//
//  ImageInfo.swift
//  FilmsApp
//
//  Created by Irina on 18/6/25.
//

import Foundation
struct ImageInfo {
    let filePath: String
    let size: ImageSize
    
    enum ImageSize: String {
        case w342
        case w500
        case w780
        case original
    }
}
