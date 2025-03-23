//
//  AbilitiesSectionView.swift
//  PokedexBCI
//
//  Created by Manny Alvarez on 21/03/2025.
//
import UIKit
import SnapKit


final class AbilitiesSectionView: CardView {
    
    // MARK: -  UI:
    
    private lazy var abilitiesStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.distribution = .fillEqually
        return stackView
    }()
    
    // MARK: - Initializers:
    
    override init(title: String) {
        super.init(title: title)
        setupUI()
        self.accessibilityIdentifier = AccessibilityIdentifiers.AbilitiesSection.container
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Private Merhods:
    
    private func setupUI() {
        contentView.addSubview(abilitiesStackView)
        abilitiesStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }
    }
    
    private func createInfoView(text: String) -> UIView {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 8
        view.accessibilityIdentifier = AccessibilityIdentifiers.AbilitiesSection.abilityContainer
        
        // Add subtle shadow for better depth
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 1)
        view.layer.shadowRadius = 3
        view.layer.shadowOpacity = 0.1
        
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 15)
        label.textColor = .label
        label.numberOfLines = 0
        label.accessibilityIdentifier = AccessibilityIdentifiers.AbilitiesSection.abilityLabel
        
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16))
        }
        
        return view
    }
    
    // MARK: - Public Merhods:
    
    func configure(with abilities: [String]) {
        abilitiesStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        if abilities.isEmpty {
            let emptyView = createInfoView(text: "No abilities available")
            abilitiesStackView.addArrangedSubview(emptyView)
            return
        }
        
        for ability in abilities {
            let abilityView = createInfoView(text: ability)
            abilitiesStackView.addArrangedSubview(abilityView)
        }
    }
}
