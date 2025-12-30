import UIKit

final class CreateTrackerViewController: UIViewController, UITextFieldDelegate {

    // MARK: - Constants

    enum Constants {
        static let maxNameLength = 38
        static let warningText = "Ограничение 38 символов"
    }

    // MARK: - Collection models

    enum Section: Int, CaseIterable {
        case emoji
        case color

        var title: String {
            switch self {
            case .emoji: return "Emoji"
            case .color: return "Цвет"
            }
        }
    }

    enum Item: Hashable {
        case emoji(String)
        case color(UIColor)
    }

    // MARK: - UI

    let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Новая привычка"
        l.font = .systemFont(ofSize: 16, weight: .medium)
        l.textColor = .black
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    lazy var nameField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Введите название трекера"
        tf.backgroundColor = UIColor(red: 230/255, green: 232/255, blue: 235/255, alpha: 0.30)
        tf.layer.cornerRadius = 16
        tf.setLeftPaddingPoints(16)
        tf.font = .systemFont(ofSize: 17, weight: .regular)
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.heightAnchor.constraint(equalToConstant: 75).isActive = true

        tf.delegate = self
        tf.returnKeyType = .done
        tf.addTarget(self, action: #selector(nameChanged), for: .editingChanged)
        tf.inputAccessoryView = makeKeyboardToolbar()
        return tf
    }()

    let warningLabel: UILabel = {
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

    lazy var categoryButton: UIButton = Self.makeRowButton(title: "Категория", subtitle: nil)
    lazy var scheduleButton: UIButton = Self.makeRowButton(title: "Расписание", subtitle: nil)

    let separator: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 174/255, green: 175/255, blue: 180/255, alpha: 1)
        v.translatesAutoresizingMaskIntoConstraints = false
        v.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return v
    }()

    lazy var cancelButton: UIButton = {
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

    lazy var createButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Создать"
        config.baseForegroundColor = .white
        config.background.backgroundColor = .systemGray3
        config.background.cornerRadius = 16
        config.contentInsets = NSDirectionalEdgeInsets(top: 18, leading: 16, bottom: 18, trailing: 16)

        let b = UIButton(configuration: config)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.heightAnchor.constraint(equalToConstant: 60).isActive = true
        return b
    }()

    let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.alwaysBounceVertical = true
        sv.keyboardDismissMode = .interactive
        return sv
    }()

    let contentView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    lazy var listCard: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 247/255, green: 248/255, blue: 249/255, alpha: 1)
        v.layer.cornerRadius = 16
        v.clipsToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    lazy var selectionCollectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: makeCollectionLayout())
        cv.backgroundColor = .clear
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.delegate = self
        cv.allowsMultipleSelection = true
        cv.isScrollEnabled = false

        cv.register(EmojiCell.self, forCellWithReuseIdentifier: EmojiCell.reuseId)
        cv.register(ColorCell.self, forCellWithReuseIdentifier: ColorCell.reuseId)
        cv.register(
            SectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: SectionHeaderView.reuseId
        )

        return cv
    }()

    lazy var topStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [
            nameField,
            warningLabel,
            listCard,
            selectionCollectionView
        ])
        s.axis = .vertical
        s.translatesAutoresizingMaskIntoConstraints = false
        s.spacing = 8
        s.setCustomSpacing(24, after: nameField)
        s.setCustomSpacing(24, after: listCard)
        return s
    }()

    lazy var bottomStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [cancelButton, createButton])
        s.axis = .horizontal
        s.spacing = 16
        s.distribution = .fillEqually
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    // MARK: - Collection state

    var selectionCollectionHeightConstraint: NSLayoutConstraint?
    var dataSource: UICollectionViewDiffableDataSource<Section, Item>!

    var selectedEmojiIndexPath: IndexPath?
    var selectedColorIndexPath: IndexPath?
    var selectedEmoji: String?
    var selectedColor: UIColor?

    // MARK: - Data

    let emojis: [String] = [
        "🙂","😻","🌺","🐶","❤️","😱",
        "😇","😡","🥶","🤔","🙌","🍔",
        "🥦","🏓","🥇","🎸","🏝️","😪"
    ]

    let colors: [UIColor] = [
        UIColor(red: 1, green: 0.23, blue: 0.19, alpha: 1),
        UIColor(red: 1, green: 0.58, blue: 0.0, alpha: 1),
        UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1),
        UIColor(red: 0.35, green: 0.34, blue: 0.84, alpha: 1),
        UIColor(red: 0.2, green: 0.78, blue: 0.35, alpha: 1),
        UIColor(red: 1.0, green: 0.35, blue: 0.8, alpha: 1),

        UIColor(red: 1.0, green: 0.8, blue: 0.8, alpha: 1),
        UIColor(red: 0.35, green: 0.68, blue: 1.0, alpha: 1),
        UIColor(red: 0.2, green: 0.9, blue: 0.7, alpha: 1),
        UIColor(red: 0.2, green: 0.2, blue: 0.4, alpha: 1),
        UIColor(red: 1.0, green: 0.35, blue: 0.3, alpha: 1),
        UIColor(red: 1.0, green: 0.6, blue: 0.85, alpha: 1),

        UIColor(red: 1.0, green: 0.78, blue: 0.55, alpha: 1),
        UIColor(red: 0.45, green: 0.52, blue: 1.0, alpha: 1),
        UIColor(red: 0.35, green: 0.2, blue: 0.95, alpha: 1),
        UIColor(red: 0.65, green: 0.35, blue: 0.95, alpha: 1),
        UIColor(red: 0.55, green: 0.45, blue: 0.95, alpha: 1),
        UIColor(red: 0.2, green: 0.85, blue: 0.35, alpha: 1)
    ]

    // MARK: - Stored

    var onCreate: ((Tracker) -> Void)?

    private var selectedSchedule: [WeekDay] = [] {
        didSet {
            updateScheduleSubtitle()
            validate()
        }
    }

    private var selectedCategory: String? {
        didSet { validate() }
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        setupUI()
        setupActions()

        setupCollectionDataSource()
        applyCollectionSnapshot()

        updateScheduleSubtitle()
        validate()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateSelectionCollectionHeight()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.async { [weak self] in
            self?.updateSelectionCollectionHeight()
        }
    }

    // MARK: - Actions

    @objc func cancelTapped() {
        dismiss(animated: true)
    }

    @objc func createTapped() {
        view.endEditing(true)

        let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        let tracker = Tracker(
            id: UUID(),
            name: name,
            color: selectedColor ?? .systemBlue,
            emoji: selectedEmoji ?? "🙂",
            schedule: selectedSchedule
        )
        onCreate?(tracker)
        dismiss(animated: true)
    }

    @objc func openSchedule() {
        let vc = ScheduleViewController()
        vc.selectedDays = selectedSchedule
        vc.onSelect = { [weak self] days in
            self?.selectedSchedule = days
        }
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc func nameChanged() {
        validate()
    }

    @objc func doneTapped() {
        nameField.resignFirstResponder()
        validate()
    }

    // MARK: - Validation

    func validate() {
        let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let isValidName = !name.isEmpty && name.count <= Constants.maxNameLength

        warningLabel.isHidden = name.count <= Constants.maxNameLength

        createButton.isEnabled = true
        createButton.isUserInteractionEnabled = isValidName

        var config = createButton.configuration
        config?.background.backgroundColor = isValidName ? .black : .systemGray3
        config?.baseForegroundColor = .white
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

    // MARK: - Schedule subtitle

    func updateScheduleSubtitle() {
        var config = scheduleButton.configuration
        config?.subtitle = scheduleSummaryText(for: selectedSchedule)
        scheduleButton.configuration = config
    }

    func scheduleSummaryText(for days: [WeekDay]) -> String? {
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
}

