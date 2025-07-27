//  StockDailyRecord.swift
//  Gudi

import Foundation

// 回應資料格式
struct StockHistoryResponse: Codable {
    let stat: String
    let data: [[String]]?
}

// 每日歷史紀錄
struct StockDailyRecord {
    let date: String
    let open: String
    let high: String
    let low: String
    let close: String

    init?(from array: [String]) {
        guard array.count >= 7 else { return nil }

        // 轉換民國年到西元年格式：114/06/29 → 2025/06/29
        let rocDate = array[0]
        let parts = rocDate.split(separator: "/")
        if parts.count == 3,
           let rocYear = Int(parts[0]),
           let month = Int(parts[1]),
           let day = Int(parts[2]) {
            let year = rocYear + 1911
            self.date = String(format: "%04d/%02d/%02d", year, month, day)
        } else {
            self.date = rocDate
        }

        self.open = array[3]
        self.high = array[4]
        self.low = array[5]
        self.close = array[6]
    }
}
