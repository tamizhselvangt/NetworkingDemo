//
//  CoinsViewModel.swift
//  NetworkingDemo
//
//  Created by Tamizhselvan gurusamy on 12/8/24.
//

import Foundation



class CoinsViewModel: ObservableObject{
    
    
    @Published var price = ""
    @Published var errorMessage :String?
    
    @Published var coins = [Coin]()
    
    private let service  = CoinDataService()
    init(){
        fetchCoin()
    }
    
    
    func fetchCoin() {
        service.fetchCoins { result in
            DispatchQueue.main.async {
                
                switch result {
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                case .success(let coins):
                    self.coins = coins ?? []
                }

            }}
    }
    
    func fetchPrice() {
        service.fetchPrice(completion: { priceFromService in
            self.price = "\(priceFromService)"
        })
    }
    
}
