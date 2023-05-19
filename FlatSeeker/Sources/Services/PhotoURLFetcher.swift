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
    
    func fetchURLs(messageIds: [Int]) async -> [URL] {
        await withTaskGroup(of: Optional<(Int, URL)>.self) { [config] taskGroup in
            for messageId in messageIds {
                taskGroup.addTask {
                    guard let url = config.makeWebPageURL(messageId),
                          let htmlPage = await URLSession.shared.utf8String(from: url)
                    else {
                        return nil
                    }
                    
                    do {
                        if let result = try config.targetURLRegex.firstMatch(in: htmlPage)?.1,
                           let resultURL = URL(string: String(result)) {
                            return (messageId, resultURL)
                        }
                        
                        return nil
                    } catch {
                        return nil
                    }
                }
            }
            
            let result = await taskGroup.reduce(into: []) { result, url in
                result.append(url)
            }
            
            return result
                .compactMap { $0 }
                .sorted(by: { $0.0 < $1.0 })
                .map(\.1)
        }
    }
}
