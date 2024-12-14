//
//  ContentView.swift
//  NetworkingDemo
//
//  Created by Tamizhselvan gurusamy on 12/8/24.
//

import SwiftUI

struct ContentView: View {
    
    
    private let service : CoinServiceProtocol
    @StateObject var viewModel : CoinsViewModel
    
    init(service: CoinServiceProtocol) {
        self._viewModel = StateObject(wrappedValue: CoinsViewModel(coinDataService: service))
        self.service = service
    }
    
    //    @EnvironmentObject var viewModel : CoinsViewModel
    var body: some View {
        NavigationStack {
            if  viewModel.isLoading {
                ProgressView()
            }else{
                List {
                    ForEach(viewModel.coins, id: \.self) { coin in
                        NavigationLink(value: coin) {
                            
                            HStack {
                                Text("\(coin.marketCapRank)")
                                    .foregroundStyle(.gray)
                                    .padding(.trailing)
                                
                                AsyncImage(url: URL(string: coin.image)){ image in
                                    
                                    image
                                        .resizable()
                                        .frame(width: 32, height: 32)
                                    
                                } placeholder : {
                                    Circle()
                                        .frame(width: 32, height: 32)
                                }
                                 
                                VStack(alignment: .leading) {
                                    Text(coin.name)
                                        .font(.headline)
                                    Text(coin.symbol)
                                }
                            }
                            .onAppear{
                                if coin == viewModel.coins.last{
                                    Task{
                                        await viewModel.fetchCoin()
                                    }
                                }
                            }
                            .font(.footnote)
                            
                        }
                        
                    }
                    
                }
                .refreshable {
                   await viewModel.refresh()
                }
                .navigationDestination(for: Coin.self) { coin in
                    CoinDetailView(coin: coin, service: service)
                    
                    //                    For EnvironmentObject Architecture Purpose
                    //                    CoinDetailView(coin: coin)
                }
                .navigationTitle(Text("All Coins"))
                .overlay {
                    if let errorMessage =
                        viewModel.errorMessage {
                    ZStack{
                        
                        Rectangle()
                            .fill(Color.black.opacity(0.7))
                            .frame(maxWidth: 350, maxHeight: 200)
                            .clipShape(.rect(cornerRadius: 20))
                    
                        VStack{
                            Text(errorMessage)
                                  .font(.callout)
                                  .fontWeight(.semibold)
                                  .foregroundStyle(.white)
                                     .padding()
                                     .background(Color.red.opacity(0.7))
                                     .clipShape(Capsule())
                            
                            
                            Button {
                                viewModel.errorMessage = nil
                            } label: {
                                Text("OK")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color.white)
                                    .padding(.horizontal,15)
                                    .padding(.vertical,7)
                                    .background(Color.gray)
                                    .clipShape(.rect(cornerRadius: 10))
                            }

                        }
                     }
                            
                    }
                }
                
            }
        }
        .task {
            await viewModel.fetchCoin()
        }
    }
}


#Preview {
    ContentView(service: MockCoinService())
}
