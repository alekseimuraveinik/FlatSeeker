extension String {
    var capitalizedWords: String {
        split(separator: " ")
            .map { $0.prefix(1).capitalized + $0.dropFirst().lowercased() }
            .joined(separator: " ")
    }
}
