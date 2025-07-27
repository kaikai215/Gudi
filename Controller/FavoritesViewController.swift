//
//  FavoritesViewController.swift
//  Gudi
//
//  Created by 林聖凱 on 2025/7/22.
//

import UIKit

class FavoritesViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    let favoriteService = FavoriteService()   //從 Firebase 抓「最愛股票代碼」
    let stockService = StockService()         //從 API 抓「所有股票資料」

    var favoriteCodes: [String] = []          // 儲存最愛代碼
    var allStocks: [StockViewModel] = []      // 所有股票資料
    var favoriteStocks: [StockViewModel] = [] // 篩選後的最愛股票資料

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        loadData()
    }
    
    //載入 Firebase + 股票資料  用.filter 篩出有加進最愛的股票
    private func loadData() {
        //抓目前登入者的最愛代碼
        favoriteService.getFavorites { [weak self] codes in
            guard let self = self else { return }
            self.favoriteCodes = codes
            
            //再抓所有股票資料
            self.stockService.fetchAllStocks { stocks in
                guard let stocks = stocks else { return }
                self.allStocks = stocks
                //用 .filter 篩出有加進最愛的股票
                self.favoriteStocks = stocks.filter { self.favoriteCodes.contains($0.code) }

                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }
    }
    //頁面每次出現時重新載入資料
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData()
    }
    //跳轉到詳情頁
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toDetail",
           let detailVC = segue.destination as? StockDetailViewController,
           let indexPath = tableView.indexPathForSelectedRow {
            let selectedStock = favoriteStocks[indexPath.row]
            detailVC.stock = selectedStock
        }
    }
}

// MARK: - TableView DataSource & Delegate

extension FavoritesViewController: UITableViewDataSource, UITableViewDelegate {
    //顯示最愛股票的數量
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return favoriteStocks.count
    }
    //每一列股票要呈現的內容
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "StockCell", for: indexPath) as? StockTableViewCell else {
            return UITableViewCell()
        }

        let stock = favoriteStocks[indexPath.row]
        cell.nameLabel.text = stock.name
        cell.closingPriceLabel.text = formatToTwoDecimal(stock.closingPrice)
        cell.changeLabel.text = formatToTwoDecimal(stock.change)
        cell.tradeVolumeLabel.text = formatTradeVolume(stock.tradeVolume)

        
        // ✅ 漲跌幅顏色設定
        let change = Double(stock.change.replacingOccurrences(of: ",", with: "")) ?? 0
        if change > 0 {
            cell.changeLabel.textColor = .red
        } else if change < 0 {
            cell.changeLabel.textColor = .green
        } else {
            cell.changeLabel.textColor = .gray
        }

        // ✅ 星星圖示設定
        let isFavorited = favoriteCodes.contains(stock.code)
        cell.favoriteButton?.setImage(UIImage(systemName: isFavorited ? "star.fill" : "star"), for: .normal)
        cell.favoriteButton?.isUserInteractionEnabled = false

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // 使用 Storyboard segue
        tableView.deselectRow(at: indexPath, animated: true)
    }
    //把交易股數換算成「張」
    private func formatTradeVolume(_ volumeStr: String) -> String {
        let clean = volumeStr.replacingOccurrences(of: ",", with: "")
        guard let volume = Double(clean) else { return volumeStr }

        let lots = floor(volume / 1000)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0

        return "\(formatter.string(from: NSNumber(value: lots)) ?? "0") 張"
    }
    //把數字轉成小數點兩位
    private func formatToTwoDecimal(_ str: String) -> String {
        if let value = Double(str.replacingOccurrences(of: ",", with: "")) {
            return String(format: "%.2f", value)
        } else {
            return str
        }
    }

}
