import SwiftUI

@main struct LifeGridAss3App: App {
    private let profileRepository = OfflineFirstUserProfileRepository(
        local: FileUserProfileRepository(),
        remote: CloudKitUserProfileRepository()
    )
    private let lifeEntryRepository = OfflineFirstLifeEntryRepository(
        local: FileLifeEntryRepository(),
        remote: CloudKitLifeEntryRepository()
    )
    private let treeHolePostRepository = CloudKitTreeHolePostRepository()

    var body: some Scene {
        WindowGroup {
            ContentView(
                profileRepository: profileRepository,
                lifeEntryRepository: lifeEntryRepository,
                treeHolePostRepository: treeHolePostRepository
            )
        }
    }
}
