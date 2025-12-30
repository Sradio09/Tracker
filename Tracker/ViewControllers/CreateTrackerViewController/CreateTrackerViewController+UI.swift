import UIKit

extension CreateTrackerViewController {
    
    func setupUI() {
        view.addSubview(titleLabel)
        view.addSubview(bottomStack)
        view.addSubview(scrollView)
        
        scrollView.addSubview(contentView)
        contentView.addSubview(topStack)
        
        listCard.addSubview(categoryButton)
        listCard.addSubview(separator)
        listCard.addSubview(scheduleButton)
        
        NSLayoutConstraint.activate([
            categoryButton.topAnchor.constraint(equalTo: listCard.topAnchor),
            categoryButton.leadingAnchor.constraint(equalTo: listCard.leadingAnchor),
            categoryButton.trailingAnchor.constraint(equalTo: listCard.trailingAnchor),
            categoryButton.heightAnchor.constraint(equalToConstant: 75),
            
            separator.topAnchor.constraint(equalTo: categoryButton.bottomAnchor),
            separator.leadingAnchor.constraint(equalTo: listCard.leadingAnchor, constant: 16),
            separator.trailingAnchor.constraint(equalTo: listCard.trailingAnchor, constant: -16),
            
            scheduleButton.topAnchor.constraint(equalTo: separator.bottomAnchor),
            scheduleButton.leadingAnchor.constraint(equalTo: listCard.leadingAnchor),
            scheduleButton.trailingAnchor.constraint(equalTo: listCard.trailingAnchor),
            scheduleButton.heightAnchor.constraint(equalToConstant: 75),
            scheduleButton.bottomAnchor.constraint(equalTo: listCard.bottomAnchor)
        ])
        
        listCard.setContentCompressionResistancePriority(.required, for: .vertical)
        listCard.setContentHuggingPriority(.required, for: .vertical)
        
        selectionCollectionHeightConstraint = selectionCollectionView.heightAnchor.constraint(equalToConstant: 1)
        selectionCollectionHeightConstraint?.isActive = true
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 27),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            bottomStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            bottomStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            bottomStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            
            scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomStack.topAnchor, constant: -16),
            
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            
            topStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 22),
            topStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            topStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            topStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])
    }
    
    func setupActions() {
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        createButton.addTarget(self, action: #selector(createTapped), for: .touchUpInside)
        scheduleButton.addTarget(self, action: #selector(openSchedule), for: .touchUpInside)
    }
    
    func makeKeyboardToolbar() -> UIToolbar {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(title: "Готово", style: .done, target: self, action: #selector(doneTapped))
        
        toolbar.items = [flex, done]
        return toolbar
    }
    
    static func makeRowButton(title: String, subtitle: String? = nil) -> UIButton {
        var config = UIButton.Configuration.plain()
        
        config.title = title
        config.subtitle = subtitle
        config.titleAlignment = .leading
        
        config.baseForegroundColor = .black
        config.background.backgroundColor = .clear
        
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        
        config.subtitleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var out = incoming
            out.foregroundColor = UIColor.systemGray
            out.font = UIFont.systemFont(ofSize: 17, weight: .regular)
            return out
        }
        
        config.image = UIImage(systemName: "chevron.right")
        config.imagePlacement = .trailing
        config.imagePadding = 8
        config.imageColorTransformer = UIConfigurationColorTransformer { _ in
            UIColor(red: 174/255, green: 175/255, blue: 180/255, alpha: 1)
        }
        config.preferredSymbolConfigurationForImage =
        UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        
        let button = UIButton(configuration: config)
        button.contentHorizontalAlignment = .fill
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 16
        button.clipsToBounds = true
        return button
    }
}

