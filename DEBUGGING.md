# LifeGrid Debugging Notes

## Current Xcode symptoms

Xcode may display these errors in `LifeGridHomeView.swift`:

- `Cannot find type 'CurrentWeekEntriesViewModel' in scope`
- `Cannot find type 'LoadLifeEntriesForWeekUseCase' in scope`
- `Cannot find 'CurrentWeekEntriesViewModel' in scope`

It may also display several purple warnings saying that dynamic shadows are
expensive to render.

## Diagnosis

The missing-type messages are stale Xcode index errors, not missing source
code. Both types exist in the project:

- `LifeGridAss3/ViewModels/CurrentWeekEntriesViewModel.swift`
- `LifeGridAss3/UseCases/LoadLifeEntriesForWeekUseCase.swift`

The project uses `PBXFileSystemSynchronizedRootGroup`, so Swift files placed
inside the `LifeGridAss3` folder are automatically included in the app target.
A command-line build has compiled these files successfully.

The screenshot also shows an older in-memory copy of `LifeGridHomeView.swift`.
The current file has a `publishTreeHolePost` dependency that is not visible in
that screenshot. Xcode therefore needs to reload the files from disk.

## Recovery steps in Xcode

1. Save or discard any intentional unsaved edits in Xcode. Do not overwrite
   the newer files on disk with the older editor copy.
2. Close the LifeGrid project window.
3. Reopen this exact project:
   `/Users/jj/Documents/ChatGPT/Ad ios/LifeGridAss3/LifeGridAss3.xcodeproj`
4. Select `Product > Clean Build Folder` while holding the Option key if the
   menu item is not visible (`Shift-Command-K`).
5. Wait for Xcode indexing to finish.
6. Build with `Command-B`.

If the same red messages remain after reopening:

1. Quit Xcode completely.
2. Reopen the same `.xcodeproj` path above.
3. Select `File > Packages > Reset Package Caches` only if package-related
   errors appear. LifeGrid currently has no external package dependency, so
   this normally is not required.

## Why deleting DerivedData is not the first step

The app and test target already compile from a clean command-line build.
Deleting all DerivedData is broad and can slow every Xcode project. Reloading
this project is the smaller and safer fix for an editor holding stale files.

## Purple dynamic-shadow warnings

The purple messages are runtime performance diagnostics, not compiler errors.
They do not prevent the app from building. SwiftUI materials and rounded cards
can create dynamic shadows that are relatively expensive on the simulator.

Treat these separately from the three red missing-type errors:

- Red error: prevents compilation and must be resolved.
- Purple warning: app can run, but rendering may be optimized later.

For the assignment prototype, validate scrolling performance on a real device
before replacing the visual design. If optimization becomes necessary, prefer
a simple opaque card background and a small explicit shadow radius instead of
stacked translucent materials.

## Verification record

Verified command:

```text
xcodebuild -project LifeGridAss3.xcodeproj -scheme LifeGridAss3 \
  -configuration Debug -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO build-for-testing
```

Verified result:

```text
** TEST BUILD SUCCEEDED **
```

This result confirms that the app target and test target can see the new source
files. It does not mean simulator tests executed; the local simulator service
must be working for test execution.
