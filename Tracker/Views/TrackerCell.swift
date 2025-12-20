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
    
    private let emojiContainer: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        v.layer.cornerRadius = 12
        v.clipsToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
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
        l.textColor = .black
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let completeButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.baseForegroundColor = .white
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
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        emojiLabel.text = nil
        nameLabel.text = nil
        counterLabel.text = nil
        isCompleted = false
        isFutureDate = false
        completeButton.isEnabled = true
        completeButton.alpha = 1
    }
    
    // MARK: - Public
    
    func configure(
        trackerName: String,
        emoji: String,
        color: UIColor,
        completedCount: Int,
        isCompleted: Bool,
        isFutureDate: Bool
    ) {
        self.isCompleted = isCompleted
        self.isFutureDate = isFutureDate
        
        cardView.backgroundColor = color
        emojiLabel.text = emoji
        nameLabel.text = trackerName
        
        counterLabel.text = "\(completedCount) \(daysWord(for: completedCount))"
        
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
    
    // MARK: - Helpers
    
    private func daysWord(for count: Int) -> String {
        let mod10 = count % 10
        let mod100 = count % 100
        if mod10 == 1 && mod100 != 11 { return "день" }
        if (2...4).contains(mod10) && !(12...14).contains(mod100) { return "дня" }
        return "дней"
    }
}

