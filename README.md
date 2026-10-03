# LifeGrid Assignment 3

LifeGrid is a private wellbeing journal for people who want a gentle way to
notice how they are spending their time. It turns age into lived weeks, lets a
person record private weekly reflections, and provides a separate **Tree Hole**
prototype for sharing an edited anonymous copy and exchanging supportive
replies.

This is a new Xcode project and Git repository for Assignment 3. The idea may
be familiar from earlier exploration, but the persistence layer, extensions,
architecture, tests, and system integration were built for this project.

## Domain and stakeholder

The primary stakeholder is a young adult who wants to reflect regularly but
finds traditional journaling difficult to maintain. LifeGrid reduces that
friction by focusing on one week at a time and keeping sensitive writing on
the device.

The private and public spaces are deliberately separated:

- `LifeEntry` is a private weekly reflection.
- `TreeHolePost` is a separately edited anonymous public copy.
- `SupportReply` is a short supportive response to a Tree Hole post.
- `UserProfile` contains the birth date and reflection timeframe used to build
  the LifeGrid.

The Tree Hole currently demonstrates the complete anonymous sharing workflow
with local SwiftData persistence. It is a prototype, not a production
multi-device community service.

## Main features

- interactive LifeGrid years with 52 selectable week cells;
- private weekly reflections with optional emotional labels;
- a Week Details sheet showing dates, timeline status, and saved reflections;
- a separate editable public copy with explicit consent;
- sexual and violent content checks at the public-sharing boundary;
- a recent Tree Hole feed with emotional filtering;
- anonymous supportive replies;
- a Share Extension inbox that requires review before private import;
- a privacy-safe Widget for the Home Screen and Lock Screen;
- local SwiftData persistence that works without internet access;
- reusable SwiftUI styling and optional Lottie feedback animations.

## Persistence choice

LifeGrid uses **SwiftData** for its primary domain data. This choice followed
the subject teacher's clarification that SwiftData is an accepted local
persistence option for this task.

SwiftData fits the domain because private reflections should open quickly,
work offline, and remain on the person's device. Views and ViewModels never
access SwiftData directly. `SwiftDataLifeGridRepository` implements the domain
repository protocols and translates between SwiftData records and semantic
domain models.

### SwiftData schema

| Record | Purpose |
| --- | --- |
| `UserProfileRecord` | Stores the current LifeGrid profile |
| `LifeEntryRecord` | Stores private weekly reflections |
| `TreeHolePostRecord` | Stores edited anonymous prototype posts |
| `SupportReplyRecord` | Stores replies related to a Tree Hole post |

`TreeHolePostRecord` has a one-to-many relationship with
`SupportReplyRecord`. Deleting a post cascades to its replies.

Meaningful queries include:

- reflections matching a selected life-week number;
- Tree Hole posts created during the most recent 30 days;
- replies belonging to a selected Tree Hole post.

## System extensions

### LifeGrid Widget

The Widget gives the stakeholder a private weekly reminder without opening the
app. It shows only the current life week, remaining weeks in the chosen frame,
and whether a reflection has been recorded. Reflection text is never copied to
the Widget container.

- Home Screen family: `systemSmall`
- Lock Screen family: `accessoryRectangular`
- App Group: `group.LALAJJ0302.com.LifeGridAss3`
- Shared value: `LifeGridWidgetSnapshot`

After a relevant reflection change, the main app writes a privacy-safe
snapshot to the App Group and calls `WidgetCenter` to reload the timeline.

### Save to LifeGrid Share Extension

The Share Extension accepts meaningful text or one web link from apps such as
Safari and Notes. It stores a `SharedReflectionDraft` in the App Group instead
of writing directly to the private database.

The person must then:

1. open **Shared Drafts**;
2. review or edit the received text;
3. optionally choose an emotional label;
4. explicitly select **Save privately**.

Successful sharing calls `completeRequest`. Cancellation or unsupported
content calls `cancelRequest`, so the host share sheet always closes.

## Privacy boundary

```text
Private LifeEntry
  -> SwiftData on this device
  -> never automatically becomes public

Explicit action: Share edited copy
  -> editable separate text
  -> consent confirmation
  -> on-device safety check
  -> new TreeHolePost prototype record
  -> no profile ID or private LifeEntry ID attached

Text or URL from another app
  -> Share Extension
  -> SharedReflectionDraft in App Group
  -> explicit review in LifeGrid
  -> private LifeEntry in SwiftData
```

Publishing never moves, modifies, or deletes the original private reflection.

## Architecture

LifeGrid uses MVVM, a Use Case layer, repository protocols, and dependency
inversion.

| Layer | Responsibility | Examples |
| --- | --- | --- |
| Domain | App vocabulary and storage contracts | `LifeEntry`, `TreeHolePost`, repository protocols |
| Use Cases | Validation and business rules | `RecordLifeEntryUseCase`, `PublishTreeHolePostUseCase` |
| Data | SwiftData and App Group implementations | `SwiftDataLifeGridRepository`, `AppGroupSharedReflectionDraftRepository` |
| ViewModels | Observable screen state and async coordination | `TreeHoleFeedViewModel`, `SupportRepliesViewModel` |
| Views | SwiftUI layout and interaction | `LifeGridHomeView`, `TreeHoleFeedView` |

`MyApp.swift` is the composition root. It creates the concrete repositories
and injects them into `ContentView`. Unit tests replace repository protocols
with deterministic test implementations.

## Functional screens

The four main tabs are only entry points. The complete workflow contains more
than the five required functional screens.

| Screen | Purpose | How to reach it |
| --- | --- | --- |
| Profile Setup | Create the private LifeGrid profile | First launch |
| LifeGrid Home | Record and review this week's reflections | **LifeGrid** tab |
| Week Details | Review dates and reflections for a selected week | Tap a week cell in **Profile** |
| Review Public Copy | Edit and confirm an anonymous copy | **Share edited copy** on a reflection |
| Tree Hole Feed | Browse recent prototype posts | **Tree Hole** tab |
| Support Replies | Read and send supportive replies | Select a Tree Hole post |
| Shared Drafts Inbox | Review content received from other apps | **Shared Drafts** tab |
| Shared Draft Review | Edit and save an imported private reflection | Select a shared draft |
| Profile | Review life years and update profile settings | **Profile** tab |

## Run locally

1. Open `LifeGridAss3.xcodeproj` in Xcode.
2. Wait for Swift Package Manager to resolve Lottie.
3. Select the `LifeGridAss3` scheme and an iPhone simulator.
4. In **Signing & Capabilities**, select a development team.
5. Confirm that the app, `LifeGridWidget`, and
   `LifeGridShareExtension` targets use App Group
   `group.LALAJJ0302.com.LifeGridAss3`.
6. Press **Command-B** to build and **Command-R** to run.
7. Press **Command-U** to run the complete test suite.

No CloudKit container or internet connection is required for app data.

## Testing and verification

The project currently contains **34 passing tests** covering:

- Use Case happy paths, boundaries, and domain errors;
- repository failure translation into human-readable errors;
- private/public copy separation;
- SwiftData persistence and the post/reply relationship;
- App Group Widget snapshot privacy;
- Share Extension draft append/remove behavior;
- weekly date calculations and current-week screen state.

The main branch was also verified with a clean Xcode build. See
`DEBUGGING.md` for current troubleshooting notes.

## Third-party software and AI disclosure

- [Lottie for iOS](https://github.com/airbnb/lottie-ios), version 4.6.1,
  is installed through Swift Package Manager and used for small decorative
  feedback animations. The animation JSON files in this repository were made
  specifically for LifeGrid.
- AI coding assistance was used during development for explanation,
  implementation support, debugging, and review. The submitted report includes
  examples of prompts, evaluation, corrections, and decisions made by the
  student.
