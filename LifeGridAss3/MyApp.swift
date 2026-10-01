import SwiftUI

@main struct LifeGridAss3App: App {
    private let profileRepository = OfflineFirstUserProfileRepository(
        local: FileUserProfileRepository(),
        remote: CloudKitUserProfileRepository()
    )

    var body: some Scene {
        WindowGroup {
            ContentView(profileRepository: profileRepository)
        }
    }
}
