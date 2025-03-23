//
//  StatsSectionView.swift
//  pokedex-pci
//
//  Created by Manny Alvarez on 21/03/2025.
//
import UIKit
import SnapKit


final class StatsSectionView: CardView {
    
    // MARK: - Container:
    
    private lazy var statsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.distribution = .fillEqually
        return stackView
    }()
    
    // MARK: - Initializars:
    
    override init(title: String) {
        super.init(title: title)
        setupUI()
        titleLabel.accessibilityIdentifier = AccessibilityIdentifiers.StatsSection.title
        self.accessibilityIdentifier = AccessibilityIdentifiers.StatsSection.container
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Private Methods:
    private func setupUI() {
        contentView.addSubview(statsStackView)
        statsStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }
    }
    
    private func createStatView(name: String, value: Int, colorName: PokemonColorName) -> UIView {
        let container = UIView()
        
        let nameLabel = UILabel()
        nameLabel.text = name.replacingOccurrences(of: "-", with: " ")
        nameLabel.font = .systemFont(ofSize: 14, weight: .medium)
        nameLabel.textColor = .label
        nameLabel.accessibilityIdentifier = AccessibilityIdentifiers.StatsSection.statName
        
        let valueLabel = UILabel()
        valueLabel.text = "\(value)"
        valueLabel.font = .systemFont(ofSize: 14, weight: .bold)
        valueLabel.textColor = .label
        valueLabel.textAlignment = .right
        valueLabel.accessibilityIdentifier = AccessibilityIdentifiers.StatsSection.statValue
        
        let progressBackground = UIView()
        progressBackground.backgroundColor = .systemGray5
        progressBackground.layer.cornerRadius = 4
        progressBackground.accessibilityIdentifier = AccessibilityIdentifiers.StatsSection.statProgressBackground
        
        let progressFill = UIView()
        progressFill.backgroundColor = colorName.uiColor
        progressFill.layer.cornerRadius = 4
        progressFill.accessibilityIdentifier = AccessibilityIdentifiers.StatsSection.statProgressFill
        
        container.addSubview(nameLabel)
        container.addSubview(valueLabel)
        container.addSubview(progressBackground)
        progressBackground.addSubview(progressFill)
        
        nameLabel.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.width.equalTo(120)
        }
        
        valueLabel.snp.makeConstraints { make in
            make.trailing.top.bottom.equalToSuperview()
            make.width.equalTo(35)
        }
        
        progressBackground.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel.snp.trailing).offset(12)
            make.trailing.equalTo(valueLabel.snp.leading).offset(-12)
            make.centerY.equalToSuperview()
            make.height.equalTo(8)
        }
        
        let percentage = min(1.0, Double(value) / 100.0)
        progressFill.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.width.equalTo(progressBackground.snp.width).multipliedBy(percentage)
        }
        
        return container
    }
    
    func configure(with stats: [SimpleStat]) {
        statsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for stat in stats {
            let statView = createStatView(name: stat.name, value: stat.value, colorName: stat.colorName)
            statsStackView.addArrangedSubview(statView)
        }
    }
}
