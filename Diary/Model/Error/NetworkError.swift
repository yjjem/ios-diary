//
//  NetworkError.swift
//  Diary
//
//  Copyright (c) 2023 woong, jeremy All rights reserved.
    
enum NetworkError: Error {
    case transportFailed(error: String)
    case dataNotFound
    case invalidResponse
    case decodeFailed
}
