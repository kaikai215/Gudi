//
//  StockViewModel.swift
//  Gudi
//
//  Created by 林聖凱 on 2025/6/26.
//

import Foundation

struct StockViewModel: Codable {
    let date: String           // 原始格式 "1140610"
    let code: String           // 股票代號
    let name: String           // 股票名稱
    let tradeVolume: String       // 成交股數
    let tradeValue: String        // 成交金額
    let openingPrice: String   // 開盤價
    let highestPrice: String   // 最高價
    let lowestPrice: String    // 最低價
    let closingPrice: String   // 收盤價
    let change: String        // 漲跌價差
    let transaction: String       // 成交筆數
    
    enum CodingKeys: String, CodingKey {
        case date = "Date"
        case code = "Code"
        case name = "Name"
        case tradeVolume = "TradeVolume"
        case tradeValue = "TradeValue"
        case openingPrice = "OpeningPrice"
        case highestPrice = "HighestPrice"
        case lowestPrice = "LowestPrice"
        case closingPrice = "ClosingPrice"
        case change = "Change"
        case transaction = "Transaction"
    }
    
}

