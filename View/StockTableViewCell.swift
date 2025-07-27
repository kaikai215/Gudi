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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    @IBAction func favoriteButtonTapped(_ sender: UIButton) {
        delegate?.didTapFavorite(on: self)
    }
    
}

protocol StockTableViewCellDelegate: AnyObject {
    func didTapFavorite(on cell: StockTableViewCell)
}
