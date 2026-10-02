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
- in-memory preview repositories and 39 unit tests.

## System extensions

### LifeGrid Widget

The Widget gives someone a private, glanceable check-in without requiring them to open the app. It deliberately shows only the current life week, remaining weeks in the chosen frame, and whether a reflection has been recorded this week. Reflection text is never copied to the Widget container or displayed on the Lock Screen.

- Home Screen: `systemSmall`
- Lock Screen: `accessoryRectangular`
- App Group: `group.LALAJJ0302.com.LifeGridAss3`
- Shared value: `LifeGridWidgetSnapshot`

The main app writes the snapshot after loading or saving the current week's reflections and then calls `WidgetCenter.shared.reloadTimelines(ofKind:)`. The Widget also requests a new timeline shortly after midnight so the life-week calculation stays current.

### Save to LifeGrid Share Extension

The Share Extension lets someone capture meaningful text or a web link from apps such as Safari and Notes without interrupting the moment to manually copy and paste. It accepts plain text and one web URL, then stores a `SharedReflectionDraft` in the same App Group.

The extension never writes a final `LifeEntry` and never publishes to the Tree Hole. In the main app, the **Shared Drafts** inbox requires the person to:

1. open the received draft;
2. review or edit its text;
3. optionally choose an emotional label;
4. explicitly select **Save privately**.

After a successful import, the draft is removed from the App Group inbox and the Widget timeline is refreshed. Posting completes with `completeRequest`; cancellation and unsupported content terminate with `cancelRequest`, so the host share sheet is always dismissed correctly.

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
  -> references the public TreeHolePost through CKRecord.Reference

Text or URL from another app
  -> Share Extension
  -> SharedReflectionDraft in App Group
  -> explicit review in LifeGrid
  -> private LifeEntry
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

## Functional screens and navigation

The three items in the main tab bar are entry points, not the total screen count. LifeGrid provides seven functional screens that follow the stakeholder's workflow:

| Screen | Purpose | How to reach it |
| --- | --- | --- |
| Profile Setup | Create the private LifeGrid profile and lifespan frame | First launch when no profile exists |
| LifeGrid Home | Record and review this week's private reflections | **LifeGrid** tab |
| Review Public Copy | Edit a separate anonymous copy and confirm public sharing | **Share edited copy** on a private reflection |
| Tree Hole Feed | Browse recent anonymous posts and filter by emotion | **Tree Hole** tab |
| Support Replies | Read and send safe, anonymous support | **View and send support** on a Tree Hole post |
| Shared Drafts Inbox | Review text and links received from other apps | **Shared Drafts** tab |
| Shared Draft Review | Edit a received draft and explicitly save it privately | Select a draft in the inbox |

`PrivateReflectionEditorView` is a functional component within LifeGrid Home and is not counted as an additional screen.

## Run locally

1. Open `LifeGridAss3.xcodeproj` in Xcode.
2. Select the `LifeGridAss3` scheme and an iPhone simulator with iOS 27 or later.
3. In **Signing & Capabilities**, choose a development team and keep iCloud/CloudKit enabled.
4. Confirm the app, `LifeGridWidget`, and `LifeGridShareExtension` targets all use App Group `group.LALAJJ0302.com.LifeGridAss3`.
5. Press **Command-B** to build and **Command-R** to run.
6. Press **Command-U** to run the test suite.

The home-screen preview does not require iCloud or internet because it uses repositories in `PreviewSupport/PreviewRepositories.swift`.

## CloudKit configuration

The configured container is `iCloud.LALAJJ0302.com.LifeGridAss3`.

For community queries in CloudKit Dashboard, configure these development-schema indexes before deploying the schema to production:

- `TreeHolePost.createdAt`: queryable and sortable;
- `TreeHolePost.emotionalState`: queryable;
- `SupportReply.postReference`: queryable;
- `SupportReply.createdAt`: sortable.

Private profile and reflection records use the private database. `TreeHolePost` and `SupportReply` use the public database.

## Verification

Verified in Xcode on 1 October 2026:

- app build succeeded;
- interactive SwiftUI preview rendered;
- both extensions were embedded and validated in the main app bundle;
- **39 tests passed**, including offline CloudKit recovery, Widget snapshot persistence, Share Extension draft persistence, and reviewed private import.

See `DEBUGGING.md` for common Xcode, simulator, preview, and CloudKit troubleshooting steps.
