import UIKit

final class TabBarController: UITabBarController {
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
        setupTabBarAppearance()
    }
    
    // MARK: - Setup Tabs
    
    private func setupTabs() {
        let trackersVC = UINavigationController(
            rootViewController: TrackersViewController()
        )
        trackersVC.tabBarItem = UITabBarItem(
            title: NSLocalizedString("tab.trackers", comment: "Trackers tab title"),
            image: UIImage(systemName: "record.circle.fill"),
            selectedImage: UIImage(systemName: "record.circle.fill")
        )
        
        let statsVC = UINavigationController(
            rootViewController: StatisticsViewController()
        )
        statsVC.tabBarItem = UITabBarItem(
            title: NSLocalizedString("tab.statistics", comment: "Statistics tab title"),
            image: UIImage(systemName: "hare.fill"),
            selectedImage: UIImage(systemName: "hare.fill")
        )
        
        viewControllers = [trackersVC, statsVC]
    }
    
    // MARK: - TabBar Appearance
    
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = AppColors.background
        appearance.shadowColor = AppColors.tabBarSeparator
        
        tabBar.standardAppearance = appearance
        
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }
    }
}


