import UIKit

protocol TrackerCellDelegate: AnyObject {
    func trackerCellDidTapComplete(_ cell: TrackerCell)
}

final class TrackerCell: UICollectionViewCell {
    
    static let identifier = "TrackerCell"
    
    weak var delegate: TrackerCellDelegate?
    
    private var isCompleted: Bool = false
    private var isFutureDate: Bool = false
    
    // MARK: - UI
    
    private let cardView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 16
        v.clipsToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    var cardViewForContextMenu: UIView { cardView }
    
    private let emojiContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .white.withAlphaComponent(0.3)
        v.layer.cornerRadius = 12
        v.clipsToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let pinImageView: UIImageView = {
        let image = UIImage(systemName: "pin.fill")?.withRenderingMode(.alwaysTemplate)
        let iv = UIImageView(image: image)
        iv.tintColor = AppColors.background.withAlphaComponent(0.7)
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.isHidden = true
        return iv
    }()
    
    private let emojiLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12, weight: .medium)
        l.textColor = .white
        l.numberOfLines = 2
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let counterLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12, weight: .medium)
        l.textColor = AppColors.textPrimary
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let completeButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.baseForegroundColor = AppColors.primaryButtonTitle
        config.background.cornerRadius = 17
        config.contentInsets = .zero
        
        let b = UIButton(configuration: config)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        completeButton.addTarget(self, action: #selector(didTapComplete), for: .touchUpInside)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        return nil
    }
    override func prepareForReuse() {
        super.prepareForReuse()
        emojiLabel.text = nil
        nameLabel.text = nil
        counterLabel.text = nil
        isCompleted = false
        isFutureDate = false
        completeButton.isEnabled = true
        completeButton.alpha = 1
        pinImageView.isHidden = true
    }
    
    // MARK: - Public
    
    func configure(
        trackerName: String,
        emoji: String,
        color: UIColor,
        completedCount: Int,
        isCompleted: Bool,
        isFutureDate: Bool,
        isPinned: Bool
    ) {
        self.isCompleted = isCompleted
        self.isFutureDate = isFutureDate
        
        cardView.backgroundColor = color
        emojiLabel.text = emoji
        nameLabel.text = trackerName
        pinImageView.isHidden = !isPinned
        
        counterLabel.text = String.localizedStringWithFormat(NSLocalizedString("stats.days_count", comment: "Days count"), completedCount)
        
        let symbolName = isCompleted ? "checkmark" : "plus"
        let image = UIImage(systemName: symbolName)?.withRenderingMode(.alwaysTemplate)
        
        var config = completeButton.configuration
        config?.image = image
        config?.background.backgroundColor = isCompleted
        ? color.withAlphaComponent(0.3)
        : color
        completeButton.configuration = config
        
        if isFutureDate {
            completeButton.isEnabled = false
            completeButton.alpha = 0.4
        } else {
            completeButton.isEnabled = true
            completeButton.alpha = 1
        }
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        contentView.addSubview(cardView)
        contentView.addSubview(counterLabel)
        contentView.addSubview(completeButton)
        
        cardView.addSubview(emojiContainer)
        emojiContainer.addSubview(emojiLabel)
        cardView.addSubview(pinImageView)
        cardView.addSubview(nameLabel)
        
        NSLayoutConstraint.activate([
            // Верхняя карточка
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardView.heightAnchor.constraint(equalToConstant: 90),
            
            // Emoji контейнер
            emojiContainer.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
            emojiContainer.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            emojiContainer.widthAnchor.constraint(equalToConstant: 24),
            emojiContainer.heightAnchor.constraint(equalToConstant: 24),

            // Pin
            pinImageView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
            pinImageView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            pinImageView.widthAnchor.constraint(equalToConstant: 12),
            pinImageView.heightAnchor.constraint(equalToConstant: 12),
            
            emojiLabel.centerXAnchor.constraint(equalTo: emojiContainer.centerXAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: emojiContainer.centerYAnchor),
            
            // Название трекера
            nameLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            nameLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -12),
            
            // Нижняя часть: счётчик слева
            counterLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            counterLabel.topAnchor.constraint(equalTo: cardView.bottomAnchor, constant: 8),
            
            // Кнопка справа
            completeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            completeButton.topAnchor.constraint(equalTo: cardView.bottomAnchor, constant: 8),
            completeButton.widthAnchor.constraint(equalToConstant: 34),
            completeButton.heightAnchor.constraint(equalToConstant: 34)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func didTapComplete() {
        delegate?.trackerCellDidTapComplete(self)
    }
}
