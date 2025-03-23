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
    
    private let viewModel: PokemonDetailViewModelProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - UI Components:
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        scrollView.accessibilityIdentifier = AccessibilityIdentifiers.PokemonDetail.scrollView
        return scrollView
    }()
    
    private lazy var contentView: UIView = {
        let view = UIView()
        return view
    }()
    
    private lazy var headerView = PokemonHeaderView(backgroundColor: viewModel.colorName.uiColor)
    private lazy var statsView = StatsSectionView(title: "Base Stats")
    private lazy var abilitiesView = AbilitiesSectionView(title: "Abilities")
    private lazy var movesView = MovesSectionView(title: "Moves")
    
    // MARK: - Initializers:
    
    init(viewModel: PokemonDetailViewModelProtocol) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle Methods:
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureUI()
        setupNavigationBar()
        edgesForExtendedLayout = .top
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        // Set main view background color to match Pokemon's type color
        view.backgroundColor = viewModel.colorName.uiColor
        view.addSubview(scrollView)
        
        scrollView.backgroundColor = .clear
        scrollView.addSubview(contentView)
        
        // Add components to view hierarchy
        contentView.backgroundColor = .clear
        contentView.addSubview(headerView)
        contentView.addSubview(statsView)
        contentView.addSubview(abilitiesView)
        contentView.addSubview(movesView)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        let safeAreaTop = view.safeAreaInsets.top
        
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(view)
        }
        
        // Header constraints - extend to cover status bar
        headerView.snp.makeConstraints { make in
            // Use a negative top value to extend under status bar
            make.top.equalToSuperview().offset(-safeAreaTop)
            make.leading.trailing.equalToSuperview()
            // Adjust height to include status bar area
            make.height.equalTo(300 + safeAreaTop)
        }
        
        // Configure header view internal constraints
        headerView.setupConstraints(safeAreaTop: safeAreaTop)
        
        statsView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(-15)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        abilitiesView.snp.makeConstraints { make in
            make.top.equalTo(statsView.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        movesView.snp.makeConstraints { make in
            make.top.equalTo(abilitiesView.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(24)
        }
    }
    
    private func setupNavigationBar() {
        navigationItem.largeTitleDisplayMode = .never
    }
    
    // MARK: - Configuration
    
    private func configureUI() {
        // Configure header view
        headerView.configure(
            id: "#\(viewModel.id)",
            name: viewModel.name,
            imageURL: viewModel.imageURL,
            types: viewModel.typeNames,
            typeColor: viewModel.colorName.uiColor,
            onBack: { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            }
        )
        // Configure stats view
        statsView.configure(with: viewModel.stats)
        // Configure abilities view
        abilitiesView.configure(with: viewModel.abilitiesArray)
        // Configure moves view
        movesView.configure(with: viewModel.movesArray)
    }
}
