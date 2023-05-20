class PriceParser {
    func parsePrice(from text: String) -> Int? {
        let lowercasedText = text.lowercased()
        for regex in priceRegexes {
            if let found = try? regex.firstMatch(in: lowercasedText) {
                var price = String(found.1)
                if price.contains(/[0️⃣1️⃣2️⃣3️⃣4️⃣5️⃣6️⃣7️⃣8️⃣9️⃣]/) {
                    price = normalize(memDigits: price)
                }
                let intPrice = Int(price)
                return intPrice == 0 ? nil : intPrice
            }
        }
        return nil
    }
}

private let priceRegexes = [
    /\$[  ]{0,3}(\d{3,4})/,
    /(\d{3,4})[  ]{0,3}[$💰💵]/,
    /(\d{3,4})[  ]{0,3}долларов/,
    
    /\$[  ]{0,3}([0️⃣1️⃣2️⃣3️⃣4️⃣5️⃣6️⃣7️⃣8️⃣9️⃣]{3,4})/,
    /([0️⃣1️⃣2️⃣3️⃣4️⃣5️⃣6️⃣7️⃣8️⃣9️⃣]{3,4})[  ]{0,3}[$💰💵]/,
    /([0️⃣1️⃣2️⃣3️⃣4️⃣5️⃣6️⃣7️⃣8️⃣9️⃣]{3,4})[  ]{0,3}долларов/,
]

private let normalizedDigits = [
    "0️⃣": 0,
    "1️⃣": 1,
    "2️⃣": 2,
    "3️⃣": 3,
    "4️⃣": 4,
    "5️⃣": 5,
    "6️⃣": 6,
    "7️⃣": 7,
    "8️⃣": 8,
    "9️⃣": 9
]

private func normalize(memDigits: String) -> String {
    var result = [String]()
    for memDigit in memDigits {
        let stringMemDigit = String(memDigit)
        if let digit = normalizedDigits[stringMemDigit] {
            result.append(String(digit))
        } else {
            result.append(stringMemDigit)
        }
    }
    return result.joined()
}
