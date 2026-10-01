# LifeGrid Assignment 3

LifeGrid is a SwiftUI wellbeing journal that turns a person's age into lived weeks. Private weekly reflections work offline, while a deliberately separate **Tree Hole** lets people publish an edited anonymous copy and exchange supportive replies.

## Assignment 3 extension

Assignment 2 supplied the basic application idea. This project is a new Xcode project and GitHub repository with a fuller, testable architecture:

- protected profile and private reflection storage on the device;
- offline-first synchronization to the user's private CloudKit database;
- current-week reflection recording with an optional emotional label;
- an explicit review screen that creates a separate public copy;
- public Tree Hole feed with a 30-day window and optional emotion filter;
- anonymous supportive replies;
- sexual/violent-content checks at the public-sharing use-case boundary;
- loading, empty, failure, retry, character-limit, and offline states;
- in-memory preview repositories and 34 unit tests.

## Privacy boundary

```text
Private LifeEntry
  -> local Application Support JSON (protected file)
  -> CloudKit private database during synchronization

Explicit user action: "Share edited copy"
  -> editable text + consent + safety check
  -> new TreeHolePost in CloudKit public database
  -> no profile ID and no private LifeEntry ID

SupportReply
  -> safety check
  -> CloudKit public database
  -> references only the public TreeHolePost ID
```

Publishing never moves, modifies, or deletes the original private reflection.

## Architecture

The project uses dependency inversion so that UI and business rules do not depend directly on CloudKit.

| Layer | Responsibility | Examples |
| --- | --- | --- |
| Domain | App vocabulary and storage contracts | `LifeEntry`, `TreeHolePost`, repository protocols |
| Use cases | Validation and business rules | `RecordLifeEntryUseCase`, `PublishTreeHolePostUseCase`, `SendSupportReplyUseCase` |
| Data | Local files, CloudKit, offline reconciliation | `FileLifeEntryRepository`, `CloudKitTreeHolePostRepository` |
| View models | Observable screen state and async coordination | `TreeHoleFeedViewModel`, `SupportRepliesViewModel` |
| Views | SwiftUI layout and user interaction | `LifeGridHomeView`, `TreeHoleFeedView` |

`MyApp.swift` is the composition root: it creates concrete repositories and injects them into the feature graph. Tests replace them with deterministic in-memory mocks.

## Run locally

1. Open `LifeGridAss3.xcodeproj` in Xcode.
2. Select the `LifeGridAss3` scheme and an iPhone simulator with iOS 27 or later.
3. In **Signing & Capabilities**, choose a development team and keep iCloud/CloudKit enabled.
4. Press **Command-B** to build and **Command-R** to run.
5. Press **Command-U** to run the test suite.

The home-screen preview does not require iCloud or internet because it uses repositories in `PreviewSupport/PreviewRepositories.swift`.

## CloudKit configuration

The configured container is `iCloud.LALAJJ0302.com.LifeGridAss3`.

For community queries in CloudKit Dashboard, configure these development-schema indexes before deploying the schema to production:

- `TreeHolePost.createdAt`: queryable and sortable;
- `TreeHolePost.emotionalState`: queryable;
- `SupportReply.postID`: queryable;
- `SupportReply.createdAt`: sortable.

Private profile and reflection records use the private database. `TreeHolePost` and `SupportReply` use the public database.

## Verification

Verified in Xcode on 1 October 2026:

- app build succeeded;
- interactive SwiftUI preview rendered;
- **34 tests in 11 suites passed**.

See `DEBUGGING.md` for common Xcode, simulator, preview, and CloudKit troubleshooting steps.
