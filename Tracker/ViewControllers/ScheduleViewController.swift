import UIKit

final class ScheduleViewController: UIViewController {
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    
    private lazy var doneButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Готово"
        config.baseForegroundColor = .white
        config.background.backgroundColor = .black
        config.background.cornerRadius = 16
        config.contentInsets = NSDirectionalEdgeInsets(top: 18, leading: 16, bottom: 18, trailing: 16)
        
        let b = UIButton(configuration: config)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.heightAnchor.constraint(equalToConstant: 60).isActive = true
        b.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
        return b
    }()
    
    var selectedDays: [WeekDay] = []
    var onSelect: (([WeekDay]) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Расписание"
        navigationItem.largeTitleDisplayMode = .never
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(tableView)
        view.addSubview(doneButton)
        
        NSLayoutConstraint.activate([
            doneButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            doneButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: doneButton.topAnchor, constant: -12)
        ])
    }
    
    @objc private func doneTapped() {
        onSelect?(selectedDays)
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func switchChanged(_ sender: UISwitch) {
        let day = WeekDay.allCases[sender.tag]
        if sender.isOn {
            if !selectedDays.contains(day) { selectedDays.append(day) }
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
        
        cell.textLabel?.text = day.fullName
        cell.textLabel?.font = .systemFont(ofSize: 17)
        cell.selectionStyle = .none
        
        let sw = UISwitch()
        sw.isOn = selectedDays.contains(day)
        sw.onTintColor = .systemBlue      
        sw.thumbTintColor = .white
        sw.tag = indexPath.row
        sw.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)
        cell.accessoryView = sw
        
        return cell
    }
}

// MARK: - UITableViewDelegate

extension ScheduleViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 75 }
}

