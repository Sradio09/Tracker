import UIKit

final class OnboardingPageViewController: UIPageViewController, UIPageViewControllerDelegate {
    
    // MARK: - Public
    
    var onFinish: (() -> Void)?
    
    // MARK: - Data
    
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            title: NSLocalizedString("onboarding.page1.title", comment: "Onboarding page 1 title"),
            subtitle: "",
            backgroundImage: UIImage(named: "backgraundBlue")
        ),
        OnboardingPage(
            title: NSLocalizedString("onboarding.page2.title", comment: "Onboarding page 2 title"),
            subtitle: "",
            backgroundImage: UIImage(named: "backgraundRed")
        )
    ]
    
    private lazy var pagesVC: [UIViewController] = pages.map { OnboardingContentViewController(page: $0) }
    
    // MARK: - UI
    
    private let overlayView: PassthroughView = {
        let v = PassthroughView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .clear
        return v
    }()
    
    private let pageControl: UIPageControl = {
        let pc = UIPageControl()
        pc.currentPageIndicatorTintColor = .label
        pc.pageIndicatorTintColor = UIColor.white.withAlphaComponent(0.5)
        pc.translatesAutoresizingMaskIntoConstraints = false
        pc.isUserInteractionEnabled = false
        return pc
    }()
    
    private let actionButton: UIButton = {
        let button = UIButton(type: .system)
        
        var config = UIButton.Configuration.filled()
        
        var attributes = AttributeContainer()
        attributes.font = .systemFont(ofSize: 16, weight: .medium)
        
        config.attributedTitle = AttributedString(NSLocalizedString("onboarding.button.next", comment: "Next button"), attributes: attributes)
        config.cornerStyle = .large
        config.baseBackgroundColor = .black
        config.baseForegroundColor = .white
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16)
        
        button.configuration = config
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Init
    
    init() {
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataSource = self
        delegate = self
        
        if let first = pagesVC.first {
            setViewControllers([first], direction: .forward, animated: false)
        }
        
        setupOverlayAndBottomUI()
        updateButtonTitle()
    }
    
    // MARK: - Setup
    
    private func setupOverlayAndBottomUI() {
        
        view.addSubview(overlayView)
        NSLayoutConstraint.activate([
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        overlayView.addSubview(actionButton)
        overlayView.addSubview(pageControl)
        overlayView.touchableViews = [actionButton, pageControl]
        
        NSLayoutConstraint.activate([
            actionButton.leadingAnchor.constraint(equalTo: overlayView.leadingAnchor, constant: 20),
            actionButton.trailingAnchor.constraint(equalTo: overlayView.trailingAnchor, constant: -20),
            actionButton.bottomAnchor.constraint(equalTo: overlayView.bottomAnchor, constant: -84),
            actionButton.heightAnchor.constraint(equalToConstant: 60)
        ])
        
        pageControl.numberOfPages = pagesVC.count
        pageControl.currentPage = 0
        
        NSLayoutConstraint.activate([
            pageControl.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            pageControl.bottomAnchor.constraint(equalTo: actionButton.topAnchor, constant: -14)
        ])
        
        actionButton.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
    }
    
    // MARK: - Actions
    
    @objc private func didTapButton() {
        UserDefaults.standard.set(true, forKey: "onboardingShown")
        onFinish?()
    }
    
    // MARK: - Navigation
    
    private func goToPage(index: Int) {
        guard index >= 0, index < pagesVC.count else { return }
        
        let direction: UIPageViewController.NavigationDirection = index > pageControl.currentPage ? .forward : .reverse
        setViewControllers([pagesVC[index]], direction: direction, animated: true)
        
        pageControl.currentPage = index
        updateButtonTitle()
    }
    
    private func updateButtonTitle() {
        let isLast = pageControl.currentPage == pagesVC.count - 1
        let title = isLast ? NSLocalizedString("onboarding.button.start", comment: "Start button") : NSLocalizedString("onboarding.button.next", comment: "Next button")
        
        var attributes = AttributeContainer()
        attributes.font = .systemFont(ofSize: 16, weight: .medium)
        
        actionButton.configuration?.attributedTitle = AttributedString(title, attributes: attributes)
    }
}

// MARK: - UIPageViewControllerDataSource

extension OnboardingPageViewController: UIPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = pagesVC.firstIndex(of: viewController) else { return nil }
        let prev = index - 1
        guard prev >= 0 else { return nil }
        return pagesVC[prev]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = pagesVC.firstIndex(of: viewController) else { return nil }
        let next = index + 1
        guard next < pagesVC.count else { return nil }
        return pagesVC[next]
    }
}

// MARK: - UIPageViewControllerDelegate

extension OnboardingPageViewController {
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            didFinishAnimating finished: Bool,
                            previousViewControllers: [UIViewController],
                            transitionCompleted completed: Bool) {
        guard completed,
              let current = pageViewController.viewControllers?.first,
              let index = pagesVC.firstIndex(of: current) else { return }
        
        pageControl.currentPage = index
        updateButtonTitle()
    }
}

