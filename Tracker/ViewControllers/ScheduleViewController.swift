import UIKit

final class ScheduleViewController: UIViewController {

    // MARK: - Public

    var selectedDays: [WeekDay] = []
    var onSelect: (([WeekDay]) -> Void)?

    // MARK: - Constants

    private enum Constants {
        static let horizontalInset: CGFloat = 16
        static let titleTop: CGFloat = 27
        static let titleBottom: CGFloat = 24
        static let rowHeight: CGFloat = 75
        static let doneButtonHeight: CGFloat = 60
        static let doneButtonBottom: CGFloat = 16
        static let separatorLeft: CGFloat = 16
    }

    // MARK: - UI

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Расписание"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .black
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let cardView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.layer.cornerRadius = 16
        v.clipsToBounds = true
        v.backgroundColor = UIColor(red: 247/255, green: 248/255, blue: 249/255, alpha: 1)
        return v
    }()

    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.backgroundColor = .clear
        tv.isScrollEnabled = false
        tv.separatorStyle = .singleLine
        tv.tableFooterView = UIView(frame: .zero)
        return tv
    }()

    private lazy var doneButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Готово"
        config.baseForegroundColor = .white
        config.background.backgroundColor = .black
        config.background.cornerRadius = 16
        config.contentInsets = NSDirectionalEdgeInsets(top: 18, leading: 16, bottom: 18, trailing: 16)

        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: Constants.doneButtonHeight).isActive = true
        button.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Stored

    private var cardHeightConstraint: NSLayoutConstraint?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        setupLayout()
        updateCardHeight()
    }

    // MARK: - UI

    private func setupUI() {
        view.backgroundColor = .white
        setupNavigation()
    }

    private func setupNavigation() {
        navigationItem.hidesBackButton = true
        navigationItem.leftBarButtonItem = nil
        navigationItem.largeTitleDisplayMode = .never
        title = nil
    }

    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")

        tableView.separatorInset = UIEdgeInsets(
            top: 0,
            left: Constants.separatorLeft,
            bottom: 0,
            right: Constants.separatorLeft
        )
        tableView.separatorColor = UIColor(red: 174/255, green: 175/255, blue: 180/255, alpha: 1) // #AEAFB4
    }

    // MARK: - Layout

    private func setupLayout() {
        view.addSubview(titleLabel)
        view.addSubview(cardView)
        cardView.addSubview(tableView)
        view.addSubview(doneButton)

        NSLayoutConstraint.activate([
            // Title
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: Constants.titleTop),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            // Card
            cardView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: Constants.titleBottom),
            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Constants.horizontalInset),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Constants.horizontalInset),

            // Table
            tableView.topAnchor.constraint(equalTo: cardView.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),

            // Done button
            doneButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Constants.horizontalInset),
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Constants.horizontalInset),
            doneButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -Constants.doneButtonBottom)
        ])
    }

    private func updateCardHeight() {
        cardHeightConstraint?.isActive = false
        let height = CGFloat(WeekDay.allCases.count) * Constants.rowHeight
        let c = cardView.heightAnchor.constraint(equalToConstant: height)
        c.isActive = true
        cardHeightConstraint = c
    }

    // MARK: - Actions

    @objc private func doneTapped() {
        onSelect?(selectedDays)
        navigationController?.popViewController(animated: true)
    }

    @objc private func switchChanged(_ sender: UISwitch) {
        let day = WeekDay.allCases[sender.tag]

        if sender.isOn {
            guard !selectedDays.contains(day) else { return }
            selectedDays.append(day)
        } else {
            selectedDays.removeAll { $0 == day }
        }
    }
}

// MARK: - UITableViewDataSource

extension ScheduleViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        WeekDay.allCases.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let day = WeekDay.allCases[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
        cell.selectionStyle = .none

        cell.textLabel?.text = day.fullName
        cell.textLabel?.font = .systemFont(ofSize: 17)

        if indexPath.row == WeekDay.allCases.count - 1 {
            cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
        } else {
            cell.separatorInset = UIEdgeInsets(
                top: 0,
                left: Constants.separatorLeft,
                bottom: 0,
                right: Constants.separatorLeft
            )
        }

        let toggle = UISwitch()
        toggle.isOn = selectedDays.contains(day)
        toggle.onTintColor = .systemBlue
        toggle.thumbTintColor = .white
        toggle.tag = indexPath.row
        toggle.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)

        cell.accessoryView = toggle
        return cell
    }
}

// MARK: - UITableViewDelegate

extension ScheduleViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        Constants.rowHeight
    }
}
