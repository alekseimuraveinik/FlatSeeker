import Foundation

class PhotoURLFetcher {
    func fetchURLs(messageIds: [Int]) async -> [URL] {
        await withTaskGroup(of: Optional<(Int, URL)>.self) { taskGroup in
            for messageId in messageIds {
                taskGroup.addTask {
                    let urlString = makeURLString(for: messageId)
                    guard let url = URL(string: urlString),
                          let htmlPage = await URLSession.shared.utf8String(from: url)
                    else {
                        return nil
                    }
                    
                    do {
                        if let result = try urlRegex.firstMatch(in: htmlPage)?.1,
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

private func makeURLString(for messageId: Int) -> String {
    "https://t.me/tbilisi_arendaa/\(messageId)?embed=1&mode=tme&single=1"
}

private let urlRegex = /background-image:url\('(.*?\.jpg)'\)/
