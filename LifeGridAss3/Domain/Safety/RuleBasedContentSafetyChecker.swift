import Foundation

/// An offline-first safety baseline for the assignment prototype.
///
/// Exact word matching avoids substring mistakes such as finding "sex" in
/// an unrelated longer word. A production community should supplement this
/// with contextual server-side moderation and human reporting.
struct RuleBasedContentSafetyChecker: ContentSafetyChecking {
    private let sexualTerms: Set<String> = [
        "nude", "nudes", "porn", "rape", "raped", "raping", "sex", "sexual"
    ]

    private let violentTerms: Set<String> = [
        "attack", "attacked", "gun", "guns", "kill", "killed", "killing",
        "murder", "murdered", "stab", "stabbed", "weapon", "weapons"
    ]

    func evaluateForPublicSharing(_ text: String) -> ContentSafetyResult {
        let words = Set(
            text.lowercased().split { !$0.isLetter }.map(String.init)
        )
        var categories: Set<UnsafeContentCategory> = []

        if !words.isDisjoint(with: sexualTerms) {
            categories.insert(.sexual)
        }

        if !words.isDisjoint(with: violentTerms) {
            categories.insert(.violent)
        }

        return categories.isEmpty ? .allowed : .blocked(categories)
    }
}
