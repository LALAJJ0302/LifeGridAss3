import SwiftUI

@main struct LifeGridAss3App: App {
    private let repository: SwiftDataLifeGridRepository
    private let sharedDraftRepository = AppGroupSharedReflectionDraftRepository()

    init() {
        do {
            repository = try SwiftDataLifeGridRepository()
        } catch {
            fatalError("LifeGrid could not open its local database: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(
                profileRepository: repository,
                lifeEntryRepository: repository,
                treeHolePostRepository: repository,
                supportReplyRepository: repository,
                sharedDraftRepository: sharedDraftRepository
            )
        }
    }
}
