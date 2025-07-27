//
//  HomeViewController.swift
//  Gudi
//
//  Created by 林聖凱 on 2025/6/26.
//

import UIKit
import FirebaseAuth

class HomeViewController: UIViewController,UISearchBarDelegate {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var stocksTableView: UITableView!
    
    var userEmail: String?
    var allStocks: [StockViewModel] = []
    var displayedStocks: [StockViewModel] = []
    var favoriteStockCodes: Set<String> = []

    let stockService = StockService()
    let favoriteService = FavoriteService()

    override func viewDidLoad() {
        super.viewDidLoad()

        if let email = userEmail {
            welcomeLabel.text = "歡迎 \(email) 登入"
        }

        stocksTableView.dataSource = self
        stocksTableView.delegate = self
        searchBar.delegate = self

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)

        loadFavorites()
        loadStockData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadFavorites()
    }
    
    @IBAction func logoutButtonTapped(_ sender: Any) {
        let alert = UIAlertController(title: "確定要登出嗎？",
                                          message: nil,
                                          preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "登出", style: .destructive, handler: { _ in
                self.handleLogout()
            }))
            
            present(alert, animated: true)
    }
    private func handleLogout(){
        do {
            try Auth.auth().signOut()
                
            // ✅ 回到登入畫面
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginViewController")
            loginVC.modalPresentationStyle = .fullScreen
            present(loginVC, animated: true, completion: nil)
                
        } catch let signOutError as NSError {
            print("❌ 登出失敗: %@", signOutError)
        }
    }
    

    // MARK: - 搜尋邏輯
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            displayedStocks = allStocks
        } else {
            displayedStocks = allStocks.filter {
                $0.name.contains(searchText) || $0.code.contains(searchText)
            }
        }
        stocksTableView.reloadData()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    // MARK: - 資料載入
    private func loadFavorites() {
        favoriteService.getFavorites { [weak self] codes in
            self?.favoriteStockCodes = Set(codes)
            DispatchQueue.main.async {
                self?.stocksTableView.reloadData()
            }
        }
    }

    private func loadStockData() {
        stockService.fetchAllStocks { [weak self] stocks in
            guard let self = self, let stocks = stocks else { return }
            self.allStocks = stocks
            self.displayedStocks = stocks
            DispatchQueue.main.async {
                self.stocksTableView.reloadData()
            }
        }
    }

    // MARK: - 前往詳情頁
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toDetail",
           let detailVC = segue.destination as? StockDetailViewController,
           let stock = sender as? StockViewModel {
            detailVC.stock = stock
        }
    }

    private func formatToTwoDecimal(_ str: String) -> String {
        if let value = Double(str.replacingOccurrences(of: ",", with: "")) {
            return String(format: "%.2f", value)
        } else {
            return str
        }
    }
}

// MARK: - TableView DataSource & Delegate

extension HomeViewController: UITableViewDataSource, UITableViewDelegate, StockTableViewCellDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayedStocks.count
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let stock = displayedStocks[indexPath.row]
        performSegue(withIdentifier: "toDetail", sender: stock)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(withIdentifier: "StockCell", for: indexPath) as? StockTableViewCell else {
            return UITableViewCell()
        }

        let stock = displayedStocks[indexPath.row]
        cell.nameLabel.text = stock.name
        cell.closingPriceLabel.text = formatToTwoDecimal(stock.closingPrice)
        cell.changeLabel.text = formatToTwoDecimal(stock.change)
        // 成交量：字串 → 數字 → 除以1000 → 無條件捨去 → 格式化
        if let volume = Double(stock.tradeVolume.replacingOccurrences(of: ",", with: "")) {
            let volumeInThousands = floor(volume / 1000)
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 0
            if let formatted = formatter.string(from: NSNumber(value: volumeInThousands)) {
                cell.tradeVolumeLabel.text = "\(formatted) 張"
            }
        } else {
            cell.tradeVolumeLabel.text = stock.tradeVolume
        }


        // ✅ 漲跌幅紅綠色
        let change = Double(stock.change.replacingOccurrences(of: ",", with: "")) ?? 0
        if change > 0 {
            cell.changeLabel.textColor = .red
        } else if change < 0 {
            cell.changeLabel.textColor = .green
        } else {
            cell.changeLabel.textColor = .gray
        }

        // ✅ 星星圖示
        let isFavorited = favoriteStockCodes.contains(stock.code)
        let starImage = UIImage(systemName: isFavorited ? "star.fill" : "star")
        cell.favoriteButton.setImage(starImage, for: .normal)

        // ⭐️ 點擊星星
        cell.delegate = self

        return cell
    }

    // ⭐️ 點星星事件處理
    func didTapFavorite(on cell: StockTableViewCell) {
        guard let indexPath = stocksTableView.indexPath(for: cell) else { return }
        let stock = displayedStocks[indexPath.row]
        let isFavorite = favoriteStockCodes.contains(stock.code)

        if isFavorite {
            favoriteService.removeFavorite(stockCode: stock.code) { [weak self] _ in
                self?.favoriteStockCodes.remove(stock.code)
                DispatchQueue.main.async {
                    self?.stocksTableView.reloadRows(at: [indexPath], with: .automatic)
                }
            }
        } else {
            favoriteService.addFavorite(stockCode: stock.code) { [weak self] _ in
                self?.favoriteStockCodes.insert(stock.code)
                DispatchQueue.main.async {
                    self?.stocksTableView.reloadRows(at: [indexPath], with: .automatic)
                }
            }
        }
    }
}
