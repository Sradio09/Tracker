import UIKit

final class CreateTrackerViewController: UIViewController, UITextFieldDelegate {
    
    enum Constants {
        static let maxNameLength = 38
        static let warningText = NSLocalizedString("create_tracker.name.limit", comment: "Name length limit warning")
    }
    
    enum Section: Int, CaseIterable {
        case emoji
        case color
        
        var title: String {
            switch self {
            case .emoji: return NSLocalizedString("create_tracker.section.emoji", comment: "Emoji section")
            case .color: return NSLocalizedString("create_tracker.section.color", comment: "Color section")
            }
        }
    }
    
    enum Item: Hashable {
        case emoji(String)
        case color(UIColor)
    }
    
    enum Mode {
        case create
        case edit(tracker: Tracker, categoryTitle: String?, completedDays: Int)
    }
    
    // MARK: - UI
    
    // MARK: - Mode
    
    private let mode: Mode
    var onUpdate: ((Tracker, String?) -> Void)?
    
    private var editTrackerId: UUID?
    private var editIsPinned: Bool = false
    
    private var pendingEmojiIndexPath: IndexPath?
    private var pendingColorIndexPath: IndexPath?
    
    
    let titleLabel: UILabel = {
        let l = UILabel()
        l.text = NSLocalizedString("create_tracker.title", comment: "Create tracker title")
        l.font = .systemFont(ofSize: 16, weight: .medium)
        l.textColor = AppColors.textPrimary
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let daysLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 32, weight: .bold)
        l.textColor = AppColors.textPrimary
        l.textAlignment = .center
        l.numberOfLines = 1
        l.isHidden = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    lazy var nameField: UITextField = {
        let tf = UITextField()
        tf.placeholder = NSLocalizedString("create_tracker.name.placeholder", comment: "Name placeholder")
        tf.backgroundColor = AppColors.inputBackground
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
        label.textColor = AppColors.accentRed
        label.font = .systemFont(ofSize: 17, weight: .regular)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var categoryButton: UIButton = Self.makeRowButton(title: NSLocalizedString("create_tracker.category", comment: "Category"), subtitle: nil)
    lazy var scheduleButton: UIButton = Self.makeRowButton(title: NSLocalizedString("create_tracker.schedule", comment: "Schedule"), subtitle: nil)
    
    let separator: UIView = {
        let v = UIView()
        v.backgroundColor = AppColors.separator
        v.translatesAutoresizingMaskIntoConstraints = false
        v.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return v
    }()
    
    lazy var cancelButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = NSLocalizedString("common.cancel", comment: "Cancel")
        config.baseForegroundColor = AppColors.accentRed
        config.background.backgroundColor = AppColors.background
        config.background.cornerRadius = 16
        config.contentInsets = NSDirectionalEdgeInsets(top: 18, leading: 16, bottom: 18, trailing: 16)
        
        let b = UIButton(configuration: config)
        b.layer.cornerRadius = 16
        b.clipsToBounds = true
        b.layer.borderWidth = 1
        b.layer.borderColor = AppColors.accentRed.cgColor
        b.translatesAutoresizingMaskIntoConstraints = false
        b.heightAnchor.constraint(equalToConstant: 60).isActive = true
        return b
    }()
    
    lazy var createButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = NSLocalizedString("common.create", comment: "Create")
        config.baseForegroundColor = AppColors.primaryButtonTitle
        config.background.backgroundColor = AppColors.disabledButtonBackground
        config.background.cornerRadius = 16
        config.contentInsets = NSDirectionalEdgeInsets(top: 18, leading: 16, bottom: 18, trailing: 16)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.foregroundColor = AppColors.primaryButtonTitle
            return outgoing
        }
        
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
        v.backgroundColor = AppColors.inputBackground
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
    
    // MARK: - Data
    
    let emojis: [String] = [
        "🙂","😻","🌺","🐶","❤️","😱",
        "😇","😡","🥶","🤔","🙌","🍔",
        "🥦","🏓","🥇","🎸","🏝️","😪"
    ]
    let colors: [UIColor] = AppColors.selectionColors
    
    // MARK: - Stored
    
    var onCreate: ((Tracker, String?) -> Void)?
    
    var selectedSchedule: [WeekDay] = [] {
        didSet { updateScheduleSubtitle(); validate() }
    }
    
    var selectedCategory: String? {
        didSet { updateCategorySubtitle(); validate() }
    }
    
    var selectedEmoji: String?
    var selectedColor: UIColor?
    // MARK: - Init
    
    init(mode: Mode = .create) {
        self.mode = mode
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        return nil
    }
    
    
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.background
        
        setupUI()
        setupActions()
        
        setupCollectionDataSource()
        applyCollectionSnapshot()
        
        updateScheduleSubtitle()
        updateCategorySubtitle()
        configureForMode()
        validate()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateSelectionCollectionHeight()
    }
    
    // MARK: - Actions
    
    @objc func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc func createTapped() {
        view.endEditing(true)
        
        let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        switch mode {
        case .create:
            let tracker = Tracker(
                id: UUID(),
                name: name,
                color: selectedColor ?? AppColors.accentBlue,
                emoji: selectedEmoji ?? "🙂",
                schedule: selectedSchedule,
                isPinned: false
            )
            onCreate?(tracker, selectedCategory)
            
        case .edit:
            guard let id = editTrackerId else {
                assertionFailure("Edit mode but tracker id is missing")
                return
            }
            
            let tracker = Tracker(
                id: id,
                name: name,
                color: selectedColor ?? AppColors.accentBlue,
                emoji: selectedEmoji ?? "🙂",
                schedule: selectedSchedule,
                isPinned: editIsPinned
            )
            onUpdate?(tracker, selectedCategory)
        }
        
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
    
    @objc func openCategory() {
        let store = TrackerCategoryStore()
        let vm = CategoryListViewModel(store: store, selectedTitle: selectedCategory)
        
        let vc = CategoryListViewController(viewModel: vm)
        vc.onPicked = { [weak self] category in
            self?.selectedCategory = category.title
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func doneTapped() {
        nameField.resignFirstResponder()
        validate()
    }
    
    @objc func nameChanged() {
        validate()
    }
    
    // MARK: - Subtitles
    
    func updateCategorySubtitle() {
        var config = categoryButton.configuration
        config?.subtitle = selectedCategory
        categoryButton.configuration = config
    }
    
    
    // MARK: - Mode configuration
    
    private func configureForMode() {
        switch mode {
        case .create:
            titleLabel.text = NSLocalizedString("create_tracker.title", comment: "Create tracker title")
            var c = createButton.configuration
            c?.title = NSLocalizedString("common.create", comment: "Create")
            createButton.configuration = c
            
        case .edit(let tracker, let categoryTitle, let completedDays):
            titleLabel.text = NSLocalizedString("tracker.edit.title", comment: "Edit tracker title")
            var c = createButton.configuration
            c?.title = NSLocalizedString("common.save", comment: "Save")
            createButton.configuration = c
            
            editTrackerId = tracker.id
            editIsPinned = tracker.isPinned
            
            // Days label
            let daysText = String.localizedStringWithFormat(
                NSLocalizedString("stats.days_count", comment: "Days count"),
                completedDays
            )
            daysLabel.text = daysText
            daysLabel.isHidden = false
            
            if daysLabel.superview == nil {
                topStack.insertArrangedSubview(daysLabel, at: 0)
                topStack.setCustomSpacing(24, after: daysLabel)
            }
            
            // Prefill
            nameField.text = tracker.name
            selectedSchedule = tracker.schedule
            selectedCategory = categoryTitle
            selectedEmoji = tracker.emoji
            selectedColor = tracker.color
            
            
            if let emojiIndex = emojis.firstIndex(of: tracker.emoji) {
                pendingEmojiIndexPath = IndexPath(item: emojiIndex, section: Section.emoji.rawValue)
                selectedEmojiIndexPath = pendingEmojiIndexPath
            }
            if let colorIndex = colors.firstIndex(where: { $0.isEqual(tracker.color) }) {
                pendingColorIndexPath = IndexPath(item: colorIndex, section: Section.color.rawValue)
                selectedColorIndexPath = pendingColorIndexPath
            }
        }
    }
    
    func applyInitialSelectionIfNeeded() {
        if let emoji = pendingEmojiIndexPath {
            selectionCollectionView.selectItem(at: emoji, animated: false, scrollPosition: [])
            pendingEmojiIndexPath = nil
        }
        if let color = pendingColorIndexPath {
            selectionCollectionView.selectItem(at: color, animated: false, scrollPosition: [])
            pendingColorIndexPath = nil
        }
    }
    // MARK: - Validation
    
    func validate() {
        let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let isValidName = !name.isEmpty && name.count <= Constants.maxNameLength
        
        warningLabel.isHidden = name.count <= Constants.maxNameLength
        
        let isValid = isValidName
        && selectedEmoji != nil
        && selectedColor != nil
        
        createButton.isEnabled = isValid
        createButton.isUserInteractionEnabled = isValid
        
        var config = createButton.configuration
        config?.background.backgroundColor = isValid ? AppColors.primaryButtonBackground : AppColors.disabledButtonBackground
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
}


