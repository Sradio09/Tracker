import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }
        setupWindow(with: windowScene)
    }
    
    private func setupWindow(with windowScene: UIWindowScene) {
        let window = UIWindow(windowScene: windowScene)
        
        if OnboardingState.shouldShowOnboarding() {
            let onboarding = OnboardingPageViewController()
            onboarding.onFinish = { [weak window] in
                OnboardingState.markOnboardingShown()
                window?.rootViewController = TabBarController()
            }
            window.rootViewController = onboarding
        } else {
            window.rootViewController = TabBarController()
        }
        
        self.window = window
        window.makeKeyAndVisible()
    }
}

