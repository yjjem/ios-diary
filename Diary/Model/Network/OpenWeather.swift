//
//  OpenWeather.swift
//  Diary
//
//  Copyright (c) 2023 woong, jeremy All rights reserved.
    
struct OpenWeather: Decodable {
    let weather: [Weather]
}

struct Weather: Decodable {
    let main: String
    let icon: String
}
