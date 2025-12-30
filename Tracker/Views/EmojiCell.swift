import UIKit

final class EmojiCell: UICollectionViewCell {
    static let reuseId = "EmojiCell"
    
    private let selectionBackground: UIView = {
        let v = UIView()
        v.backgroundColor = .systemGray5
        v.layer.cornerRadius = 16
        v.isHidden = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let label: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 32)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        l.clipsToBounds = false
        return l
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.layoutMargins = .zero
        contentView.preservesSuperviewLayoutMargins = false
        contentView.clipsToBounds = false
        
        contentView.addSubview(selectionBackground)
        contentView.addSubview(label)
        
        NSLayoutConstraint.activate([
            
            selectionBackground.widthAnchor.constraint(equalToConstant: 52),
            selectionBackground.heightAnchor.constraint(equalToConstant: 52),
            selectionBackground.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            selectionBackground.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            label.widthAnchor.constraint(equalToConstant: 46),
            label.heightAnchor.constraint(equalToConstant: 46),
            label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
        
        updateSelectionUI()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    func configure(emoji: String) {
        label.text = emoji
        updateSelectionUI()
    }
    
    override var isSelected: Bool {
        didSet { updateSelectionUI() }
    }
    
    private func updateSelectionUI() {
        selectionBackground.isHidden = !isSelected
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        label.text = nil
        selectionBackground.isHidden = true
    }
}

