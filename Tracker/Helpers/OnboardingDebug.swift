import Foundation

enum OnboardingDebug {
    
    static let alwaysShowOnboarding = true
    
    static func shouldShowOnboarding() -> Bool {
        if alwaysShowOnboarding {
            return true
        }
        return !UserDefaults.standard.bool(forKey: "onboardingShown")
    }
    
    static func markOnboardingShown() {
        UserDefaults.standard.set(true, forKey: "onboardingShown")
    }
}

