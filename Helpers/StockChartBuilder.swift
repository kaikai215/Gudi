import Charts
import DGCharts
import UIKit

//建立股票的折線圖資料
struct StockChartBuilder {

    private static let tealColor = NSUIColor(red: 0.22, green: 0.55, blue: 0.53, alpha: 1)

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

        // 折線：主色、較粗、圓滑
        dataSet.lineWidth = 2.5
        dataSet.colors = [tealColor]
        dataSet.mode = .cubicBezier
        dataSet.drawCirclesEnabled = true
        dataSet.circleRadius = 5
        dataSet.circleHoleRadius = 2
        dataSet.circleHoleColor = .white
        dataSet.valueFont = .systemFont(ofSize: 10, weight: .medium)
        dataSet.valueFormatter = DefaultValueFormatter(decimals: 2)

        // x軸標籤
        for record in records {
            xLabels.append(formatDateString(record.date))
        }

        // 依序設定每個點的顏色（漲紅跌綠，與 App 一致）
        var circleColors: [NSUIColor] = []
        for i in 0..<closes.count {
            if i == 0 {
                circleColors.append(tealColor)
            } else {
                if closes[i] > closes[i - 1] {
                    circleColors.append(NSUIColor(red: 0.9, green: 0.25, blue: 0.22, alpha: 1))   // 漲 → 紅
                } else if closes[i] < closes[i - 1] {
                    circleColors.append(NSUIColor(red: 0.18, green: 0.6, blue: 0.35, alpha: 1))  // 跌 → 綠
                } else {
                    circleColors.append(NSUIColor(red: 0.55, green: 0.55, blue: 0.58, alpha: 1)) // 平 → 灰
                }
            }
        }
        dataSet.circleColors = circleColors

        let lineChartData = LineChartData(dataSet: dataSet)
        return (lineChartData, xLabels)
    }

    /// 將 "2025/06/29" 或 "20240601" 轉成簡短 "6/29" 避免 X 軸重疊
    private static func formatDateString(_ raw: String) -> String {
        // API 格式 "2025/06/29"
        if raw.contains("/"), let slashIdx = raw.firstIndex(of: "/") {
            let afterFirst = raw[raw.index(after: slashIdx)...]
            if let secondSlash = afterFirst.firstIndex(of: "/") {
                let month = String(raw[raw.index(after: slashIdx)..<secondSlash])
                let day = String(afterFirst[afterFirst.index(after: secondSlash)...])
                return "\(Int(month) ?? 0)/\(Int(day) ?? 0)"
            }
        }
        // 舊格式 "20240601"
        if raw.count == 8 {
            let m = Int(raw.dropFirst(4).prefix(2)) ?? 0
            let d = Int(raw.dropFirst(6)) ?? 0
            return "\(m)/\(d)"
        }
        return raw
    }
}
