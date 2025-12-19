import UIKit

final class InlineCalendarOverlay: UIView {
    
    private let picker: UIDatePicker = {
        let p = UIDatePicker()
        p.preferredDatePickerStyle = .inline
        p.datePickerMode = .date
        p.locale = Locale(identifier: "ru_RU")
        p.maximumDate = Date()
        p.translatesAutoresizingMaskIntoConstraints = false
        return p
    }()
    
    private var onDateSelected: (Date) -> Void
    private var isVisible = false
    
    init(onSelect: @escaping (Date) -> Void) {
        self.onDateSelected = onSelect
        super.init(frame: .zero)
        
        backgroundColor = .white
        layer.cornerRadius = 12
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.15
        layer.shadowRadius = 10
        layer.shadowOffset = CGSize(width: 0, height: 6)
        
        isHidden = true
        
        addSubview(picker)
        picker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        
        NSLayoutConstraint.activate([
            picker.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            picker.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            picker.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            picker.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }
    
    @objc private func dateChanged() {
        onDateSelected(picker.date)
    }
    
    func toggle(anchor: UIView, in container: UIView) {
        isVisible.toggle()
        isHidden = !isVisible
        
        if isVisible {
            let frame = anchor.convert(anchor.bounds, to: container)
            self.frame = CGRect(
                x: 16,
                y: frame.maxY + 8,
                width: container.bounds.width - 32,
                height: 350
            )
            container.bringSubviewToFront(self)
        }
    }
    
    required init?(coder: NSCoder) { fatalError() }
}

