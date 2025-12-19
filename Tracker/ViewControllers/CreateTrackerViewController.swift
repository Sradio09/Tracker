import UIKit

final class CreateTrackerViewController: UIViewController, UITextFieldDelegate {
    
    private enum Constants {
        static let maxNameLength = 38
        static let warningText = "Ограничение 38 символов"
    }
    
    // MARK: - UI
    
    private lazy var nameField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Введите название трекера"
        tf.backgroundColor = .systemGray6
        tf.layer.cornerRadius = 16
        tf.setLeftPaddingPoints(16)
        tf.font = .systemFont(ofSize: 17)
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.heightAnchor.constraint(equalToConstant: 75).isActive = true
        
        tf.delegate = self
        tf.returnKeyType = .done
        tf.addTarget(self, action: #selector(nameChanged), for: .editingChanged)
        tf.inputAccessoryView = makeKeyboardToolbar()
        return tf
    }()
    
    private let warningLabel: UILabel = {
        let label = UILabel()
        label.text = Constants.warningText
        label.textColor = .systemRed
        label.font = .systemFont(ofSize: 17, weight: .regular)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var categoryButton: UIButton = Self.makeRowButton(title: "Категория", subtitle: nil)
    private lazy var scheduleButton: UIButton = Self.makeRowButton(title: "Расписание", subtitle: nil)
    
    private let separator: UIView = {
        let v = UIView()
        v.backgroundColor = .systemGray3
        v.translatesAutoresizingMaskIntoConstraints = false
        v.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return v
    }()
    
    private lazy var cancelButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Отменить"
        config.baseForegroundColor = .systemRed
        config.background.backgroundColor = .white
        config.background.cornerRadius = 16
        config.contentInsets = NSDirectionalEdgeInsets(top: 18, leading: 16, bottom: 18, trailing: 16)
        
        let b = UIButton(configuration: config)
        b.layer.cornerRadius = 16
        b.clipsToBounds = true
        b.layer.borderWidth = 1
        b.layer.borderColor = UIColor.systemRed.cgColor
        b.translatesAutoresizingMaskIntoConstraints = false
        b.heightAnchor.constraint(equalToConstant: 60).isActive = true
        return b
    }()
    
    private lazy var createButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Создать"
        config.baseForegroundColor = .white
        config.background.backgroundColor = .systemGray3
        config.background.cornerRadius = 16
        config.contentInsets = NSDirectionalEdgeInsets(top: 18, leading: 16, bottom: 18, trailing: 16)
        
        let b = UIButton(configuration: config)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.heightAnchor.constraint(equalToConstant: 60).isActive = true
        b.isEnabled = false
        return b
    }()
    
    // MARK: - Stored
    
    private var selectedSchedule: [WeekDay] = [] {
        didSet {
            updateScheduleSubtitle()
            validate()
        }
    }
    
    private var selectedCategory: String? {
        didSet { validate() }
    }
    
    var onCreate: ((Tracker) -> Void)?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Новая привычка"
        navigationItem.largeTitleDisplayMode = .never
        
        setupUI()
        setupActions()
        
        updateScheduleSubtitle()
        validate()
    }
    
    // MARK: - UI
    
    private func setupUI() {
        let listCard = UIView()
        listCard.backgroundColor = .systemGray6
        listCard.layer.cornerRadius = 16
        listCard.translatesAutoresizingMaskIntoConstraints = false
        
        listCard.addSubview(categoryButton)
        listCard.addSubview(separator)
        listCard.addSubview(scheduleButton)
        
        NSLayoutConstraint.activate([
            categoryButton.topAnchor.constraint(equalTo: listCard.topAnchor),
            categoryButton.leadingAnchor.constraint(equalTo: listCard.leadingAnchor),
            categoryButton.trailingAnchor.constraint(equalTo: listCard.trailingAnchor),
            categoryButton.heightAnchor.constraint(equalToConstant: 75),
            
            separator.topAnchor.constraint(equalTo: categoryButton.bottomAnchor),
            separator.leadingAnchor.constraint(equalTo: listCard.leadingAnchor, constant: 16),
            separator.trailingAnchor.constraint(equalTo: listCard.trailingAnchor, constant: -16),
            
            scheduleButton.topAnchor.constraint(equalTo: separator.bottomAnchor),
            scheduleButton.leadingAnchor.constraint(equalTo: listCard.leadingAnchor),
            scheduleButton.trailingAnchor.constraint(equalTo: listCard.trailingAnchor),
            scheduleButton.heightAnchor.constraint(equalToConstant: 75),
            scheduleButton.bottomAnchor.constraint(equalTo: listCard.bottomAnchor)
        ])
        
        let topStack = UIStackView(arrangedSubviews: [
            nameField,
            warningLabel,
            listCard
        ])
        topStack.axis = .vertical
        topStack.translatesAutoresizingMaskIntoConstraints = false
        topStack.spacing = 8
        topStack.setCustomSpacing(24, after: nameField)
        
        let bottomStack = UIStackView(arrangedSubviews: [cancelButton, createButton])
        bottomStack.axis = .horizontal
        bottomStack.spacing = 16
        bottomStack.distribution = .fillEqually
        bottomStack.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(topStack)
        view.addSubview(bottomStack)
        
        NSLayoutConstraint.activate([
            topStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            topStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            topStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            bottomStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            bottomStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            bottomStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24)
        ])
    }
    
    private func setupActions() {
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        createButton.addTarget(self, action: #selector(createTapped), for: .touchUpInside)
        scheduleButton.addTarget(self, action: #selector(openSchedule), for: .touchUpInside)
    }
    
    // MARK: - Actions
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func createTapped() {
        view.endEditing(true)
        
        let tracker = Tracker(
            id: UUID(),
            name: nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            color: .systemBlue,
            emoji: "🙂",
            schedule: selectedSchedule
        )
        onCreate?(tracker)
        dismiss(animated: true)
    }
    
    @objc private func openSchedule() {
        let vc = ScheduleViewController()
        vc.selectedDays = selectedSchedule
        vc.onSelect = { [weak self] days in
            self?.selectedSchedule = days
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func nameChanged() {
        validate()
    }
    
    // MARK: - Validation
    
    private func validate() {
        let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let isValid = !name.isEmpty && name.count <= Constants.maxNameLength
        
        warningLabel.isHidden = name.count <= Constants.maxNameLength
        createButton.isEnabled = isValid
        
        var config = createButton.configuration
        config?.background.backgroundColor = isValid ? .black : .systemGray3
        createButton.configuration = config
    }
    
    // MARK: - UITextFieldDelegate
    
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        
        guard let current = textField.text,
              let r = Range(range, in: current) else { return true }
        
        let updated = current.replacingCharacters(in: r, with: string)
        let allowed = updated.count <= Constants.maxNameLength
        
        warningLabel.isHidden = allowed
        return allowed
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        validate()
        return true
    }
    
    // MARK: - Keyboard toolbar
    
    private func makeKeyboardToolbar() -> UIToolbar {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(title: "Готово", style: .done, target: self, action: #selector(doneTapped))
        
        toolbar.items = [flex, done]
        return toolbar
    }
    
    @objc private func doneTapped() {
        nameField.resignFirstResponder()
        validate()
    }
    
    // MARK: - Schedule subtitle
    
    private func updateScheduleSubtitle() {
        var config = scheduleButton.configuration
        config?.subtitle = scheduleSummaryText(for: selectedSchedule)
        scheduleButton.configuration = config
    }
    
    private func scheduleSummaryText(for days: [WeekDay]) -> String? {
        let set = Set(days)
        if set.isEmpty { return nil }
        
        let weekdays: Set<WeekDay> = [.monday, .tuesday, .wednesday, .thursday, .friday]
        let weekends: Set<WeekDay> = [.saturday, .sunday]
        let allDays = Set(WeekDay.allCases)
        
        if set == allDays { return "Каждый день" }
        if set == weekdays { return "Будние" }
        if set == weekends { return "Выходные" }
        
        let ordered = WeekDay.allCases.filter { set.contains($0) }
        return ordered.map { $0.rawValue }.joined(separator: ", ")
    }
    
    // MARK: - Factory
    
    private static func makeRowButton(title: String, subtitle: String? = nil) -> UIButton {
        var config = UIButton.Configuration.plain()
        
        config.title = title
        config.subtitle = subtitle
        config.titleAlignment = .leading
        
        config.baseForegroundColor = .black
        config.background.backgroundColor = .clear
        
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        
        config.subtitleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var out = incoming
            out.foregroundColor = UIColor.systemGray
            out.font = UIFont.systemFont(ofSize: 14)
            return out
        }
        
        config.image = UIImage(systemName: "chevron.right")
        config.imagePlacement = .trailing
        config.imagePadding = 8
        config.preferredSymbolConfigurationForImage =
        UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        
        let button = UIButton(configuration: config)
        button.contentHorizontalAlignment = .fill
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }
}
