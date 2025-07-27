//
//  StockDetailViewController.swift
//  Gudi
//
//  Created by 林聖凱 on 2025/6/26.
//

import UIKit
import Charts
import DGCharts

class StockDetailViewController: UIViewController {
    
    @IBOutlet weak var stockCodeLabel: UILabel!
    @IBOutlet weak var stockNameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var openingPriceLabel: UILabel!
    @IBOutlet weak var closingPriceLabel: UILabel!
    @IBOutlet weak var tradeVolumeLabel: UILabel!
    @IBOutlet weak var lowestPriceLabel: UILabel!
    @IBOutlet weak var highestPriceLabel: UILabel!
   
    @IBOutlet weak var lineChartView: LineChartView!
    
    var stock: StockViewModel?
    let stockService = StockService()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadStockHistory()
    }

    private func setupUI() {
        guard let stock = stock else { return }
        stockNameLabel.text = stock.name
        stockCodeLabel.text = stock.code
        openingPriceLabel.text = "開盤價：\(stock.openingPrice)"
        closingPriceLabel.text = "收盤價：\(stock.closingPrice)"
        lowestPriceLabel.text = "最低價：\(stock.lowestPrice)"
        highestPriceLabel.text = "最高價：\(stock.highestPrice)"
        tradeVolumeLabel.text = "成交量：\(formatToLots(stock.tradeVolume))"
        dateLabel.text = formatDate(stock.date)
        

        lineChartView.chartDescription.enabled = true
        lineChartView.chartDescription.text = "本月股價走勢"
        lineChartView.xAxis.labelPosition = .bottom
        lineChartView.rightAxis.enabled = false
        lineChartView.legend.enabled = true
        lineChartView.animate(xAxisDuration: 1.0, yAxisDuration: 1.0)
    }
    
    func formatDate(_ rawDate: String) -> String {
        // 1140610 -> 2025/06/10
        if rawDate.count == 7 {
            let year = Int(rawDate.prefix(3)) ?? 0
            let fullYear = 1911 + year
            let month = rawDate.dropFirst(3).prefix(2)
            let day = rawDate.suffix(2)
            return "\(fullYear)/\(month)/\(day)"
        }
        return rawDate
    }
    func formatToLots(_ tradeVolume: String) -> String {
        // 先清除所有非數字字元（例如逗號、空白）
        let digitOnly = tradeVolume.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        guard let volume = Double(digitOnly), volume > 0 else {
            return "無資料"
        }

        let lots = volume / 1000.0
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0  // 不顯示小數點
        return "\(formatter.string(from: NSNumber(value: lots)) ?? "0") 張"
    }



    func formatNumber(_ str: String) -> String {
        let noComma = str.replacingOccurrences(of: ",", with: "")
        if let number = Int(noComma) {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            return formatter.string(from: NSNumber(value: number)) ?? str
        }
        return str
    }


    private func loadStockHistory() {
        guard let stock = stock else { return }

        let dateStr = getCurrentMonthFirstDate()

        stockService.fetchStockHistory(for: stock.code, date: dateStr) { [weak self] records in
            guard let self = self, let records = records, !records.isEmpty else {
                print("無法取得歷史資料或資料為空")
                return
            }

            let (chartData, xLabels) = StockChartBuilder.buildLineChart(from: records)

            DispatchQueue.main.async {
                self.lineChartView.data = chartData
                self.lineChartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: xLabels)
                self.lineChartView.xAxis.granularity = 1
                self.lineChartView.notifyDataSetChanged()
            }
        }
    }

    private func getCurrentMonthFirstDate() -> String {
        let calendar = Calendar.current
        let now = Date()
        if let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMdd"
            return formatter.string(from: firstDay)
        }
        return "20240101"
    }
}
