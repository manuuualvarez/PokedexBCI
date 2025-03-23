import UIKit
import SnapKit
import Kingfisher

final class PokemonCell: UICollectionViewCell {
    static let identifier = "PokemonCell"
    
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 10
        view.clipsToBounds = true
        return view
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .clear
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 15, weight: .medium)
        return label
    }()
    
    private let idLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private var currentImageURL: URL?
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        contentView.addSubview(containerView)
        containerView.addSubview(imageView)
        containerView.addSubview(nameLabel)
        containerView.addSubview(idLabel)
        
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(4)
        }
        
        imageView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(8)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(contentView.snp.width).multipliedBy(0.6)
        }
        
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(8)
        }
        
        idLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview().inset(8)
            make.bottom.equalToSuperview().inset(8).priority(999) // High priority but not required
        }
    }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let isIPad = UIDevice.current.userInterfaceIdiom == .pad
        
        // Get accurate orientation information from window scene
        var isLandscape = false
        if let window = self.window, let windowScene = window.windowScene {
            isLandscape = windowScene.interfaceOrientation.isLandscape
        } else {
            // Use size as fallback for older iOS versions
            isLandscape = bounds.width > bounds.height * 1.2
        }
        
        if isLandscape && !isIPad {
            // Landscape layout for iPhone
            imageView.snp.remakeConstraints { make in
                make.leading.top.bottom.equalToSuperview().inset(8)
                make.width.equalTo(imageView.snp.height)
            }
            
            nameLabel.snp.remakeConstraints { make in
                make.top.equalToSuperview().inset(12)
                make.leading.equalTo(imageView.snp.trailing).offset(8)
                make.trailing.equalToSuperview().inset(8)
            }
            
            idLabel.snp.remakeConstraints { make in
                make.top.equalTo(nameLabel.snp.bottom).offset(4)
                make.leading.equalTo(imageView.snp.trailing).offset(8)
                make.trailing.bottom.equalToSuperview().inset(8)
            }
        } else {
            // Standard portrait layout (for iPhone portrait and iPad both orientations)
            imageView.snp.remakeConstraints { make in
                make.top.equalToSuperview().inset(8)
                make.centerX.equalToSuperview()
                // Smaller image for portrait mode
                make.width.height.equalTo(contentView.snp.width).multipliedBy(isIPad ? 0.35 : 0.4)
            }
            
            nameLabel.snp.remakeConstraints { make in
                make.top.equalTo(imageView.snp.bottom).offset(4)
                make.leading.trailing.equalToSuperview().inset(8)
            }
            
            idLabel.snp.remakeConstraints { make in
                make.top.equalTo(nameLabel.snp.bottom).offset(2)
                make.leading.trailing.equalToSuperview().inset(8)
                make.bottom.lessThanOrEqualToSuperview().inset(8) // This is the key change to fix constraints
            }
        }
    }
    
    // MARK: - Configuration
    func configure(with pokemon: Pokemon) {
        nameLabel.text = pokemon.name.capitalized
        // Use formatt to show 3 digits with a # prefix
        idLabel.text = String(format: "#%03d", pokemon.id)
        // Use KingFisher package to handle the image cache.
        if let url = URL(string: pokemon.sprites.frontDefault), currentImageURL != url {
            currentImageURL = url
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
    
    /// Prepares a cell for reuse in a collection view by cleaning up resources and resetting its state.
    /// This method is called by the collection view when a cell is about to be reused for a different index path.
    /// 
    /// The cleanup process includes:
    /// - Canceling any ongoing Kingfisher image download to prevent unnecessary network requests
    /// - Clearing the image view to prevent showing stale images
    /// - Resetting text labels to prevent showing incorrect data
    /// - Clearing the current image URL to ensure proper image loading for the new item
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.kf.cancelDownloadTask()
        imageView.image = nil
        nameLabel.text = nil
        idLabel.text = nil
        currentImageURL = nil
    }
}
