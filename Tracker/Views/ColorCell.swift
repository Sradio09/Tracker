import UIKit

final class ColorCell: UICollectionViewCell {
    static let reuseId = "ColorCell"

    private let selectionContainer: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 16
        v.layer.borderWidth = 2
        v.layer.borderColor = UIColor.systemGreen.cgColor
        v.isHidden = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let colorView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 12
        v.layer.masksToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.clipsToBounds = false
        contentView.layoutMargins = .zero

        contentView.addSubview(selectionContainer)
        contentView.addSubview(colorView)

        NSLayoutConstraint.activate([
            selectionContainer.widthAnchor.constraint(equalToConstant: 52),
            selectionContainer.heightAnchor.constraint(equalToConstant: 52),
            selectionContainer.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            selectionContainer.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            colorView.widthAnchor.constraint(equalToConstant: 40),
            colorView.heightAnchor.constraint(equalToConstant: 40),
            colorView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            colorView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])

        updateSelectionUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        return nil
    }
    func configure(color: UIColor) {
        colorView.backgroundColor = color
        updateSelectionUI()
    }

    override var isSelected: Bool {
        didSet { updateSelectionUI() }
    }

    private func updateSelectionUI() {
        selectionContainer.isHidden = !isSelected
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        colorView.backgroundColor = nil
        selectionContainer.isHidden = true
    }
}
