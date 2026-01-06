import Foundation

enum OnboardingState {

    // MARK: - Constants

    private static let onboardingShownKey = "onboardingShown"

    // MARK: - Debug

    static let alwaysShowOnboarding = false

    // MARK: - Public API

    static func shouldShow() -> Bool {
        if alwaysShowOnboarding {
            return true
        }
        return !UserDefaults.standard.bool(forKey: onboardingShownKey)
    }

    static func markShown() {
        UserDefaults.standard.set(true, forKey: onboardingShownKey)
    }
}

