//
//  NetworkManager.swift
//  Diary
//
//  Copyright (c) 2023 woong, jeremy All rights reserved.
    

import Foundation

struct NetworkManager {
    
    func requestData<T: Decodable>(url: URL,
                                   type: T.Type,
                                   handler: @escaping (Result<T, NetworkError>) -> Void) {
        let urlSession = URLSession(configuration: .default)
        let request = URLRequest(url: url)
        let task = urlSession.dataTask(with: request) { data, response, error in
            if let error = error {
                handler(.failure(.transportFailed(error: error.localizedDescription)))
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode)
            else {
                handler(.failure(.invalidResponse))
                return
            }
            
            guard let data = data else {
                handler(.failure(.dataNotFound))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let decodedData = try decoder.decode(type,
                                                     from: data)
                handler(.success(decodedData))
            } catch {
                handler(.failure(.decodeFailed))
            }
        }
        task.resume()
    }
}
