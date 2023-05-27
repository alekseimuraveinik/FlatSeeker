import Foundation

struct PhotoURLFetcherConfig {
    let makeWebPageURL: (Int) -> URL?
    let makeDeeplinkURL: (Int) -> URL?
    let targetURLRegex: Regex<(Substring, Substring)>
    let targetAuthorNameRegex: Regex<(Substring, Substring)>
    let targetAuthorImageURLRegex: Regex<(Substring, Substring)>
}

class PhotoURLFetcher {
    private let config: PhotoURLFetcherConfig
    
    init(config: PhotoURLFetcherConfig) {
        self.config = config
    }
    
    func fetchURLs(messageId: Int) async -> (String, URL, [URL])? {
        guard let url = config.makeWebPageURL(messageId),
              let htmlPage = await URLSession.shared.utf8String(from: url),
              let authourImage = try? config.targetAuthorImageURLRegex.firstMatch(in: htmlPage)?.1,
              let authourImageURL = URL(string: String(authourImage)),
              let authorName = try? config.targetAuthorNameRegex.firstMatch(in: htmlPage)?.1
        else {
            return nil
        }
        
        let urls = htmlPage.matches(of: config.targetURLRegex)
            .compactMap { URL(string: String($0.1)) }
            .reversed()
                
        return (String(authorName), authourImageURL, Array(urls))
    }
    
    func makeDeeplinkURL(messageId: Int) -> URL? {
        config.makeDeeplinkURL(messageId)
    }
    
    func makePostURL(messageId: Int) -> URL? {
        config.makeWebPageURL(messageId)
    }
}
