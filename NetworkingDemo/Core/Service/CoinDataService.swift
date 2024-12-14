//
//  CoinDataService.swift
//  NetworkingDemo
//
//  Created by Tamizhselvan gurusamy on 12/9/24.
//

import Foundation


protocol CoinServiceProtocol{
    func fetchCoins()  async throws -> [Coin]
    
    func fetchCoinDetails(id: String) async throws -> CoinDetail?
}

class CoinDataService: CoinServiceProtocol , HTTPDataDownloader {
    
    private var baseUrlComponent: URLComponents {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.coingecko.com"
        components.path = "/api/v3/coins"
        return components
    }
    
    private var allCoinsURLString : String? {
        var components = baseUrlComponent
        
        components.path += "/markets"
        components.queryItems = [
            .init(name: "vs_currency", value: "usd"),
            .init(name: "order", value: "market_cap_desc"),
            .init(name: "per_page", value: "30"),
            .init(name: "page", value: "1"),
            .init(name: "price_change_percentage", value: "24h"),
            .init(name: "locale", value: "en")
        ]
        
        return components.url?.absoluteString
    }
    
    private func coinDetailsUrlString(id: String) -> String? {
        var components = baseUrlComponent;
        
        components.path += "/" + id
        
        components.queryItems = [
            .init(name: "localization", value: "false")
        ]
        
        return components.url?.absoluteString
    }
    
    
    func fetchCoins()  async throws -> [Coin]{
        guard let endPoint = allCoinsURLString else {
            throw CoinApiError.requestFailed(description: "Invalid URL")
        }
        return  try await fetchData(as: [Coin].self ,stringEndPoint: endPoint)
    }
    
    func fetchCoinDetails(id: String) async throws -> CoinDetail?{
        if let cache = CoinDetailCache.shared.get(forKey: id) {
            print("DEBUG: Get Data From Cache")
            return cache
        }
        guard let endPoint = coinDetailsUrlString(id: id) else {
            throw CoinApiError.requestFailed(description: "Invalid URL")
        }
        let details = try await fetchData(as: CoinDetail.self, stringEndPoint: endPoint)
        print("DEBUG: Get Data From API")
        CoinDetailCache.shared.set(details, forKey: id)
        return details
    }
    
}









// Complaetion Handler Method
extension  CoinDataService {
    
    func fetchCoinsWithCompletion(completion: @escaping(Result<[Coin]?, CoinApiError>) -> Void){
        guard let endPoint = allCoinsURLString else {
            return
        }
        
        guard let url = URL(string: endPoint) else {return}
        
        URLSession.shared.dataTask(with: url){ data, response, error in
            
            if let error = error {
                completion(.failure(.requestFailed(description: error.localizedDescription)))
                print("DEBUG: Failed to fetch \(error)")
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.requestFailed(description: "Request Failed ")))
                return
            }
            
            guard httpResponse.statusCode == 200 else {
                completion(.failure(.invalidStatusCode(statusCode: httpResponse.statusCode)))
                return
            }
            
            guard let data = data else {
                completion(.failure(.invalidData))
                return
            }
            
            do{
                let coins = try JSONDecoder().decode([Coin].self, from: data)
                
                completion(.success(coins))
                
            }catch{
                completion(.failure(.jsonParsingError))
                print("DEBUG: Error decoding data: \(error)")
            }
            
            
            
        }
        .resume()
        
    }
    
    func fetchPrice(completion: @escaping(Double) -> Void) {
        
        
        let urlString = "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=inr"
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            
            if let error = error {
                print("DEBUG: Failed with error: \(error)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return
            }
            
            guard httpResponse.statusCode == 200  else{
                return
            }
            guard let data = data else { return }
            guard let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {return}
            guard let value = jsonObject["bitcoin"] as? [String: Int] else{ return }
            
            guard let price = value["inr"] else { return }
            
            completion(Double(price))
            
        }
        .resume()
        
        
        
        
    }
}

// All Coins URL
//    private let urlString = "https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=30&page=1&price_change_percentage=24h&locale=en"


// Coin Details URL
//private let detailsUrlString = "https://api.coingecko.com/api/v3/coins/"


