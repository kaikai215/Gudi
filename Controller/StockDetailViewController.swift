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
    @IBOutlet weak var changeLabel: UILabel!
    @IBOutlet weak var openingPriceLabel: UILabel!
    @IBOutlet weak var closingPriceLabel: UILabel!
    @IBOutlet weak var tradeVolumeLabel: UILabel!
    @IBOutlet weak var tradeValueLabel: UILabel!
    @IBOutlet weak var transactionLabel: UILabel!
    @IBOutlet weak var chartSummaryLabel: UILabel!
    @IBOutlet weak var lowestPriceLabel: UILabel!
    @IBOutlet weak var highestPriceLabel: UILabel!
    @IBOutlet weak var lineChartView: LineChartView!

    private let chartLoadingIndicator = UIActivityIndicatorView(style: .medium)
    private let chartMessageLabel: UILabel = {
        let l = UILabel()
        l.textAlignment = .center
        l.font = .systemFont(ofSize: 15, weight: .medium)
        l.textColor = UIColor(red: 0.45, green: 0.47, blue: 0.52, alpha: 1)
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    var stock: StockViewModel?
    let stockService = StockService()
    let favoriteService = FavoriteService()
    var isFavorited: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupChartOverlay()
        loadStockHistory()
    }

    private func setupUI() {
        guard let stock = stock else { return }
        stockNameLabel.text = stock.name
        stockCodeLabel.text = stock.code
        dateLabel.text = formatDate(stock.date)
        setDetailLabel(openingPriceLabel, title: "開盤價", value: stock.openingPrice)
        setDetailLabel(closingPriceLabel, title: "收盤價", value: stock.closingPrice)
        setDetailLabel(lowestPriceLabel, title: "最低價", value: stock.lowestPrice)
        setDetailLabel(highestPriceLabel, title: "最高價", value: stock.highestPrice)
        setDetailLabel(tradeVolumeLabel, title: "成交量", value: formatToLots(stock.tradeVolume))
        setDetailLabel(transactionLabel, title: "成交筆數", value: formatTransaction(stock.transaction))
        setDetailLabel(tradeValueLabel, title: "成交金額", value: formatTradeValue(stock.tradeValue))

        // 漲跌與漲跌幅
        let changeStr = formatToTwoDecimal(stock.change)
        let changeVal = Double(stock.change.replacingOccurrences(of: ",", with: "")) ?? 0
        let closeVal = Double(stock.closingPrice.replacingOccurrences(of: ",", with: "")) ?? 0
        let prevClose = closeVal - changeVal
        let percentStr = prevClose != 0 ? String(format: "%.2f", changeVal / prevClose * 100) : "0.00"
        let sign = changeVal >= 0 ? "+" : ""
        changeLabel.text = "漲跌：\(sign)\(changeStr) (\(sign)\(percentStr)%)"
        changeLabel.textColor = changeVal > 0 ? UIColor(red: 0.9, green: 0.25, blue: 0.22, alpha: 1)
            : (changeVal < 0 ? UIColor(red: 0.18, green: 0.6, blue: 0.35, alpha: 1)
            : UIColor(red: 0.55, green: 0.55, blue: 0.58, alpha: 1))

        // 導航列右側收藏按鈕
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "star"),
            style: .plain,
            target: self,
            action: #selector(favoriteButtonTapped)
        )
        navigationItem.rightBarButtonItem?.tintColor = UIColor(red: 0.22, green: 0.55, blue: 0.53, alpha: 1)
        updateFavoriteButton()
        

        // 圖表樣式：與 App 主色一致
        lineChartView.chartDescription.enabled = true
        lineChartView.chartDescription.text = "本月股價走勢"
        lineChartView.chartDescription.font = .systemFont(ofSize: 12, weight: .medium)
        lineChartView.chartDescription.textColor = UIColor(red: 0.45, green: 0.47, blue: 0.52, alpha: 1)

        lineChartView.xAxis.labelPosition = .bottom
        lineChartView.xAxis.labelFont = .systemFont(ofSize: 11, weight: .regular)
        lineChartView.xAxis.labelTextColor = UIColor(red: 0.45, green: 0.47, blue: 0.52, alpha: 1)
        lineChartView.xAxis.gridColor = UIColor(red: 0.92, green: 0.93, blue: 0.95, alpha: 1)
        lineChartView.xAxis.axisLineColor = UIColor(red: 0.9, green: 0.91, blue: 0.93, alpha: 1)

        lineChartView.leftAxis.labelFont = .systemFont(ofSize: 11, weight: .regular)
        lineChartView.leftAxis.labelTextColor = UIColor(red: 0.45, green: 0.47, blue: 0.52, alpha: 1)
        lineChartView.leftAxis.gridColor = UIColor(red: 0.92, green: 0.93, blue: 0.95, alpha: 1)
        lineChartView.leftAxis.axisLineColor = .clear
        lineChartView.leftAxis.drawZeroLineEnabled = false

        lineChartView.rightAxis.enabled = false
        lineChartView.legend.enabled = true
        lineChartView.legend.font = .systemFont(ofSize: 12, weight: .medium)
        lineChartView.legend.textColor = UIColor(red: 0.35, green: 0.38, blue: 0.44, alpha: 1)
        lineChartView.legend.orientation = .horizontal
        lineChartView.legend.horizontalAlignment = .left
        lineChartView.legend.verticalAlignment = .top
        lineChartView.legend.form = .circle
        lineChartView.legend.formSize = 8
        lineChartView.legend.xOffset = 8
        lineChartView.extraBottomOffset = 28

        // 啟用左右滑動與縮放
        lineChartView.dragEnabled = true
        lineChartView.setScaleEnabled(true)
        lineChartView.scaleXEnabled = true
        lineChartView.scaleYEnabled = false
        lineChartView.pinchZoomEnabled = true

        lineChartView.animate(xAxisDuration: 0.8, yAxisDuration: 0.8)
    }

    private func setupChartOverlay() {
        chartLoadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        chartLoadingIndicator.hidesWhenStopped = true
        chartLoadingIndicator.color = UIColor(red: 0.45, green: 0.47, blue: 0.52, alpha: 1)
        view.addSubview(chartLoadingIndicator)
        view.addSubview(chartMessageLabel)
        NSLayoutConstraint.activate([
            chartLoadingIndicator.centerXAnchor.constraint(equalTo: lineChartView.centerXAnchor),
            chartLoadingIndicator.centerYAnchor.constraint(equalTo: lineChartView.centerYAnchor),
            chartMessageLabel.centerXAnchor.constraint(equalTo: lineChartView.centerXAnchor),
            chartMessageLabel.centerYAnchor.constraint(equalTo: lineChartView.centerYAnchor),
            chartMessageLabel.leadingAnchor.constraint(greaterThanOrEqualTo: lineChartView.leadingAnchor, constant: 16),
            chartMessageLabel.trailingAnchor.constraint(lessThanOrEqualTo: lineChartView.trailingAnchor, constant: -16)
        ])
        chartMessageLabel.isHidden = true
    }

    private func showChartLoading(_ show: Bool) {
        if show {
            chartMessageLabel.isHidden = true
            chartLoadingIndicator.startAnimating()
        } else {
            chartLoadingIndicator.stopAnimating()
        }
    }

    private func showChartMessage(_ message: String) {
        chartLoadingIndicator.stopAnimating()
        chartMessageLabel.text = message
        chartMessageLabel.isHidden = false
    }

    private func hideChartMessage() {
        chartMessageLabel.isHidden = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateFavoriteButton()
        navigationItem.rightBarButtonItem?.image = UIImage(systemName: isFavorited ? "star.fill" : "star")
    }

    private func updateFavoriteButton() {
        guard let code = stock?.code else { return }
        favoriteService.getFavorites { [weak self] codes in
            self?.isFavorited = codes.contains(code)
            DispatchQueue.main.async {
                self?.navigationItem.rightBarButtonItem?.image = UIImage(systemName: (self?.isFavorited ?? false) ? "star.fill" : "star")
            }
        }
    }

    @objc private func favoriteButtonTapped() {
        guard let code = stock?.code else { return }
        if isFavorited {
            favoriteService.removeFavorite(stockCode: code) { [weak self] _ in
                self?.isFavorited = false
                DispatchQueue.main.async {
                    self?.navigationItem.rightBarButtonItem?.image = UIImage(systemName: "star")
                }
            }
        } else {
            favoriteService.addFavorite(stockCode: code) { [weak self] _ in
                self?.isFavorited = true
                DispatchQueue.main.async {
                    self?.navigationItem.rightBarButtonItem?.image = UIImage(systemName: "star.fill")
                }
            }
        }
    }

    private func setDetailLabel(_ label: UILabel, title: String, value: String) {
        let gray = UIColor(red: 0.45, green: 0.47, blue: 0.52, alpha: 1)
        let dark = UIColor(red: 0.2, green: 0.22, blue: 0.28, alpha: 1)
        let titleAttr = NSAttributedString(
            string: "\(title)：",
            attributes: [.font: UIFont.systemFont(ofSize: 15, weight: .regular), .foregroundColor: gray]
        )
        let valueAttr = NSAttributedString(
            string: value,
            attributes: [.font: UIFont.systemFont(ofSize: 15, weight: .semibold), .foregroundColor: dark]
        )
        let combined = NSMutableAttributedString(attributedString: titleAttr)
        combined.append(valueAttr)
        label.attributedText = combined
    }

    private func formatToTwoDecimal(_ str: String) -> String {
        let clean = str.replacingOccurrences(of: ",", with: "")
        if let val = Double(clean) {
            return String(format: "%.2f", val)
        }
        return str
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

    private func formatTradeValue(_ str: String) -> String {
        let digitOnly = str.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        guard let value = Double(digitOnly), value >= 0 else { return "—" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        if value >= 100_000_000 {
            let yi = value / 100_000_000
            return "\(formatter.string(from: NSNumber(value: yi)) ?? "0") 億元"
        } else if value >= 10_000 {
            let wan = value / 10_000
            return "\(formatter.string(from: NSNumber(value: wan)) ?? "0") 萬元"
        }
        return "\(formatter.string(from: NSNumber(value: value)) ?? "0") 元"
    }

    private func formatTransaction(_ str: String) -> String {
        let digitOnly = str.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        guard let num = Int(digitOnly), num >= 0 else { return "—" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: num)) ?? "—"
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

        showChartLoading(true)
        chartSummaryLabel.text = "本月最高 — / 最低 — · 區間漲跌 —"
        let dateStr = getCurrentMonthFirstDate()

        stockService.fetchStockHistory(for: stock.code, date: dateStr) { [weak self] records in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.showChartLoading(false)
            }
            if let records = records, !records.isEmpty {
                let (chartData, xLabels) = StockChartBuilder.buildLineChart(from: records)
                let summaryText = self.buildChartSummary(from: records)
                let latestDate = records.last?.date  // 圖表最後一筆日期，與 X 軸一致
                DispatchQueue.main.async {
                    self.hideChartMessage()
                    if let date = latestDate { self.dateLabel.text = date }
                    self.chartSummaryLabel.text = summaryText
                    self.lineChartView.data = chartData
                    self.lineChartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: xLabels)
                    self.lineChartView.xAxis.granularity = 1
                    self.lineChartView.xAxis.setLabelCount(5, force: true)
                    self.lineChartView.xAxis.labelRotationAngle = -25
                    self.lineChartView.notifyDataSetChanged()
                    self.lineChartView.setVisibleXRangeMaximum(6)
                    self.lineChartView.setVisibleXRangeMinimum(3)
                    self.lineChartView.moveViewToX(Double(records.count - 1))
                }
            } else {
                DispatchQueue.main.async {
                    self.showChartMessage("暫無本月走勢\n請稍後再試")
                }
            }
        }
    }

    private func buildChartSummary(from records: [StockDailyRecord]) -> String {
        let closes = records.compactMap { Double($0.close.replacingOccurrences(of: ",", with: "")) }
        guard closes.count >= 2,
              let monthHigh = closes.max(),
              let monthLow = closes.min(),
              let first = closes.first,
              let last = closes.last else {
            return "本月最高 — / 最低 — · 區間漲跌 —"
        }
        let highStr = String(format: "%.2f", monthHigh)
        let lowStr = String(format: "%.2f", monthLow)
        let rangePercent = first != 0 ? (last - first) / first * 100 : 0
        let sign = rangePercent >= 0 ? "+" : ""
        let pctStr = String(format: "%@%.2f%%", sign, rangePercent)
        return "本月最高 \(highStr) / 最低 \(lowStr) · 區間漲跌 \(pctStr)"
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
