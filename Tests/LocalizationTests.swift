import XCTest
@testable import iTamagotchi

final class LocalizationTests: XCTestCase {

    func testNoEmptyTranslations() {
        for (key, pair) in Strings.all {
            XCTAssertFalse(pair.pt.isEmpty, "Missing PT for \(key)")
            XCTAssertFalse(pair.en.isEmpty, "Missing EN for \(key)")
        }
    }

    func testFormatSpecifiersMatch() {
        let pattern = try! NSRegularExpression(pattern: "%[@d]")
        func specifiers(_ s: String) -> [String] {
            pattern.matches(in: s, range: NSRange(s.startIndex..., in: s)).map { (s as NSString).substring(with: $0.range) }
        }
        for (key, pair) in Strings.all {
            XCTAssertEqual(specifiers(pair.pt), specifiers(pair.en), "Format mismatch in \(key)")
        }
    }

    func testDynamicKeysExist() {
        var keys: [String] = []
        keys += NeedKind.allCases.map { "need.\($0.rawValue)" }
        keys += LifeStage.allCases.map { "stage.\($0.rawValue)" }
        keys += AdultForm.allCases.flatMap { ["form.\($0.rawValue)", "form.\($0.rawValue).trait"] }
        keys += Mood.allCases.map { "mood.\($0.rawValue)" }
        keys += [Refusal.asleep, .full, .nothingToClean, .notSick, .unfair, .tooTired, .notHatched].map { "refusal.\($0.rawValue)" }
        keys += ShopItem.catalog.map { "item.\($0.id)" }
        keys += ShopCategory.allCases.map { "shop.\($0.rawValue)" }
        keys += Achievement.allCases.flatMap { ["ach.\($0.rawValue)", "ach.\($0.rawValue).desc"] }
        keys += Forecast.Alert.allCases.flatMap { ["notif.\($0.rawValue)", "notif.\($0.rawValue).body"] }
        keys += Room.allCases.map { "room.\($0.rawValue)" }
        keys += AppTheme.allCases.map { "settings.theme.\($0.rawValue)" }
        keys += [FarewellReason.oldAge, .neglect].map { "album.reason.\($0.rawValue)" }
        for key in keys {
            XCTAssertNotNil(Strings.all[key], "Missing key \(key)")
        }
    }

    func testPortugueseIsEuropean() {
        let brazilian = [" você", "tela", "configurações", "celular", " time "]
        for (key, pair) in Strings.all {
            for word in brazilian {
                XCTAssertFalse(pair.pt.lowercased().contains(word), "\(key) uses Brazilian Portuguese: \(word)")
            }
        }
    }

    func testDatesFollowTheAppLanguage() {
        let date = Fixture.date(hour: 15)
        let pt = date.formatted(.dateTime.month(.wide).locale(AppLanguage.pt.locale))
        let en = date.formatted(.dateTime.month(.wide).locale(AppLanguage.en.locale))
        XCTAssertNotEqual(pt, en)
        XCTAssertEqual(AppLanguage.pt.locale.language.languageCode, .portuguese)
        XCTAssertEqual(AppLanguage.pt.locale.region, .portugal, "European Portuguese, not Brazilian")
    }

    func testCreditsAreIdenticalInBothLanguages() {
        XCTAssertEqual(Strings.t("about.developedBy", .pt), "Developed by David Arsénio Martins")
        XCTAssertEqual(Strings.t("about.developedBy", .en), "Developed by David Arsénio Martins")
    }
}
