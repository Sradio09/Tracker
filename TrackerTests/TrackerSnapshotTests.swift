import XCTest
import UIKit
import SnapshotTesting
import CoreData
@testable import Tracker

final class TrackerSnapshotTests: XCTestCase {

    private let fixedDate = Date(timeIntervalSince1970: 1_735_689_600) // 2025-01-01 00:00:00 UTC

    override func invokeTest() {
        withSnapshotTesting(
            record: .missing,
            diffTool: .ksdiff
        ) {
            super.invokeTest()
        }
    }

    override func setUp() {
        super.setUp()
        UIView.setAnimationsEnabled(false)
        SnapshotTestSeeder.resetAndSeed(for: fixedDate)
    }

    override func tearDown() {
        UIView.setAnimationsEnabled(true)
        super.tearDown()
    }

    // MARK: - Helpers

    private var lightTraits: UITraitCollection {
        UITraitCollection(userInterfaceStyle: .light)
    }

    private var darkTraits: UITraitCollection {
        UITraitCollection(userInterfaceStyle: .dark)
    }

    private func assertVC(
        _ vc: UIViewController,
        name: String? = nil,
        file: StaticString = #filePath,
        testName: String = #function,
        line: UInt = #line
    ) {
        let nav = UINavigationController(rootViewController: vc)
        nav.navigationBar.prefersLargeTitles = false

        // Light snapshot
        assertSnapshot(
            of: nav,
            as: .image(on: .iPhoneX, traits: lightTraits),
            named: makeVariantName(base: name, variant: "light"),
            file: file,
            testName: testName,
            line: line
        )

        // Dark snapshot
        assertSnapshot(
            of: nav,
            as: .image(on: .iPhoneX, traits: darkTraits),
            named: makeVariantName(base: name, variant: "dark"),
            file: file,
            testName: testName,
            line: line
        )
    }

    private func makeVariantName(base: String?, variant: String) -> String {
        if let base, !base.isEmpty {
            return "\(base)_\(variant)"
        }
        return variant
    }

    // MARK: - Screens

    func testTrackersScreen() {
        let vc = TrackersViewController(initialDate: fixedDate)
        assertVC(vc)
    }

    func testStatisticsScreen() {
        let vc = StatisticsViewController()
        assertVC(vc)
    }

    func testCreateTrackerScreen() {
        let vc = CreateTrackerViewController()
        assertVC(vc)
    }

    func testCategoryListScreen() {
        let store = TrackerCategoryStore(delegate: nil)
        let vm = CategoryListViewModel(store: store, selectedTitle: "Health")
        let vc = CategoryListViewController(viewModel: vm)
        assertVC(vc)
    }

    func testNewCategoryScreen() {
        let vc = NewCategoryViewController(
            screenTitle: NSLocalizedString("categories.new.title", comment: ""),
            initialText: "Work"
        )
        assertVC(vc)
    }

    func testScheduleScreen() {
        let vc = ScheduleViewController()
        vc.selectedDays = [.monday, .wednesday, .friday]
        assertVC(vc)
    }

    func testFiltersScreen() {
        let vc = FiltersViewController()
        vc.selectedOption = .completed
        assertVC(vc)
    }

    func testOnboardingPageScreen() {
        let vc = OnboardingPageViewController()
        assertVC(vc)
    }

    func testOnboardingContentScreen() {
        let page = OnboardingPage(
            title: NSLocalizedString("onboarding.page1.title", comment: ""),
            subtitle: "",
            backgroundImage: UIImage(named: "backgraundBlue")
        )
        let vc = OnboardingContentViewController(page: page)
        assertVC(vc)
    }

    func testInlineCalendarOverlay() {
        let overlay = InlineCalendarOverlay(onSelect: { _ in })

        let host = UIViewController()
        host.view.backgroundColor = .systemBackground

        let anchor = UIButton(type: .system)
        anchor.setTitle("Anchor", for: .normal)
        anchor.translatesAutoresizingMaskIntoConstraints = false
        host.view.addSubview(anchor)
        NSLayoutConstraint.activate([
            anchor.topAnchor.constraint(equalTo: host.view.safeAreaLayoutGuide.topAnchor, constant: 16),
            anchor.leadingAnchor.constraint(equalTo: host.view.leadingAnchor, constant: 16)
        ])

        host.view.addSubview(overlay)

        host.view.layoutIfNeeded()
        overlay.toggle(anchor: anchor, in: host.view)

        assertVC(host)
    }
}

// MARK: - Test Data

private enum SnapshotTestSeeder {

    static func resetAndSeed(for date: Date) {
        wipeCoreData()
        seedCoreData(for: date)
    }

    private static func wipeCoreData() {
        let context = DataBaseStore.shared.viewContext
        let model = DataBaseStore.shared.persistentContainer.managedObjectModel

        context.performAndWait {
            for entity in model.entities {
                guard let name = entity.name else { continue }
                let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: name)
                let request = NSBatchDeleteRequest(fetchRequest: fetch)
                request.resultType = .resultTypeObjectIDs

                do {
                    let result = try context.execute(request) as? NSBatchDeleteResult
                    if let objectIDs = result?.result as? [NSManagedObjectID], !objectIDs.isEmpty {
                        NSManagedObjectContext.mergeChanges(
                            fromRemoteContextSave: [NSDeletedObjectsKey: objectIDs],
                            into: [context]
                        )
                    }
                } catch {
                    assertionFailure("Failed to wipe entity \(name): \(error)")
                }
            }

            do { try context.save() }
            catch { assertionFailure("Failed to save after wipe: \(error)") }
        }
    }

    private static func seedCoreData(for date: Date) {
        let context = DataBaseStore.shared.viewContext
        let trackerStore = TrackerStore(delegate: nil)
        let categoryStore = TrackerCategoryStore(delegate: nil)
        let recordStore = TrackerRecordStore(delegate: nil)

        // Категории
        try? categoryStore.addCategory(title: "Здоровье")
        try? categoryStore.addCategory(title: "Работа")
        try? categoryStore.addCategory(title: "Саморазвитие")

        let health = fetchCategory(with: "Здоровье", context: context)
        let work = fetchCategory(with: "Работа", context: context)
        let selfDev = fetchCategory(with: "Саморазвитие", context: context)

        // UUID
        let meditationId = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let runId        = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let readId       = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
        let inboxId      = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!

        // Трекеры
        try? trackerStore.addNewTracker(
            id: meditationId,
            name: "Медитация",
            emoji: "🧘‍♂️",
            colorHex: "ColorSelection3",
            schedule: 0,
            isPinned: true,
            category: health
        )

        try? trackerStore.addNewTracker(
            id: runId,
            name: "Пробежка 5 км",
            emoji: "🏃‍♂️",
            colorHex: "ColorSelection7",
            schedule: 0,
            isPinned: false,
            category: health
        )

        try? trackerStore.addNewTracker(
            id: readId,
            name: "Читать 20 страниц",
            emoji: "📚",
            colorHex: "ColorSelection12",
            schedule: 0,
            isPinned: false,
            category: selfDev
        )

        try? trackerStore.addNewTracker(
            id: inboxId,
            name: "Разобрать почту",
            emoji: "📩",
            colorHex: "ColorSelection15",
            schedule: 0,
            isPinned: false,
            category: work
        )

        // Один выполненный трекер
        try? recordStore.addRecord(date: date, trackerId: runId)

        context.performAndWait {
            do { try context.save() }
            catch { assertionFailure("Seed save failed: \(error)") }
        }
    }


    private static func fetchCategory(with title: String, context: NSManagedObjectContext) -> TrackerCategoryCoreData? {
        let request = TrackerCategoryCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "title == %@", title)
        request.fetchLimit = 1
        return (try? context.fetch(request))?.first
    }
}
