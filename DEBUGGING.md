# LifeGrid Debugging Notes

## Open the correct project

Open this project file:

```text
/Users/jj/Documents/ChatGPT/Ad ios/LifeGridAss3/LifeGridAss3.xcodeproj
```

The project uses file-system-synchronised Xcode groups, so Swift files inside
the target folders are included automatically.

## Normal build and test steps

1. Wait until Swift Package Manager finishes resolving Lottie.
2. Select the `LifeGridAss3` scheme and an iPhone simulator.
3. Press **Command-B** to build.
4. Press **Command-R** to run the app.
5. Press **Command-U** to run all tests.

The current verified result is a successful build with 34 passing tests.

## If Xcode shows stale errors

Sometimes Xcode's editor index shows red errors even though the project can
build successfully.

1. Save intentional edits.
2. Close the project window.
3. Reopen the `.xcodeproj` listed above.
4. Choose **Product > Clean Build Folder** (`Shift-Command-K`).
5. Wait for indexing to finish and build again.

Deleting all DerivedData should be a last resort because it also removes
cached packages and slows the next build.

## If Lottie does not resolve

Lottie 4.6.1 is installed through Swift Package Manager.

1. Check the **Package Dependencies** section in Xcode.
2. Choose **File > Packages > Resolve Package Versions**.
3. Use **Reset Package Caches** only if normal resolution fails.

An internet connection may be required the first time the package is
downloaded. After it is cached, normal local builds do not require internet.

## Core Animation console messages

The iOS 27 Simulator may print this message while a Lottie view is starting or
changing size:

```text
cannot add handler to 0 from 0 - dropping
```

This is a Core Animation runtime diagnostic. It has not produced a crash,
compiler warning, or failed test in LifeGrid. The animations also respect the
Reduce Motion accessibility setting. Treat the message separately from red
Swift compiler errors.

## App Group checks

If the Widget always says **Open LifeGrid**, or Shared Drafts remain empty:

1. Open **Signing & Capabilities** for all three targets.
2. Confirm the following App Group is enabled everywhere:

```text
group.LALAJJ0302.com.LifeGridAss3
```

3. Run the main app once before adding the Widget.
4. Save a reflection, then return to the Home Screen to check the Widget.
5. For Share Extension testing, share text or a web link from Simulator Safari
   to **Save to LifeGrid**, then reopen the Shared Drafts tab.

## SwiftData during testing

The production app uses the on-device SwiftData store. Repository tests create
an in-memory `SwiftDataLifeGridRepository`, so tests do not overwrite the
person's saved simulator data.
