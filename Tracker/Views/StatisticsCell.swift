import UIKit

final class StatisticsCell: UITableViewCell {
    
    static let reuseId = "StatisticsCell"
    private let cardView = StatisticsCardView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(cardView)
        cardView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        return nil
    }
    
    func configure(value: Int, title: String) {
        cardView.configure(value: value, title: title)
    }
}

final class StatisticsCardView: UIView {
    
    private let valueLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 34, weight: .bold)
        l.textColor = AppColors.textPrimary
        return l
    }()
    
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 12, weight: .medium)
        l.textColor = AppColors.textPrimary
        l.numberOfLines = 2
        return l
    }()
    
    private let borderLayer = CAGradientLayer()
    private let maskLayer = CAShapeLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = AppColors.background
        layer.cornerRadius = 16
        layer.masksToBounds = true
        
        setupBorder()
        
        addSubview(valueLabel)
        addSubview(titleLabel)
        
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        titleLabel.setContentHuggingPriority(.required, for: .vertical)
        
        NSLayoutConstraint.activate([
            valueLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            valueLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.topAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: 2),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        return nil
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        borderLayer.frame = bounds
        
        let inset: CGFloat = 1
        let path = UIBezierPath(roundedRect: bounds.insetBy(dx: inset, dy: inset), cornerRadius: 16)
        maskLayer.path = path.cgPath
        maskLayer.lineWidth = 2
    }
    
    func configure(value: Int, title: String) {
        valueLabel.text = String(value)
        titleLabel.text = title
    }
    
    private func setupBorder() {
        borderLayer.type = .conic
        borderLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        borderLayer.endPoint = CGPoint(x: 1, y: 1)
        borderLayer.colors = [
            UIColor.systemRed.cgColor,
            UIColor.systemGreen.cgColor,
            UIColor.systemBlue.cgColor,
            UIColor.systemRed.cgColor
        ]
        
        maskLayer.fillColor = UIColor.clear.cgColor
        maskLayer.strokeColor = UIColor.black.cgColor
        
        borderLayer.mask = maskLayer
        layer.addSublayer(borderLayer)
    }
}

