//
//  MovesSectionView.swift
//  pokedex-pci
//
//  Created by Manny Alvarez on 21/03/2025.
//
import UIKit
import SnapKit


final class MovesSectionView: CardView {
    
    // MARK: - UI:
    
    private lazy var movesStackView: UIStackView = {
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
        titleLabel.accessibilityIdentifier = AccessibilityIdentifiers.MovesSection.title
        self.accessibilityIdentifier = AccessibilityIdentifiers.MovesSection.container
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Private Methods:
    
    private func setupUI() {
        contentView.addSubview(movesStackView)
        movesStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }
    }
    
    private func createInfoView(text: String) -> UIView {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 8
        view.accessibilityIdentifier = AccessibilityIdentifiers.MovesSection.moveContainer
        
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
        label.accessibilityIdentifier = AccessibilityIdentifiers.MovesSection.moveLabel
        
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16))
        }
        
        return view
    }
    
    // MARK: - Public Methods:
    
    func configure(with moves: [String]) {
        movesStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        if moves.isEmpty {
            let emptyView = createInfoView(text: "No moves available")
            movesStackView.addArrangedSubview(emptyView)
            return
        }
        
        for move in moves {
            let moveView = createInfoView(text: move)
            movesStackView.addArrangedSubview(moveView)
        }
    }
    
}
