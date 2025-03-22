//
//  CardView.swift
//  pokedex-pci
//
//  Created by Manny Alvarez on 21/03/2025.
//
import UIKit
import SnapKit

// MARK: - Card View
class CardView: UIView {

    // MARK: - UI Components:
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .label
        return label
    }()
    
    let contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    // MARK: - Initializers
    
    init(title: String) {
        super.init(frame: .zero)
        
        backgroundColor = .systemBackground
        layer.cornerRadius = 16
        
        // Enhanced shadow for better contrast against colored backgrounds
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 3)
        layer.shadowRadius = 10
        layer.shadowOpacity = 0.15
        
        titleLabel.text = title
        
        addSubview(titleLabel)
        addSubview(contentView)
        
        titleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().inset(16)
        }
        
        contentView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
