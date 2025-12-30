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
            title: "Трекеры",
            image: UIImage(systemName: "record.circle"),
            selectedImage: UIImage(systemName: "record.circle.fill")
        )
        
        let statsVC = UINavigationController(
            rootViewController: StatisticsViewController()
        )
        statsVC.tabBarItem = UITabBarItem(
            title: "Статистика",
            image: UIImage(systemName: "hare.fill"),
            selectedImage: UIImage(systemName: "hare.fill")
        )
        
        viewControllers = [trackersVC, statsVC]
    }
    
    // MARK: - TabBar Appearance
    
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        
        appearance.shadowColor = UIColor(
            red: 174/255,
            green: 175/255,
            blue: 180/255,
            alpha: 1
        )
        
        tabBar.standardAppearance = appearance
        
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }
    }
}

