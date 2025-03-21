//
//  PokemonDetailViewController.swift
//  pokedex-pci
//
//  Created by Manny Alvarez on 20/03/2025.
//

import UIKit
import SnapKit
import Combine
import Kingfisher

final class PokemonDetailViewController: UIViewController {
    
    // MARK: - Private Properties:
    
    private let viewModel: PokemonDetailViewModel
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: UI - Components:
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        return scrollView
    }()
    
    private let containerView = UIView()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .clear
        return imageView
    }()
    
    private let loadingView: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private let typeLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.text = "Loading..."
        return label
    }()
    
    private let abilitiesTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Abilities"
        label.font = .systemFont(ofSize: 20, weight: .bold)
        return label
    }()
    
    private let abilitiesLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 16)
        label.text = "Loading..."
        return label
    }()
    
    private let movesTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Moves"
        label.font = .systemFont(ofSize: 20, weight: .bold)
        return label
    }()
    
    private let movesLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 16)
        label.text = "Loading..."
        return label
    }()
    
    // MARK: - Initializers :
    
    init(viewModel: PokemonDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle:
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureWithViewModel()
    }
    
    // MARK: - Private Methods:
    
    private func configureWithViewModel() {
        title = viewModel.name
        typeLabel.text = viewModel.types
        abilitiesLabel.text = viewModel.abilities
        movesLabel.text = viewModel.moves
        // Handle image cache with Kingfisher
        if let url = viewModel.imageURL {
            imageView.kf.indicatorType = .activity
            imageView.kf.setImage(
                with: url,
                options: [
                    .transition(.fade(0.2)),
                    .cacheOriginalImage
                ]
            )
        }
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(scrollView)
        scrollView.addSubview(containerView)
        
        containerView.addSubview(imageView)
        containerView.addSubview(loadingView)
        containerView.addSubview(typeLabel)
        containerView.addSubview(abilitiesTitleLabel)
        containerView.addSubview(abilitiesLabel)
        containerView.addSubview(movesTitleLabel)
        containerView.addSubview(movesLabel)
        
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
        
        imageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(200)
        }
        
        loadingView.snp.makeConstraints { make in
            make.center.equalTo(imageView)
        }
        
        typeLabel.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        abilitiesTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(typeLabel.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        abilitiesLabel.snp.makeConstraints { make in
            make.top.equalTo(abilitiesTitleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        movesTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(abilitiesLabel.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        movesLabel.snp.makeConstraints { make in
            make.top.equalTo(movesTitleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(16)
        }
    }
}
