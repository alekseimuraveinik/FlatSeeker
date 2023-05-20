import Foundation

struct PostImage {
    let thumbnail: Data
    let imageURL: URL
}

struct Post {
    let id: Int
    let text: String
    let price: String?
    let district: String?
    let images: [PostImage]
}

class PostsRepository {
    private let telegramClient: TelegramClient
    private let photoURLFetcher: PhotoURLFetcher
    private let districtParser = DistrictParser()
    private let priceParser = PriceParser()
    
    init(telegramClient: TelegramClient, photoURLFetcher: PhotoURLFetcher) {
        self.telegramClient = telegramClient
        self.photoURLFetcher = photoURLFetcher
    }
    
    func getPosts() async -> [Post] {
        let groups = await telegramClient.getGroups()
        
        let posts = await withTaskGroup(of: Post.self) { [photoURLFetcher, districtParser, priceParser] taskGroup in
            for (id, text, images) in groups {
                taskGroup.addTask {
                    let urls = await photoURLFetcher.fetchURLs(messageIds: images.map(\.0))
                    return Post(
                        id: id,
                        text: text,
                        price: priceParser.parsePrice(from: text),
                        district: districtParser.parseDistrict(from: text)?.capitalizedWords,
                        images: zip(images.map(\.1), urls)
                            .reversed()
                            .map(PostImage.init)
                    )
                }
            }
            
            let result = await taskGroup.reduce(into: []) { result, group in
                result.append(group)
            }
            
            return result.sorted(by: { $0.id > $1.id })
        }
        
        if posts.isEmpty {
            return await getPosts()
        }
        return posts
    }
}
