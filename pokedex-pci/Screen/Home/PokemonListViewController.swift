import UIKit
import Combine
import SnapKit

final class PokemonListViewController: UIViewController {
    
    // MARK: - Properties:
    /// The coordinator is marked as weak to prevent retain cycles in the navigation hierarchy.
    /// Explanation of the memory management:
    /// 1. The AppCoordinator strongly holds the navigation controller
    /// 2. The navigation controller strongly holds this view controller
    /// 3. If this view controller strongly held the coordinator, it would create a retain cycle:
    ///    Coordinator -> NavigationController -> ViewController -> Coordinator
    /// 4. By making it weak, we break this cycle:
    ///    Coordinator -> NavigationController -> ViewController --(weak)--> Coordinator
    weak var coordinator: AppCoordinator?
    private let viewModel: any PokemonListViewModelProtocol
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
        let layout = createCollectionViewLayout()
        
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
    
    init(viewModel: any PokemonListViewModelProtocol) {
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
        
        // Register for trait changes using the modern API
        registerForTraitChanges([UITraitHorizontalSizeClass.self, UITraitVerticalSizeClass.self]) { (viewController: PokemonListViewController, _) in
            viewController.collectionView.collectionViewLayout = viewController.createCollectionViewLayout()
            viewController.collectionView.collectionViewLayout.invalidateLayout()
        }
        
        Task {
            await viewModel.fetchPokemon()
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate { [weak self] context in
            self?.collectionView.collectionViewLayout = self?.createCollectionViewLayout(for: size) ?? UICollectionViewFlowLayout()
            self?.collectionView.collectionViewLayout.invalidateLayout()
        }
    }
    
    // MARK: - Bindings
    /// Setup Combine publishers to observe the pokemon data
    /// Note: We use [weak self] in these closures because:
    /// 1. Combine subscribers are retained until cancelled
    /// 2. These closures could outlive the view controller
    /// 3. Without [weak self], we would create retain cycles
    private func setupBindings() {
        /// @escaping - These closures can outlive the function they were passed to (they "escape" the function's scope)
        viewModel.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleStateChange(state)
            }
            .store(in: &cancellables)
        viewModel.filteredPokemonPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.collectionView.reloadData()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Private methods:

    private func setupUI() {
        view.backgroundColor = .systemBackground
        view.addSubview(searchBar)
        view.addSubview(collectionView)
        view.addSubview(loadingIndicator)
        view.addSubview(progressView)
        view.addSubview(progressLabel)
        /// SnapKit constraints setup
        /// Note: We don't need [weak self] in SnapKit closures because they are executed immediately and not retained after constraint installation
        /// non-escaping - These are executed synchronously within the function they were passed to and don't persist after the function returns
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
            // Allow user scroll when the data is loading, but the delegate method avoid the user tap on the cell
            collectionView.isUserInteractionEnabled = true
            
            let progressFloat = Float(progress) / Float(total)
            progressView.progress = progressFloat
            progressLabel.text = "Loading Pokémons... \(progress)/\(total)"
            
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
            
            // Show cached data if available
            if !viewModel.filteredPokemon.isEmpty {
                collectionView.isHidden = false
                collectionView.reloadData()
                collectionView.isUserInteractionEnabled = true
                // Show a non-blocking alert about offline mode
                let alert = UIAlertController(
                    title: "Offline Mode",
                    message: "You're viewing cached data. \(message)",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
                
            } else {
                showRetryAlert(message)
            }
        }
    }
    
    private func showRetryAlert(_ message: String) {
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
    
    private func createCollectionViewLayout() -> UICollectionViewLayout {
        return createCollectionViewLayout(for: view.bounds.size)
    }
    
    private func createCollectionViewLayout(for size: CGSize) -> UICollectionViewLayout {
        let layout = UICollectionViewFlowLayout()
        
        let isIPad = UIDevice.current.userInterfaceIdiom == .pad
        
        // Determine orientation based on interface orientation rather than just width/height
        var isLandscape = false
        if let window = view.window, let windowScene = window.windowScene {
            isLandscape = windowScene.interfaceOrientation.isLandscape
        } else {
            // Fallback to size comparison if we can't get the interface orientation
            isLandscape = size.width > size.height
        }
        
        // Configure layout properties based on device/orientation
        if isIPad {
            layout.minimumInteritemSpacing = 20
            layout.minimumLineSpacing = 20
            layout.sectionInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        } else if isLandscape {
            // iPhone landscape - more generous spacing
            layout.minimumInteritemSpacing = 16
            layout.minimumLineSpacing = 16
            layout.sectionInset = UIEdgeInsets(top: 16, left: 24, bottom: 16, right: 24)
        } else {
            // iPhone portrait - more modern insets
            layout.minimumInteritemSpacing = 12
            layout.minimumLineSpacing = 16
            layout.sectionInset = UIEdgeInsets(top: 16, left: 20, bottom: 16, right: 20)
        }
        
        // Determine number of columns
        let numberOfColumns: CGFloat
        if isIPad {
            numberOfColumns = 3
        } else {
            // iPhone
            numberOfColumns = isLandscape ? 2 : 1
        }
        
        // Calculate cell dimensions
        let spacing: CGFloat = layout.minimumInteritemSpacing
        let insets: CGFloat = layout.sectionInset.left + layout.sectionInset.right
        let availableWidth = size.width - insets - (spacing * (numberOfColumns - 1))
        let itemWidth = availableWidth / numberOfColumns
        
        // Adjust height ratio for different layouts
        let heightRatio: CGFloat
        if !isIPad && !isLandscape {
            // iPhone portrait - shorter cells
            heightRatio = 0.6
        } else if !isIPad && isLandscape {
            // iPhone landscape - shorter, wider cells
            heightRatio = 0.6
        } else {
            // iPad - use same compact ratio as iPhone
            heightRatio = 0.7
        }
        
        let itemHeight = itemWidth * heightRatio
        
        layout.itemSize = CGSize(width: itemWidth, height: itemHeight)
        return layout
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
        if case .error = viewModel.state {
            showRetryAlert("Is your network connection working?")
            collectionView.deselectItem(at: indexPath, animated: true)
            return
        }
        // Prevent navigation while loading
        if case .loading = viewModel.state {
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
