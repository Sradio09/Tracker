import UIKit

final class CategoryListViewController: UIViewController {
    
    // MARK: - Public
    
    var onPicked: ((TrackerCategory) -> Void)?
    
    // MARK: - Constants
    
    private enum Constants {
        static let horizontalInset: CGFloat = 16
        static let titleTop: CGFloat = 27
        static let titleBottom: CGFloat = 24
        
        static let rowHeight: CGFloat = 75
        
        static let addButtonHeight: CGFloat = 60
        static let addButtonBottom: CGFloat = 16
        static let cardToButtonGap: CGFloat = 16
        
        static let emptyIconSize: CGFloat = 80
        static let emptyLabelTop: CGFloat = 8
    }
    
    // MARK: - ViewModel
    
    private let viewModel: CategoryListViewModel
    
    // MARK: - UI
    
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Категория"
        l.font = .systemFont(ofSize: 16, weight: .medium)
        l.textColor = .black
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let cardView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.layer.cornerRadius = 16
        v.clipsToBounds = true
        v.backgroundColor = UIColor(red: 247/255, green: 248/255, blue: 249/255, alpha: 1)
        return v
    }()
    
    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.backgroundColor = .clear
        tv.separatorStyle = .none
        tv.tableFooterView = UIView(frame: .zero)
        tv.rowHeight = Constants.rowHeight
        tv.dataSource = self
        tv.delegate = self
        tv.register(CategoryCell.self, forCellReuseIdentifier: CategoryCell.reuseId)
        return tv
    }()
    
    private lazy var addButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Добавить категорию"
        config.baseForegroundColor = .white
        config.background.backgroundColor = .black
        config.background.cornerRadius = 16
        config.contentInsets = NSDirectionalEdgeInsets(top: 18, leading: 16, bottom: 18, trailing: 16)
        
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.foregroundColor = UIColor.white
            return outgoing
        }
        
        let b = UIButton(configuration: config)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.heightAnchor.constraint(equalToConstant: Constants.addButtonHeight).isActive = true
        b.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
        return b
    }()
    
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
        l.text = "Привычки и события можно\nобъединить по смыслу"
        l.font = .systemFont(ofSize: 12, weight: .medium)
        l.textColor = .black
        l.numberOfLines = 0
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    // MARK: - Layout helpers
    
    private var cardHeightConstraint: NSLayoutConstraint?
    
    // MARK: - Init
    
    init(viewModel: CategoryListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        setupNavigation()
        setupBindings()
        setupLayout()
        reloadUI()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateCardHeight()
    }
    
    // MARK: - Setup
    
    private func setupNavigation() {
        navigationItem.hidesBackButton = true
        navigationItem.leftBarButtonItem = nil
        navigationItem.largeTitleDisplayMode = .never
        title = nil
    }
    
    private func setupBindings() {
        viewModel.onDataChanged = { [weak self] in
            self?.reloadUI()
        }
        viewModel.onError = { [weak self] message in
            self?.presentError(message)
        }
    }
    
    private func setupLayout() {
        view.addSubview(titleLabel)
        view.addSubview(cardView)
        cardView.addSubview(tableView)
        
        view.addSubview(emptyStateView)
        emptyStateView.addSubview(emptyImageView)
        emptyStateView.addSubview(emptyLabel)
        
        view.addSubview(addButton)
        
        cardHeightConstraint = cardView.heightAnchor.constraint(equalToConstant: 0)
        cardHeightConstraint?.isActive = true
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: Constants.titleTop),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            cardView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: Constants.titleBottom),
            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Constants.horizontalInset),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Constants.horizontalInset),
            
            cardView.bottomAnchor.constraint(lessThanOrEqualTo: addButton.topAnchor, constant: -Constants.cardToButtonGap),
            
            tableView.topAnchor.constraint(equalTo: cardView.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),
            
            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            emptyImageView.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            emptyImageView.topAnchor.constraint(equalTo: emptyStateView.topAnchor),
            emptyImageView.widthAnchor.constraint(equalToConstant: Constants.emptyIconSize),
            emptyImageView.heightAnchor.constraint(equalToConstant: Constants.emptyIconSize),
            
            emptyLabel.topAnchor.constraint(equalTo: emptyImageView.bottomAnchor, constant: Constants.emptyLabelTop),
            emptyLabel.leadingAnchor.constraint(equalTo: emptyStateView.leadingAnchor),
            emptyLabel.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor),
            emptyLabel.bottomAnchor.constraint(equalTo: emptyStateView.bottomAnchor),
            
            addButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Constants.horizontalInset),
            addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Constants.horizontalInset),
            addButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -Constants.addButtonBottom)
        ])
    }
    
    // MARK: - UI
    
    private func reloadUI() {
        let sections = viewModel.numberOfSections()
        let totalRows = (0..<sections).reduce(0) { $0 + viewModel.numberOfRows(in: $1) }
        let isEmpty = totalRows == 0
        
        cardView.isHidden = isEmpty
        emptyStateView.isHidden = !isEmpty
        
        tableView.reloadData()
        updateCardHeight()
    }
    
    private func updateCardHeight() {
        guard !cardView.isHidden else { return }
        
        tableView.layoutIfNeeded()
        
        let contentHeight = tableView.contentSize.height
        let maxHeight = addButton.frame.minY - cardView.frame.minY - Constants.cardToButtonGap
        let newHeight = min(contentHeight, max(0, maxHeight))
        
        cardHeightConstraint?.constant = newHeight
        tableView.isScrollEnabled = contentHeight > newHeight + 0.5
    }
    
    private func presentError(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ок", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Actions
    
    @objc private func addTapped() {
        let vc = NewCategoryViewController(screenTitle: "Новая категория", initialText: nil)
        vc.onSave = { [weak self] title in
            guard let self else { return }
            do {
                try TrackerCategoryStore().addCategory(title: title)
                self.reloadUI()
            } catch {
                self.presentError("Не удалось создать категорию")
            }
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func presentDeleteAlert(indexPath: IndexPath) {
        let alert = UIAlertController(
            title: nil,
            message: "Уверены что хотите удалить категорию?",
            preferredStyle: .actionSheet
        )
        
        alert.addAction(UIAlertAction(title: "Удалить", style: .destructive) { [weak self] _ in
            self?.viewModel.deleteCategory(at: indexPath)
        })
        alert.addAction(UIAlertAction(title: "Отменить", style: .cancel))
        
        if let pop = alert.popoverPresentationController {
            pop.sourceView = view
            pop.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.maxY, width: 1, height: 1)
        }
        
        present(alert, animated: true)
    }
    
    // MARK: - Context menu highlight preview (only card)
    
    private func cardOnlyPreview(for configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        guard let indexPath = configuration.identifier as? NSIndexPath,
              let cell = tableView.cellForRow(at: indexPath as IndexPath) as? CategoryCell else {
            return nil
        }
        
        let card = cell.cardViewForContextMenu
        
        let params = UIPreviewParameters()
        params.backgroundColor = .clear
        params.visiblePath = UIBezierPath(roundedRect: card.bounds, cornerRadius: 16)
        
        return UITargetedPreview(view: card, parameters: params)
    }
}

// MARK: - UITableViewDataSource

extension CategoryListViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.numberOfSections()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.numberOfRows(in: section)
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: CategoryCell.reuseId,
            for: indexPath
        ) as? CategoryCell else { return UITableViewCell() }
        
        let cat = viewModel.category(at: indexPath)
        cell.configure(title: cat.title, isSelected: viewModel.isSelected(at: indexPath))
        
        let rows = viewModel.numberOfRows(in: indexPath.section)
        cell.setSeparatorHidden(indexPath.row == rows - 1)
        
        return cell
    }
}

// MARK: - UITableViewDelegate + Context Menu

extension CategoryListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let picked = viewModel.didSelectRow(at: indexPath)
        onPicked?(picked)
        navigationController?.popViewController(animated: true)
    }
    
    func tableView(_ tableView: UITableView,
                   contextMenuConfigurationForRowAt indexPath: IndexPath,
                   point: CGPoint) -> UIContextMenuConfiguration? {
        
        UIContextMenuConfiguration(
            identifier: indexPath as NSIndexPath,
            previewProvider: nil
        ) { [weak self] _ in
            guard let self else { return nil }
            
            let edit = UIAction(title: "Редактировать") { _ in
                let currentTitle = self.viewModel.categoryTitle(at: indexPath)
                
                let vc = NewCategoryViewController(
                    screenTitle: "Редактирование категории",
                    initialText: currentTitle
                )
                
                vc.onSave = { [weak self] newTitle in
                    self?.viewModel.updateCategory(at: indexPath, newTitle: newTitle)
                }
                
                self.navigationController?.pushViewController(vc, animated: true)
            }
            
            let delete = UIAction(title: "Удалить", attributes: .destructive) { _ in
                self.presentDeleteAlert(indexPath: indexPath)
            }
            
            return UIMenu(children: [edit, delete])
        }
    }
    
    func tableView(_ tableView: UITableView,
                   previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        cardOnlyPreview(for: configuration)
    }
    
    func tableView(_ tableView: UITableView,
                   previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        cardOnlyPreview(for: configuration)
    }
}

