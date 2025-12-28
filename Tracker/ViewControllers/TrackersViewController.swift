import UIKit

final class TrackersViewController: UIViewController {
    
    // MARK: - State
    
    private var selectedDate: Date = Date()
    
    // MARK: - UI
    
    private let emptyStateView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isHidden = true
        return v
    }()
    
    private let emptyImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "emptyTrackerIcon"))
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private let emptyLabel: UILabel = {
        let l = UILabel()
        l.text = "Что будем отслеживать?"
        l.font = .systemFont(ofSize: 12, weight: .medium)
        l.textColor = .black
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private lazy var dateContainerView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        
        v.backgroundColor = UIColor(
            red: 240/255,
            green: 240/255,
            blue: 240/255,
            alpha: 1
        )
        
        v.layer.cornerRadius = 12
        v.clipsToBounds = true
        
        NSLayoutConstraint.activate([
            v.widthAnchor.constraint(equalToConstant: 77),
            v.heightAnchor.constraint(equalToConstant: 34)
        ])
        
        return v
    }()
    
    private let dateLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 17)
        l.textColor = .black
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        l.setContentHuggingPriority(.required, for: .horizontal)
        l.setContentCompressionResistancePriority(.required, for: .horizontal)
        return l
    }()
    
    private let datePicker: UIDatePicker = {
        let p = UIDatePicker()
        p.preferredDatePickerStyle = .compact
        p.datePickerMode = .date
        p.maximumDate = Date()
        p.locale = Locale(identifier: "ru_RU")
        p.tintColor = .systemBlue
        p.translatesAutoresizingMaskIntoConstraints = false
        return p
    }()
    
    private let titleLabel = TrackersViewController.makeTitle("Трекеры")
    private let searchField = TrackersViewController.makeSearchField()
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 16
        layout.minimumInteritemSpacing = 9
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .white
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.dataSource = self
        cv.delegate = self
        cv.register(TrackerCell.self, forCellWithReuseIdentifier: TrackerCell.identifier)
        return cv
    }()
    
    // MARK: - ViewModel
    
    private lazy var viewModel = TrackersViewModel(delegate: self)
    
    // MARK: - Formatters
    
    private lazy var dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd.MM.yy"
        return f
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        configureNavBar()
        setupLayout()
        setupSearch()
        setupKeyboardDismiss()
        
        applySelectedDate(Date())
    }
    
    // MARK: - NavBar
    
    private func configureNavBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "plus"),
            style: .plain,
            target: self,
            action: #selector(addTracker)
        )
        navigationItem.leftBarButtonItem?.tintColor = .black
        
        navigationController?.navigationBar.tintColor = .systemBlue
        
        setupNavigationDatePicker()
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: dateContainerView)
    }
    
    private func setupNavigationDatePicker() {
        datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        
        dateContainerView.addSubview(dateLabel)
        dateContainerView.addSubview(datePicker)
        
        NSLayoutConstraint.activate([
            dateLabel.leadingAnchor.constraint(equalTo: dateContainerView.leadingAnchor),
            dateLabel.trailingAnchor.constraint(equalTo: dateContainerView.trailingAnchor),
            dateLabel.topAnchor.constraint(equalTo: dateContainerView.topAnchor),
            dateLabel.bottomAnchor.constraint(equalTo: dateContainerView.bottomAnchor),
            
            datePicker.leadingAnchor.constraint(equalTo: dateContainerView.leadingAnchor),
            datePicker.trailingAnchor.constraint(equalTo: dateContainerView.trailingAnchor),
            datePicker.topAnchor.constraint(equalTo: dateContainerView.topAnchor),
            datePicker.bottomAnchor.constraint(equalTo: dateContainerView.bottomAnchor)
        ])
        
        datePicker.alpha = 0.02
    }
    
    @objc private func dateChanged() {
        applySelectedDate(datePicker.date)
    }
    
    // MARK: - Layout
    
    private func setupLayout() {
        view.addSubview(titleLabel)
        view.addSubview(searchField)
        view.addSubview(collectionView)
        view.addSubview(emptyStateView)
        emptyStateView.addSubview(emptyImageView)
        emptyStateView.addSubview(emptyLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            searchField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            searchField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            searchField.heightAnchor.constraint(equalToConstant: 36),
            
            collectionView.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 8),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            emptyImageView.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            emptyImageView.topAnchor.constraint(equalTo: emptyStateView.topAnchor),
            emptyImageView.widthAnchor.constraint(equalToConstant: 80),
            emptyImageView.heightAnchor.constraint(equalToConstant: 80),
            
            emptyLabel.topAnchor.constraint(equalTo: emptyImageView.bottomAnchor, constant: 8),
            emptyLabel.leadingAnchor.constraint(equalTo: emptyStateView.leadingAnchor),
            emptyLabel.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor),
            emptyLabel.bottomAnchor.constraint(equalTo: emptyStateView.bottomAnchor)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func addTracker() {
        let vc = CreateTrackerViewController()
        
        vc.onCreate = { [weak self] tracker in
            guard let self else { return }
            self.viewModel.addTracker(tracker, to: "Без категории")
            self.viewModel.filterBy(date: self.selectedDate)
            self.reloadData()
        }
        
        let nav = UINavigationController(rootViewController: vc)
        
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = false
            sheet.preferredCornerRadius = 16
        } else {
            nav.modalPresentationStyle = .pageSheet
        }
        
        present(nav, animated: true)
    }
    
    private func applySelectedDate(_ date: Date) {
        selectedDate = date
        datePicker.date = date
        dateLabel.text = dateFormatter.string(from: date)
        
        viewModel.filterBy(date: date)
        reloadData()
    }
    
    // MARK: - Search
    
    private func setupSearch() {
        searchField.addTarget(self, action: #selector(searchChanged), for: .editingChanged)
    }
    
    @objc private func searchChanged() {
        viewModel.filterBy(search: searchField.text ?? "")
        reloadData()
    }
    
    private func reloadData() {
        let isEmpty = viewModel.filteredTrackers.isEmpty
        collectionView.isHidden = isEmpty
        emptyStateView.isHidden = !isEmpty
        collectionView.reloadData()
    }
    
    private func isFuture(_ date: Date) -> Bool {
        let cal = Calendar.current
        return cal.startOfDay(for: date) > cal.startOfDay(for: Date())
    }
    
    // MARK: - Keyboard
    
    private func setupKeyboardDismiss() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(endEditing))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc private func endEditing() {
        view.endEditing(true)
    }
}

// MARK: - StoreUpdateDelegate (получаем обновления от FRC)

extension TrackersViewController: StoreUpdateDelegate {
    func didUpdate(_ update: StoreUpdate) {
        viewModel.reloadFromStores()
        viewModel.filterBy(date: selectedDate)
        reloadData()
    }
}

// MARK: - UICollectionViewDataSource

extension TrackersViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.filteredTrackers.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: TrackerCell.identifier,
            for: indexPath
        ) as? TrackerCell else {
            return UICollectionViewCell()
        }
        
        let tracker = viewModel.filteredTrackers[indexPath.item]
        
        let completed = viewModel.isTrackerCompleted(tracker.id, on: selectedDate)
        let count = viewModel.completedCount(for: tracker.id)
        let future = isFuture(selectedDate)
        
        cell.delegate = self
        cell.configure(
            trackerName: tracker.name,
            emoji: tracker.emoji,
            color: tracker.color,
            completedCount: count,
            isCompleted: completed,
            isFutureDate: future
        )
        
        return cell
    }
}

// MARK: - TrackerCellDelegate

extension TrackersViewController: TrackerCellDelegate {
    
    func trackerCellDidTapComplete(_ cell: TrackerCell) {
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        if isFuture(selectedDate) { return }
        
        let tracker = viewModel.filteredTrackers[indexPath.item]
        
        if viewModel.isTrackerCompleted(tracker.id, on: selectedDate) {
            viewModel.uncompleteTracker(tracker.id, on: selectedDate)
        } else {
            viewModel.completeTracker(tracker.id, on: selectedDate)
        }
        
        collectionView.reloadItems(at: [indexPath])
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension TrackersViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let columns: CGFloat = 2
        let horizontalInset: CGFloat = 16
        let interItemSpacing: CGFloat = 9
        
        let totalSpacing = horizontalInset * 2 + interItemSpacing * (columns - 1)
        let availableWidth = collectionView.bounds.width - totalSpacing
        let itemWidth = floor(availableWidth / columns)
        return CGSize(width: itemWidth, height: 130)
    }
}

// MARK: - UI Factory

extension TrackersViewController {
    
    static func makeTitle(_ text: String) -> UILabel {
        let lbl = UILabel()
        lbl.text = text
        lbl.font = .systemFont(ofSize: 34, weight: .bold)
        lbl.textColor = .black
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }
    
    static func makeSearchField() -> UISearchTextField {
        let s = UISearchTextField()
        s.placeholder = "Поиск"
        
        s.backgroundColor = UIColor(
            red: 240/255,
            green: 240/255,
            blue: 240/255,
            alpha: 1
        )
        
        s.layer.cornerRadius = 8
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }
}

