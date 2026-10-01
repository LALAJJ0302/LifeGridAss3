import SwiftUI

@main struct LifeGridAss3App: App {
    private let profileRepository = CloudKitUserProfileRepository()

    var body: some Scene {
        WindowGroup {
            ContentView(profileRepository: profileRepository)
        }
    }
}
