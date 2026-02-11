//
//  StockTableViewCell.swift
//  Gudi
//
//  Created by 林聖凱 on 2025/6/27.
//

import UIKit



class StockTableViewCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var closingPriceLabel: UILabel!
    @IBOutlet weak var changeLabel: UILabel!
    @IBOutlet weak var tradeVolumeLabel: UILabel!
    @IBOutlet weak var favoriteButton: UIButton!
    
    weak var delegate: StockTableViewCellDelegate?

    private let darkTextColor = UIColor(red: 0.2, green: 0.22, blue: 0.28, alpha: 1)
    private let tealColor = UIColor(red: 0.22, green: 0.55, blue: 0.53, alpha: 1)

    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.backgroundColor = .white
        nameLabel?.textColor = darkTextColor
        nameLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        closingPriceLabel?.textColor = darkTextColor
        closingPriceLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        tradeVolumeLabel?.textColor = UIColor(red: 0.45, green: 0.47, blue: 0.52, alpha: 1)
        tradeVolumeLabel?.font = .systemFont(ofSize: 14, weight: .regular)
        changeLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        favoriteButton?.tintColor = tealColor
    }
    
    @IBAction func favoriteButtonTapped(_ sender: UIButton) {
        delegate?.didTapFavorite(on: self)
    }
    
}

protocol StockTableViewCellDelegate: AnyObject {
    func didTapFavorite(on cell: StockTableViewCell)
}
