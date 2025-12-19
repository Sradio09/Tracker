import UIKit

final class TabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
    }

    private func setupTabs() {
        let trackersVC = UINavigationController(rootViewController: TrackersViewController())
        trackersVC.tabBarItem = UITabBarItem(
            title: "Трекеры",
            image: UIImage(systemName: "record.circle"),
            selectedImage: UIImage(systemName: "record.circle.fill")
        )

        let statsVC = UINavigationController(rootViewController: StatisticsViewController())
        statsVC.tabBarItem = UITabBarItem(
            title: "Статистика",
            image: UIImage(systemName: "hare"),
            selectedImage: UIImage(systemName: "hare.fill")
        )

        viewControllers = [trackersVC, statsVC]
    }
}

