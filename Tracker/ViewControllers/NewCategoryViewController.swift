import UIKit

final class NewCategoryViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: - Public
    
    var onSave: ((String) -> Void)?
    
    // MARK: - UI
    
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16, weight: .medium)
        l.textColor = .black
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private lazy var textField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Введите название категории"
        tf.backgroundColor = UIColor(red: 230/255, green: 232/255, blue: 235/255, alpha: 0.30)
        tf.layer.cornerRadius = 16
        tf.setLeftPaddingPoints(16)
        tf.font = .systemFont(ofSize: 17, weight: .regular)
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.heightAnchor.constraint(equalToConstant: 75).isActive = true
        
        tf.delegate = self
        tf.returnKeyType = .done
        tf.addTarget(self, action: #selector(textChanged), for: .editingChanged)
        tf.inputAccessoryView = makeKeyboardToolbar()
        return tf
    }()
    
    private lazy var doneButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Готово"
        config.baseForegroundColor = .white
        config.background.backgroundColor = .systemGray3
        config.background.cornerRadius = 16
        config.contentInsets = NSDirectionalEdgeInsets(top: 18, leading: 16, bottom: 18, trailing: 16)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var out = incoming
            out.foregroundColor = UIColor.white
            return out
        }
        
        let b = UIButton(configuration: config)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.heightAnchor.constraint(equalToConstant: 60).isActive = true
        b.isEnabled = false
        b.isUserInteractionEnabled = false
        b.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
        return b
    }()
    
    // MARK: - Stored
    
    private let screenTitle: String
    private let initialText: String?
    
    // MARK: - Init
    
    init(screenTitle: String = "Новая категория", initialText: String? = nil) {
        self.screenTitle = screenTitle
        self.initialText = initialText
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        titleLabel.text = screenTitle
        textField.text = initialText
        
        setupUI()
        validate()
    }
    
    // MARK: - UI
    
    private func setupUI() {
        view.addSubview(titleLabel)
        view.addSubview(textField)
        view.addSubview(doneButton)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 27),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            textField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 38),
            textField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            textField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            doneButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            doneButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func doneTapped() {
        view.endEditing(true)
        
        let title = (textField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        
        onSave?(title)
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func textChanged() {
        validate()
    }
    
    @objc private func toolbarDoneTapped() {
        textField.resignFirstResponder()
        validate()
    }
    
    // MARK: - Validation
    
    private func validate() {
        let title = (textField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let enabled = !title.isEmpty
        
        doneButton.isEnabled = enabled
        doneButton.isUserInteractionEnabled = enabled
        
        var config = doneButton.configuration
        config?.background.backgroundColor = enabled ? .black : .systemGray3
        doneButton.configuration = config
    }
    
    // MARK: - Toolbar
    
    private func makeKeyboardToolbar() -> UIToolbar {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(title: "Готово", style: .done, target: self, action: #selector(toolbarDoneTapped))
        toolbar.items = [flex, done]
        
        return toolbar
    }
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        validate()
        return true
    }
}

