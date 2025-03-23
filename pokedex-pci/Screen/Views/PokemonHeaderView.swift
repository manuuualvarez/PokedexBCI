//
//  PokemonHeaderView.swift
//  pokedex-pci
//
//  Created by Manny Alvarez on 21/03/2025.
//
import UIKit
import SnapKit

final class PokemonHeaderView: UIView {
    
    // MARK: - UI:
    
    private lazy var backButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        let image = UIImage(systemName: "chevron.left", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.tintColor = .white
        button.accessibilityIdentifier = AccessibilityIdentifiers.PokemonDetail.backButton
        return button
    }()
    
    private lazy var idLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white.withAlphaComponent(0.7)
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.accessibilityIdentifier = AccessibilityIdentifiers.PokemonDetail.pokemonId
        return label
    }()
    
    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 32, weight: .heavy)
        label.textAlignment = .center
        label.numberOfLines = 2
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
        
        // Add text shadow for better readability on colored backgrounds
        label.layer.shadowColor = UIColor.black.cgColor
        label.layer.shadowOffset = CGSize(width: 0, height: 2)
        label.layer.shadowRadius = 3
        label.layer.shadowOpacity = 0.3
        label.layer.masksToBounds = false
        label.accessibilityIdentifier = AccessibilityIdentifiers.PokemonDetail.pokemonName
        return label
    }()
    
    private lazy var nameLabelBackground: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.15)
        view.layer.cornerRadius = 12
        return view
    }()
    
    private lazy var typeContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.accessibilityIdentifier = AccessibilityIdentifiers.PokemonDetail.typeContainer
        return view
    }()
    
    private lazy var typeStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.distribution = .fillEqually
        stackView.alignment = .center
        return stackView
    }()
    
    private lazy var pokemonImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .clear
        imageView.accessibilityIdentifier = AccessibilityIdentifiers.PokemonDetail.pokemonImage
        return imageView
    }()
    
    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .white
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private var onBackTapped: (() -> Void)?
    
    // MARK: - Initializers:
    
    init(backgroundColor: UIColor) {
        super.init(frame: .zero)
        self.backgroundColor = backgroundColor
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Private Methods:
    
    private func setupUI() {
        addSubview(backButton)
        addSubview(idLabel)
        addSubview(nameLabelBackground)
        addSubview(nameLabel)
        addSubview(pokemonImageView)
        addSubview(loadingIndicator)
        addSubview(typeContainerView)
        typeContainerView.addSubview(typeStackView)
        
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
    }
    
    private func configureTypes(types: [String], typeColor: UIColor) {
        typeStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for typeName in types {
            let badge = createTypeBadge(typeName: typeName, color: typeColor)
            typeStackView.addArrangedSubview(badge)
        }
    }
    
    private func createTypeBadge(typeName: String, color: UIColor) -> UIView {
        let badge = UIView()
        badge.backgroundColor = color.withAlphaComponent(0.4)
        badge.layer.cornerRadius = 16
        
        let label = UILabel()
        label.text = typeName
        label.textColor = .white
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .center
        label.accessibilityIdentifier = AccessibilityIdentifiers.PokemonDetail.typeLabel
        
        badge.addSubview(label)
        label.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(6)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        return badge
    }
    
    @objc private func backButtonTapped() {
        onBackTapped?()
    }
    
    // MARK: - Public Methods:
    
    func setupConstraints(safeAreaTop: CGFloat) {
        backButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(safeAreaTop + 16)
            make.leading.equalToSuperview().offset(16)
            make.width.height.equalTo(44)
        }
        
        idLabel.snp.makeConstraints { make in
            make.centerY.equalTo(backButton)
            make.trailing.equalToSuperview().inset(16)
        }
        
        pokemonImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(safeAreaTop + 70)
            make.width.height.lessThanOrEqualTo(150)
        }
        
        loadingIndicator.snp.makeConstraints { make in
            make.center.equalTo(pokemonImageView)
        }
        
        nameLabelBackground.snp.makeConstraints { make in
            make.top.equalTo(pokemonImageView.snp.bottom).offset(12)
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(50)
            make.height.equalTo(44).priority(750)
            make.bottom.equalTo(nameLabel).offset(8)
        }
        
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(pokemonImageView.snp.bottom).offset(18)
            make.centerX.equalToSuperview()
            make.leading.trailing.equalTo(nameLabelBackground).inset(12)
        }
        
        typeContainerView.snp.makeConstraints { make in
            make.top.equalTo(nameLabelBackground.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
            make.bottom.lessThanOrEqualToSuperview().inset(16).priority(999)
        }
        
        typeStackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.height.lessThanOrEqualToSuperview()
            make.top.bottom.equalToSuperview()
        }
    }
    
    func configure(id: String, name: String, imageURL: URL?, types: [String], typeColor: UIColor, onBack: @escaping () -> Void) {
        idLabel.text = id
        nameLabel.text = name
        self.onBackTapped = onBack
        
        // Configure image
        loadingIndicator.startAnimating()
        if let url = imageURL {
            pokemonImageView.kf.setImage(
                with: url,
                options: [.transition(.fade(0.3))],
                completionHandler: { [weak self] _ in
                    self?.loadingIndicator.stopAnimating()
                }
            )
        } else {
            loadingIndicator.stopAnimating()
        }
        
        // Configure types
        configureTypes(types: types, typeColor: typeColor)
    }
}
