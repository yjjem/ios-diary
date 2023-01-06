//
//  WeatherAPI.swift
//  Diary
//
//  Created by 서현웅 on 2023/01/06.
//

import Foundation

enum WeatherAPI {
    static let schema: String = "https"
    static let host: String = "api.openweathermap.org"
    static let apiKey: String = "44aea5632c5f4c27d89bbe765acbed69"
}

enum Scale {
    case x1
    case x2
    case x3
    
    var value: String {
        switch self {
        case .x1:
            return "1x"
        case .x2:
            return "2x"
        case .x3:
            return "3x"
        }
    }
}

enum NetworkURL {
    case weatherData(latitude: String, longitude: String)
    case imageData(imageName: String, scale: Scale)
    
    private var baseURL: URLComponents {
        var components = URLComponents()
        components.scheme = WeatherAPI.schema
        components.host = WeatherAPI.host
        return components
    }
    
    var url: URL? {
        switch self {
        case .weatherData(let latitude, let longitude):
            var components = self.baseURL
            let queryItems = [URLQueryItem(name: "lat", value: latitude),
                              URLQueryItem(name: "lon", value: longitude),
                              URLQueryItem(name: "appid", value: WeatherAPI.apiKey)]
            components.path = "/data/2.5/weather"
            components.queryItems = queryItems
            
            return components.url
        case .imageData(let name, let scale):
            var components = self.baseURL
            components.path = "/img/wn/\(name)@\(scale.value).png"
            
            return components.url
        }
    }
}
