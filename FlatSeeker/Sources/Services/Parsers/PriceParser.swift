class PriceParser {
    func parsePrice(from text: String) -> Int? {
        let lowercasedText = (digitSubstitutions + dollarSubstitutions).reduce(text.lowercased()) { text, map in
            let (emoji, value) = map
            return text.replacingOccurrences(of: emoji, with: value)
        }
        
        for regex in priceRegexes {
            if let found = try? regex.firstMatch(in: lowercasedText) {
                let intPrice = Int(String(found.1))
                return intPrice == 0 ? nil : intPrice
            }
        }
        return nil
    }
}

private let priceRegexes = [
    /\$[  ]{0,3}(\d{3,4})/,
    /(\d{3,4})[  ]{0,3}\$/,
    /(\d{3,4})[  ]{0,3}долларов/,
    /цена[  ]{0,3}(\d{3,4})/,
]

private let digitSubstitutions = [
    "0️⃣", "1️⃣", "2️⃣", "3️⃣", "4️⃣", "5️⃣", "6️⃣", "7️⃣", "8️⃣", "9️⃣"
]
.enumerated()
.map { ($1, "\($0)") }

private let dollarSubstitutions = ["💰", "💵", "💲"].map { ($0, "$") }
