//
//  PokemonDetailViewController.swift
//  pokedex-pci
//
//  Created by Manny Alvarez on 20/03/2025.
//

import UIKit
import SnapKit
import Combine

final class PokemonDetailViewController: UIViewController {
    private let viewModel: PokemonDetailViewModel
    private var cancellables = Set<AnyCancellable>()
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        return scrollView
    }()
    
    private let containerView = UIView()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .systemGray6
        imageView.layer.cornerRadius = 16
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private let typeLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 18, weight: .medium)
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
        return label
    }()
    
    init(viewModel: PokemonDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = viewModel.name
        
        view.addSubview(scrollView)
        scrollView.addSubview(containerView)
        
        containerView.addSubview(imageView)
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
    
    private func configureUI() {
        typeLabel.text = viewModel.types
        abilitiesLabel.text = viewModel.abilities
        movesLabel.text = viewModel.moves
        
        if let url = viewModel.imageURL {
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.imageView.image = image
                    }
                }
            }.resume()
        }
    }
}
