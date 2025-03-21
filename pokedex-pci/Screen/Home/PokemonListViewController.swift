import UIKit
import Combine
import SnapKit

final class PokemonListViewController: UIViewController {
    
    // MARK: - Properties:
    /// The coordinator is marked as weak to prevent retain cycles in the navigation hierarchy.
    /// 
    /// Explanation of the memory management:
    /// 1. The AppCoordinator strongly holds the navigation controller
    /// 2. The navigation controller strongly holds this view controller
    /// 3. If this view controller strongly held the coordinator, it would create a retain cycle:
    ///    Coordinator -> NavigationController -> ViewController -> Coordinator
    /// 4. By making it weak, we break this cycle:
    ///    Coordinator -> NavigationController -> ViewController --(weak)--> Coordinator
    weak var coordinator: AppCoordinator?
    private let viewModel: PokemonListViewModel
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - UI Components:
    private lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search Pokémon"
        searchBar.searchBarStyle = .minimal
        searchBar.delegate = self
        return searchBar
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 16
        layout.minimumLineSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        
        let itemWidth = (UIScreen.main.bounds.width - 48) / 2
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth * 1.2)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemBackground
        collectionView.delegate = self
        collectionView.dataSource = self
        return collectionView
    }()
    
    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private lazy var progressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.progressTintColor = .red
        progress.trackTintColor = .systemGray5
        progress.layer.cornerRadius = 2
        progress.clipsToBounds = true
        return progress
    }()
    
    private lazy var progressLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 14)
        return label
    }()
    
    // MARK: - Initialization:
    
    init(viewModel: PokemonListViewModel) {
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
        setupCollectionView()
        setupBindings()
        title = "Pokédex"
        Task {
            await viewModel.fetchPokemon()
        }
    }
    
    // MARK: - UI Setup
    /// SnapKit constraints setup
    /// Note: We don't need [weak self] in SnapKit closures because they are executed immediately
    /// and not retained after constraint installation
    private func setupUI() {
        view.backgroundColor = .systemBackground
        view.addSubview(searchBar)
        view.addSubview(collectionView)
        view.addSubview(loadingIndicator)
        view.addSubview(progressView)
        view.addSubview(progressLabel)
        
        searchBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
        }
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(progressView.snp.top).offset(-8)
        }
        loadingIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        progressView.snp.makeConstraints { make in
            make.leading.equalTo(view.snp.leading).offset(20)
            make.trailing.equalTo(view.snp.trailing).offset(-20)
            make.bottom.equalTo(progressLabel.snp.top).offset(-4)
            make.height.equalTo(4)
        }
        progressLabel.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-8)
            make.centerX.equalToSuperview()
        }
    }
    
    // MARK: - Private methods:
    
    // MARK: - Bindings
    /// Setup Combine publishers to observe the pokemon data
    /// Note: We use [weak self] in these closures because:
    /// 1. Combine subscribers are retained until cancelled
    /// 2. These closures could outlive the view controller
    /// 3. Without [weak self], we would create retain cycles
    private func setupBindings() {
        // Observe the data flowL (.idle .loading(progress: Int, total: Int), .loaded([Pokemon]), .error(String))
        viewModel.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleStateChange(state)
            }
            .store(in: &cancellables)
        // Observe changes on the search filter and the view model handle the data
        viewModel.$filteredPokemon
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.collectionView.reloadData()
            }
            .store(in: &cancellables)
    }
    
    private func setupCollectionView() {
        collectionView.register(PokemonCell.self, forCellWithReuseIdentifier: PokemonCell.identifier)
    }
    
    private func handleStateChange(_ state: PokemonListState) {
        switch state {
        case .idle:
            loadingIndicator.startAnimating()
            progressView.isHidden = true
            progressLabel.isHidden = true
            collectionView.isHidden = true
            // Disable tap before the data is loaded
            collectionView.isUserInteractionEnabled = false
            
        case .loading(let progress, let total):
            loadingIndicator.stopAnimating()
            progressView.isHidden = false
            progressLabel.isHidden = false
            collectionView.isHidden = false
            // Allows tap after the data is loaded
            collectionView.isUserInteractionEnabled = false
            
            let progressFloat = Float(progress) / Float(total)
            progressView.progress = progressFloat
            progressLabel.text = "Loading Pokemon... \(progress)/\(total)"
            
        case .loaded:
            loadingIndicator.stopAnimating()
            progressView.isHidden = true
            progressLabel.isHidden = true
            collectionView.isHidden = false
            collectionView.isUserInteractionEnabled = true
            collectionView.reloadData()
            
        case .error(let message):
            loadingIndicator.stopAnimating()
            progressView.isHidden = true
            progressLabel.isHidden = true
            collectionView.isHidden = true
            collectionView.isUserInteractionEnabled = false
            
            let alert = UIAlertController(
                title: "Error",
                message: message,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Retry", style: .default) { [weak self] _ in
                Task {
                    await self?.viewModel.fetchPokemon()
                }
            })
            present(alert, animated: true)
        }
    }
}

// MARK: - UICollectionViewDataSource:

extension PokemonListViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.filteredPokemon.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PokemonCell.identifier, for: indexPath) as! PokemonCell
        let pokemon = viewModel.filteredPokemon[indexPath.item]
        cell.configure(with: pokemon)
        return cell
    }
}

// MARK: - UICollectionViewDelegate:

extension PokemonListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Prevent navigation while loading
        guard case .loaded = viewModel.state else {
            collectionView.deselectItem(at: indexPath, animated: true)
            return
        }
        
        let pokemon = viewModel.filteredPokemon[indexPath.item]
        coordinator?.showPokemonDetail(pokemon: pokemon)
    }
}

// MARK: - UISearchBarDelegate:

extension PokemonListViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.searchText = searchText
    }
}
