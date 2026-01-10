import UIKit

final class TrackersViewController: UIViewController {
    
    private let initialDate: Date
    private var selectedDate: Date
    private var selectedFilterOption: FiltersViewController.Option = .all
    
    // MARK: - Init
    
    init(initialDate: Date = Date()) {
        self.initialDate = initialDate
        self.selectedDate = initialDate
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        self.initialDate = Date()
        self.selectedDate = self.initialDate
        super.init(coder: coder)
    }
    
    // MARK: - UI
    
    private let emptyStateView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isHidden = true
        return v
    }()
    
    private let emptyImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    
    private let emptyLabel: UILabel = {
        let l = UILabel()
        l.text = NSLocalizedString("trackers.empty.title", comment: "Empty title")
        l.font = .systemFont(ofSize: 12, weight: .medium)
        l.textColor = AppColors.textPrimary
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private lazy var dateContainerView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        
        v.backgroundColor = AppColors.surface
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
        l.textColor = UIColor.black
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
        p.tintColor = AppColors.accentBlue
        p.backgroundColor = AppColors.background
        p.translatesAutoresizingMaskIntoConstraints = false
        return p
    }()
    
    private let titleLabel = TrackersViewController.makeTitle(NSLocalizedString("trackers.title", comment: "Trackers title"))
    private let searchField = TrackersViewController.makeSearchField()
    
    private lazy var filtersButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = NSLocalizedString("filters.button", comment: "Filters")
        config.baseBackgroundColor = AppColors.accentBlue
        config.baseForegroundColor = .white
        config.cornerStyle = .large
        
        let btn = UIButton(configuration: config)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(didTapFilters), for: .touchUpInside)
        return btn
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 16
        layout.minimumInteritemSpacing = 9
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        layout.headerReferenceSize = CGSize(width: 0, height: 32)
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = AppColors.background
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.dataSource = self
        cv.delegate = self
        
        cv.register(TrackerCell.self, forCellWithReuseIdentifier: TrackerCell.identifier)
        
        cv.register(
            SectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: SectionHeaderView.reuseId
        )
        
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
        view.backgroundColor = AppColors.background
    
        configureNavBar()
        setupLayout()
        setupSearch()
        setupKeyboardDismiss()
        
        applySelectedDate(initialDate)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AnalyticsService.shared.report(event: .open, screen: .main)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        AnalyticsService.shared.report(event: .close, screen: .main)
    }
    
    // MARK: - NavBar
    
    private func configureNavBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "plus"),
            style: .plain,
            target: self,
            action: #selector(addTracker)
        )
        navigationItem.leftBarButtonItem?.tintColor = AppColors.textPrimary
        
        navigationController?.navigationBar.tintColor = AppColors.accentBlue
        
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
        view.addSubview(filtersButton)
        
        emptyStateView.addSubview(emptyImageView)
        emptyStateView.addSubview(emptyLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            searchField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            searchField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            searchField.heightAnchor.constraint(equalToConstant: 36),
            
            collectionView.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 34),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            filtersButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 130),
            filtersButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -130),
            filtersButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            filtersButton.heightAnchor.constraint(equalToConstant: 50),
            
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
        
        collectionView.alwaysBounceVertical = true
        updateCollectionInsetsForFiltersButton(isHidden: filtersButton.isHidden)
    }
    
    // MARK: - Actions
    
    @objc private func addTracker() {
        AnalyticsService.shared.report(event: .click, screen: .main, item: .addTrack)
        
        let vc = CreateTrackerViewController()
        
        vc.onCreate = { [weak self] tracker, categoryTitle in
            guard let self else { return }
            self.viewModel.addTracker(tracker, categoryTitle: categoryTitle)
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
    
    // MARK: - Filters
    
    @objc private func didTapFilters() {
        AnalyticsService.shared.report(event: .click, screen: .main, item: .filter)
        
        let vc = FiltersViewController()
        vc.selectedOption = selectedFilterOption
        vc.onSelect = { [weak self] option in
            guard let self else { return }
            self.applyFilterSelection(option)
        }
        
        vc.modalPresentationStyle = .pageSheet
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = false
            sheet.preferredCornerRadius = 16
        }
        present(vc, animated: true)
    }
    
    private func applyFilterSelection(_ option: FiltersViewController.Option) {
        selectedFilterOption = option
        
        switch option {
        case .all:
            viewModel.setFilter(.all)
        case .today:
            viewModel.setFilter(.all)
            applySelectedDate(Date())
        case .completed:
            viewModel.setFilter(.completed)
        case .uncompleted:
            viewModel.setFilter(.uncompleted)
        }
        
        presentedViewController?.dismiss(animated: true)
        reloadData()
    }
    
    private func updateFiltersButtonAppearance() {
        if viewModel.isFilterActive {
            filtersButton.configuration?.baseForegroundColor = AppColors.accentRed
        } else {
            filtersButton.configuration?.baseForegroundColor = .white
        }
    }
    
    private func updateCollectionInsetsForFiltersButton(isHidden: Bool) {
        let baseBottom: CGFloat = 16
        if isHidden {
            collectionView.contentInset.bottom = baseBottom
            collectionView.verticalScrollIndicatorInsets.bottom = baseBottom
        } else {
            let extra = 50 + 16 + baseBottom
            collectionView.contentInset.bottom = extra
            collectionView.verticalScrollIndicatorInsets.bottom = extra
        }
    }
    
    // MARK: - Search
    
    private func setupSearch() {
        searchField.addTarget(self, action: #selector(searchChanged), for: .editingChanged)
    }
    
    @objc private func searchChanged() {
        viewModel.filterBy(search: searchField.text ?? "")
        reloadData()
    }
    
    private var isSearchActive: Bool {
        !(searchField.text ?? "").isEmpty
    }
    
    private func reloadData() {
        let hasAnyTrackers = viewModel.hasAnyTrackers()
        let hasTrackersForSelectedDay = viewModel.hasTrackers(for: selectedDate)
        
        let shouldHideFiltersButton = !hasTrackersForSelectedDay
        filtersButton.isHidden = shouldHideFiltersButton
        updateCollectionInsetsForFiltersButton(isHidden: shouldHideFiltersButton)
        updateFiltersButtonAppearance()
        
        let isEmpty = viewModel.numberOfSections() == 0
        
        collectionView.isHidden = isEmpty
        emptyStateView.isHidden = !isEmpty
        
        if isEmpty {
            if isSearchActive {
                emptyImageView.image = UIImage(named: "emptySearchIcon")
                emptyLabel.text = NSLocalizedString("trackers.empty.nothingFound", comment: "Nothing found")
            } else {
                emptyImageView.image = UIImage(named: "emptyTrackerIcon")
                emptyLabel.text = NSLocalizedString("trackers.empty.title", comment: "Empty title")
            }
        }
        
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
    
    // MARK: - Delete alert
    
    private func presentDeleteAlert(trackerId: UUID) {
        let alert = UIAlertController(
            title: nil,
            message: NSLocalizedString("trackers.delete.message", comment: "Delete tracker message"),
            preferredStyle: .actionSheet
        )
        
        let delete = UIAlertAction(title: NSLocalizedString("common.delete", comment: "Delete"), style: .destructive) { [weak self] _ in
            guard let self else { return }
            self.viewModel.deleteTracker(trackerId)
            self.viewModel.filterBy(date: self.selectedDate)
            self.reloadData()
        }
        
        let cancel = UIAlertAction(title: NSLocalizedString("common.cancel", comment: "Cancel"), style: .cancel)
        
        alert.addAction(delete)
        alert.addAction(cancel)
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = self.view
            popover.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.maxY, width: 1, height: 1)
        }
        
        present(alert, animated: true)
    }
    
    // MARK: - Context Menu Highlight Preview
    
    private func cardOnlyPreview(for configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        guard let indexPath = configuration.identifier as? NSIndexPath,
              let cell = collectionView.cellForItem(at: indexPath as IndexPath) as? TrackerCell else {
            return nil
        }
        
        let cardView = cell.cardViewForContextMenu
        
        let params = UIPreviewParameters()
        params.backgroundColor = .clear
        params.visiblePath = UIBezierPath(roundedRect: cardView.bounds, cornerRadius: 16)
        
        return UITargetedPreview(view: cardView, parameters: params)
    }
}

// MARK: - StoreUpdateDelegate

extension TrackersViewController: StoreUpdateDelegate {
    func didUpdate(_ update: StoreUpdate) {
        viewModel.reloadFromStores()
        viewModel.filterBy(date: selectedDate)
        reloadData()
    }
}

// MARK: - UICollectionViewDataSource

extension TrackersViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        viewModel.numberOfSections()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.numberOfItems(in: section)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: TrackerCell.identifier,
            for: indexPath
        ) as? TrackerCell else {
            return UICollectionViewCell()
        }
        
        let tracker = viewModel.tracker(at: indexPath)
        
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
            isFutureDate: future,
            isPinned: tracker.isPinned
        )
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        
        guard kind == UICollectionView.elementKindSectionHeader else {
            return UICollectionReusableView()
        }
        
        guard let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: SectionHeaderView.reuseId,
            for: indexPath
        ) as? SectionHeaderView else {
            assertionFailure("Expected SectionHeaderView")
            return UICollectionReusableView()
        }
        
        if let title = viewModel.sectionTitle(indexPath.section) {
            header.configure(title: title)
        } else {
            header.configure(title: "")
        }
        
        return header
    }
}

// MARK: - TrackerCellDelegate

extension TrackersViewController: TrackerCellDelegate {
    
    func trackerCellDidTapComplete(_ cell: TrackerCell) {
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        if isFuture(selectedDate) { return }
        
        AnalyticsService.shared.report(event: .click, screen: .main, item: .track)
        
        let tracker = viewModel.tracker(at: indexPath)
        
        if viewModel.isTrackerCompleted(tracker.id, on: selectedDate) {
            viewModel.uncompleteTracker(tracker.id, on: selectedDate)
        } else {
            viewModel.completeTracker(tracker.id, on: selectedDate)
        }
        
        collectionView.reloadItems(at: [indexPath])
    }
}

// MARK: - UICollectionViewDelegateFlowLayout + Context Menu

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
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        if viewModel.isUncategorizedSection(section) {
            return .zero
        }
        return CGSize(width: collectionView.bounds.width, height: 32)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        contextMenuConfigurationForItemAt indexPath: IndexPath,
                        point: CGPoint) -> UIContextMenuConfiguration? {
        
        let tracker = viewModel.tracker(at: indexPath)
        
        return UIContextMenuConfiguration(
            identifier: indexPath as NSIndexPath,
            previewProvider: nil
        ) { [weak self] _ in
            guard let self else { return nil }
            
            let pinTitleKey = tracker.isPinned ? "trackers.context.unpin" : "trackers.context.pin"
            let pinAction = UIAction(title: NSLocalizedString(pinTitleKey, comment: "Pin/Unpin")) { _ in
                self.viewModel.setPinned(!tracker.isPinned, for: tracker.id)
                self.viewModel.filterBy(date: self.selectedDate)
                self.reloadData()
            }
            
            let editAction = UIAction(title: NSLocalizedString("common.edit", comment: "Edit")) { _ in
                AnalyticsService.shared.report(event: .click, screen: .main, item: .edit)
                
                let categoryTitle = self.viewModel.categoryTitle(for: tracker.id)
                let days = self.viewModel.completedCount(for: tracker.id)
                
                let vc = CreateTrackerViewController(mode: .edit(tracker: tracker, categoryTitle: categoryTitle, completedDays: days))
                vc.onUpdate = { [weak self] updatedTracker, updatedCategoryTitle in
                    guard let self else { return }
                    self.viewModel.updateTracker(updatedTracker, categoryTitle: updatedCategoryTitle)
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
                
                self.present(nav, animated: true)
            }
            
            let deleteAction = UIAction(title: NSLocalizedString("common.delete", comment: "Delete"), attributes: .destructive) { _ in
                AnalyticsService.shared.report(event: .click, screen: .main, item: .delete)
                self.presentDeleteAlert(trackerId: tracker.id)
            }
            
            return UIMenu(children: [pinAction, editAction, deleteAction])
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        cardOnlyPreview(for: configuration)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        cardOnlyPreview(for: configuration)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        
        if viewModel.isUncategorizedSection(section) {
            return UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        }
        
        return UIEdgeInsets(top: 0, left: 16, bottom: 16, right: 16)
    }
}

// MARK: - UI Factory

extension TrackersViewController {
    
    static func makeTitle(_ text: String) -> UILabel {
        let lbl = UILabel()
        lbl.text = text
        lbl.font = .systemFont(ofSize: 34, weight: .bold)
        lbl.textColor = AppColors.textPrimary
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }
    
    static func makeSearchField() -> UISearchTextField {
        let s = UISearchTextField()
        s.attributedPlaceholder = NSAttributedString(
            string: NSLocalizedString("common.search", comment: "Search"),
            attributes: [
                .foregroundColor: AppColors.searchText
            ]
        )
        s.backgroundColor = AppColors.searchField
        s.textColor = AppColors.searchText
        s.tintColor = AppColors.searchText
        s.leftView?.tintColor = AppColors.searchText
        s.layer.cornerRadius = 8
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }
}
