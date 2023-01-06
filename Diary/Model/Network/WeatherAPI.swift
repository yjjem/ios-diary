//
//  WeatherAPI.swift
//  Diary
//
//  Created by 서현웅 on 2023/01/06.
//

import Foundation

enum WeatherAPI {
    static let host: String = "https://api.openweathermap.org/"
    static let path: String = "data/2.5/weather"
    static let query: String = "?lat=37.785834&lon=-122.406417"
    static let apiKey: String = "&appid=44aea5632c5f4c27d89bbe765acbed69"
}
