class DistrictParser {
    func parseDistrict(from text: String) -> String? {
        let lowercasedText = text.lowercased()
        for regex in districtRegexes {
            if let found = try? regex.firstMatch(in: lowercasedText) {
                return String(found.1).capitalizedWords
            }
        }
        return nil
    }
}

private let districtRegexes = [
    /Район {0,2}#([а-яА-Я]+)/,
    /Район {0,2}:? {0,2}([а-яА-Я]+)/,
    
    /(ваке-сабуртало)/,
    /(ваке)/,
    /(сабуртало)/,
    /(диди дигоми)/,
    /(дигоми)/,
    /(исани)/,
    /(исаны)/,
    /(исане)/,
    /(сололаки)/,
    /(надзаладеви)/,
    /(авлабари)/,
    /(глдани)/,
    /(дидубе)/,
    /(чугурети)/,
    /(мтацминда)/,
    /(cанзона)/,
    /(ортачала)/,
    /(церетели)/,
    /(вера)/,
    /(вазисубани)/,
    /(варкетили)/,
    /(батуми)/,
    /(ортчала)/,
    /(мардженешвили)/,
    /(марджанишвили)/,
]
