import Combine
import Foundation

class PostsRepository {
    private let telegramClient: TelegramClient
    private let photoURLFetcher: PhotoURLFetcher
    private let districtParser = DistrictParser()
    private let priceParser = PriceParser()
    
    private var fetchedPosts = Set<String>()
    
    private let dataController = DataController()
    private let savedPosts: AnyPublisher<[PostDTO], any Error>
    
    init(telegramClient: TelegramClient, photoURLFetcher: PhotoURLFetcher) {
        self.telegramClient = telegramClient
        self.photoURLFetcher = photoURLFetcher
        
        savedPosts = CDPublisher(request: Post.fetchRequest(), context: dataController.container.viewContext)
            .map { objects in
                objects.map { object in
                    PostDTO(
                        id: Int(truncating: object.value(forKey: "id") as! NSNumber),
                        text: object.value(forKey: "text") as! String,
                        price: (object.value(forKey: "price") as! NSNumber?).flatMap(Int.init(truncating:)),
                        district: object.value(forKey: "districe") as! String?,
                        images: []
                    )
                }
            }
            .eraseToAnyPublisher()
    }
    
    func getPosts() async -> [PostDTO] {
        let groups = await telegramClient.getGroups()
        
        var posts = await withTaskGroup(of: PostDTO.self) { [photoURLFetcher, districtParser, priceParser] taskGroup in
            for (id, text, images) in groups {
                taskGroup.addTask {
                    let urls = await photoURLFetcher.fetchURLs(messageIds: images.map(\.0))
                    return PostDTO(
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
        
        posts = posts.filter { self.fetchedPosts.insert($0.text).inserted }
        if posts.isEmpty {
            return await getPosts()
        }
        return posts
    }
}
