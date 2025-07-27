//
//  StockService.swift
//  Gudi
//
//  Created by 林聖凱 on 2025/6/26.
//

import Foundation

class StockService {
    
    //@escaping 表示 closure會在這個函數結束後才被執行，因為網路請求是非同步的
    //([StockViewModel]?) -> Void 表示完成後會回傳一個StockViewModel 物件的陣列
    func fetchAllStocks(completion: @escaping ([StockViewModel]?) -> Void) {
        let urlString = "https://openapi.twse.com.tw/v1/exchangeReport/STOCK_DAY_ALL"
        
        guard let url = URL(string: urlString) else {
            print("無效的 URL")
            completion(nil)
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            // 1. 檢查錯誤
            if let error = error {
                print("網路錯誤: \(error)")
                completion(nil)
                return
            }
            // 2. 檢查資料是否存在
            guard let data = data else {
                print("沒有接收到資料")
                completion(nil)
                return
            }
            
            do {
                // 3. 嘗試解碼 將 API 傳回來的 JSON 陣列資料轉成 StockViewModel 型別的陣列
                let decoder = JSONDecoder()
                let stocks = try decoder.decode([StockViewModel].self, from: data)
                
                // 4. 回傳資料 將結果傳回主執行緒
                DispatchQueue.main.async {
                    completion(stocks)
                }
            } catch {
                print("解碼失敗: \(error)")
                completion(nil)
            }
        }
        
        task.resume()
    }
    
    func fetchStockHistory(for stockCode: String, date: String, completion: @escaping ([StockDailyRecord]?) -> Void) {
            let urlStr = "https://www.twse.com.tw/exchangeReport/STOCK_DAY?response=json&date=\(date)&stockNo=\(stockCode)"
            guard let url = URL(string: urlStr) else {
                print("無效的 URL")
                completion(nil)
                return
            }

            URLSession.shared.dataTask(with: url) { data, response, error in
                if let error = error {
                    print("請求失敗: \(error)")
                    completion(nil)
                    return
                }

                guard let data = data else {
                    print("無資料")
                    completion(nil)
                    return
                }

                do {
                    let decoder = JSONDecoder()
                    let response = try decoder.decode(StockHistoryResponse.self, from: data)
                    //確認 API 回傳的狀態是「OK」
                    guard response.stat == "OK", let dataArray = response.data else {
                        print("API 回傳錯誤訊息: \(response.stat)")
                        completion(nil)
                        return
                    }

                    let records = dataArray.compactMap { StockDailyRecord(from: $0) }
                    completion(records)
                } catch {
                    print("❌ 歷史資料解碼失敗: \(error)")
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("收到的資料: \(jsonString)")
                    }
                    completion(nil)
                }
            }.resume()
        }
}
