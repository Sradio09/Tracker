import UIKit

final class StatisticsViewController: UIViewController {
    
    // MARK: - UI
    
    private let tableView = UITableView(frame: .zero, style: .plain)
    
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
        iv.image = UIImage(named: "emptyStatistics")
        return iv
    }()
    
    private let emptyLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.textAlignment = .center
        l.numberOfLines = 0
        l.font = .systemFont(ofSize: 12, weight: .medium)
        l.textColor = AppColors.textPrimary
        l.text = NSLocalizedString("statistics.empty", comment: "Empty statistics placeholder")
        return l
    }()
    
    // MARK: - Data
    
    private let viewModel = StatisticsViewModel()
    
    private enum Row: Int, CaseIterable {
        case bestPeriod
        case perfectDays
        case completed
        case average
        
        var title: String {
            switch self {
            case .bestPeriod: return NSLocalizedString("statistics.bestPeriod", comment: "Best period")
            case .perfectDays: return NSLocalizedString("statistics.perfectDays", comment: "Perfect days")
            case .completed: return NSLocalizedString("statistics.completed", comment: "Completed")
            case .average: return NSLocalizedString("statistics.average", comment: "Average")
            }
        }
    }
    
    private var metrics = StatisticsMetrics(completed: 0, bestPeriod: 0, perfectDays: 0, average: 0)
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.background
        title = NSLocalizedString("statistics.title", comment: "Statistics screen title")
        navigationController?.navigationBar.prefersLargeTitles = true
        
        setupTable()
        setupEmptyState()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
    }
    
    // MARK: - Setup
    
    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        
        tableView.rowHeight = 90
        tableView.estimatedRowHeight = 90
        tableView.sectionHeaderTopPadding = 0
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(StatisticsCell.self, forCellReuseIdentifier: StatisticsCell.reuseId)
        
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 77),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupEmptyState() {
        view.addSubview(emptyStateView)
        emptyStateView.addSubview(emptyImageView)
        emptyStateView.addSubview(emptyLabel)
        
        NSLayoutConstraint.activate([
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
    
    // MARK: - Reload
    
    private func reload() {
        metrics = viewModel.loadMetrics()
        let isEmpty = metrics.completed == 0
        
        emptyStateView.isHidden = !isEmpty
        tableView.isHidden = isEmpty
        
        if isEmpty {
            emptyImageView.image = UIImage(named: "emptyStatistics")
        }
        
        tableView.reloadData()
    }
}

// MARK: - UITableViewDataSource

extension StatisticsViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        Row.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: StatisticsCell.reuseId,
            for: indexPath
        ) as? StatisticsCell else {
            assertionFailure("Expected StatisticsCell")
            return UITableViewCell()
        }

        guard let row = Row(rawValue: indexPath.section) else {
            assertionFailure("Unexpected section: \(indexPath.section)")
            return cell
        }
        let value: Int
        
        switch row {
        case .bestPeriod: value = metrics.bestPeriod
        case .perfectDays: value = metrics.perfectDays
        case .completed: value = metrics.completed
        case .average: value = metrics.average
        }
        
        cell.configure(value: value, title: row.title)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension StatisticsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        90
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        section == Row.allCases.count - 1 ? 0 : 12
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        UIView()
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        0.01
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        UIView()
    }
}
