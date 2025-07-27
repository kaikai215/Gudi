import Charts
import DGCharts
import Foundation

//建立股票的折線圖資料
struct StockChartBuilder {
    
    /// 建立折線圖資料與對應的日期陣列，並根據漲跌變化決定顏色
    static func buildLineChart(from records: [StockDailyRecord]) -> (LineChartData, [String]) {
        var xLabels: [String] = []

        // 先解析收盤價
        let closes: [Double] = records.compactMap {
            Double($0.close.replacingOccurrences(of: ",", with: ""))
        }

        // 建立 ChartDataEntry，設定 x 為索引，y 為收盤價
        var entries: [ChartDataEntry] = []
        for (index, close) in closes.enumerated() {
            entries.append(ChartDataEntry(x: Double(index), y: close))
        }

        // 建立 DataSet
        let dataSet = LineChartDataSet(entries: entries, label: "收盤價")

        // 設定折線寬度、圓點大小
        dataSet.lineWidth = 2
        dataSet.circleRadius = 4
        dataSet.valueFont = .systemFont(ofSize: 10)
        dataSet.valueFormatter = DefaultValueFormatter(decimals: 0)

        // x軸標籤
        for record in records {
            xLabels.append(formatDateString(record.date))
        }

        // 依序設定每個點的顏色
        var circleColors: [NSUIColor] = []
        for i in 0..<closes.count {
            if i == 0 {
                circleColors.append(.systemBlue)
            } else {
                if closes[i] > closes[i - 1] {
                    circleColors.append(.systemRed)   // 漲 -> 紅色
                } else if closes[i] < closes[i - 1] {
                    circleColors.append(.systemGreen) // 跌 -> 綠色
                } else {
                    circleColors.append(.systemGray)  // 不變 -> 灰色
                }
            }
        }
        dataSet.circleColors = circleColors

        // 折線顏色
        dataSet.colors = [.systemBlue]

        let lineChartData = LineChartData(dataSet: dataSet)
        return (lineChartData, xLabels)
    }

    /// 將 "20240601" → "6/01"
    private static func formatDateString(_ raw: String) -> String {
        guard raw.count == 8 else { return raw }
        let month = String(raw.dropFirst(4).prefix(2))
        let day = String(raw.dropFirst(6))
        return "\(Int(month) ?? 0)/\(day)"
    }
}
