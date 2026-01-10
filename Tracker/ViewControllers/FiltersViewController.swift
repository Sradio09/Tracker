import UIKit

final class FiltersViewController: UIViewController {

    enum Option: Int, CaseIterable {
        case all, today, completed, uncompleted

        var title: String {
            switch self {
            case .all: return NSLocalizedString("filters.all", comment: "")
            case .today: return NSLocalizedString("filters.today", comment: "")
            case .completed: return NSLocalizedString("filters.completed", comment: "")
            case .uncompleted: return NSLocalizedString("filters.uncompleted", comment: "")
            }
        }
    }

    // MARK: - Public

    var selectedOption: Option = .all
    var onSelect: ((Option) -> Void)?

    // MARK: - Constants

    private enum Constants {
        static let horizontalInset: CGFloat = 16
        static let titleTop: CGFloat = 27
        static let titleBottom: CGFloat = 24
        static let rowHeight: CGFloat = 75
    }

    // MARK: - UI

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = NSLocalizedString("filters.title", comment: "")
        l.font = .systemFont(ofSize: 16, weight: .medium)
        l.textColor = AppColors.textPrimary
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let cardView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.layer.cornerRadius = 16
        v.clipsToBounds = true
        v.backgroundColor = AppColors.inputBackground
        return v
    }()

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.backgroundColor = .clear
        tv.separatorStyle = .none
        tv.tableFooterView = UIView(frame: .zero)
        tv.rowHeight = Constants.rowHeight
        tv.isScrollEnabled = false

        tv.dataSource = self
        tv.delegate = self

        tv.register(FilterCell.self, forCellReuseIdentifier: FilterCell.reuseId)
        return tv
    }()

    private var cardHeightConstraint: NSLayoutConstraint?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.background

        setupLayout()
        reloadUI()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateCardHeight()
    }

    // MARK: - Layout

    private func setupLayout() {
        view.addSubview(titleLabel)
        view.addSubview(cardView)
        cardView.addSubview(tableView)

        cardHeightConstraint = cardView.heightAnchor.constraint(equalToConstant: 0)
        cardHeightConstraint?.isActive = true

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: Constants.titleTop),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            cardView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: Constants.titleBottom),
            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Constants.horizontalInset),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Constants.horizontalInset),

            tableView.topAnchor.constraint(equalTo: cardView.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor)
        ])
    }

    private func reloadUI() {
        tableView.reloadData()
        updateCardHeight()
    }

    private func updateCardHeight() {
        tableView.layoutIfNeeded()
        cardHeightConstraint?.constant = tableView.contentSize.height
    }
}

// MARK: - UITableViewDataSource

extension FiltersViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Option.allCases.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: FilterCell.reuseId,
            for: indexPath
        ) as? FilterCell else { return UITableViewCell() }

        guard let option = Option(rawValue: indexPath.row) else { return cell }
        let showCheckmark =
            option == selectedOption &&
            (option == .completed || option == .uncompleted)

        let isLast = indexPath.row == Option.allCases.count - 1
        cell.configure(title: option.title, showCheckmark: showCheckmark, hideSeparator: isLast)

        return cell
    }
}

// MARK: - UITableViewDelegate

extension FiltersViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let option = Option(rawValue: indexPath.row) else { return }
        onSelect?(option)
    }
}
