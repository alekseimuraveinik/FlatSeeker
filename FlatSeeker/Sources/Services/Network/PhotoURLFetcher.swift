import Foundation

struct PhotoURLFetcherConfig {
    let makeWebPageURL: (Int) -> URL?
    let targetURLRegex: Regex<(Substring, Substring)>
}

class PhotoURLFetcher {
    private let config: PhotoURLFetcherConfig
    
    init(config: PhotoURLFetcherConfig) {
        self.config = config
    }
    
    func fetchURLs(messageId: Int) async -> [URL]? {
        guard let url = config.makeWebPageURL(messageId),
              let htmlPage = await URLSession.shared.utf8String(from: url)
        else {
            return nil
        }
        
        return htmlPage.matches(of: config.targetURLRegex)
            .compactMap { URL(string: String($0.1)) }
            .reversed()
    }
}
