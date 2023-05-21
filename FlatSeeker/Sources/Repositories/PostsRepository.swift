import Combine
import CoreData
import Foundation

class PostsRepository {
    private let telegramClient: TelegramClient
    private let photoURLFetcher: PhotoURLFetcher
    private let districtParser = DistrictParser()
    private let priceParser = PriceParser()
    
    private var fetchedPosts = Set<String>()
    
    private let dataController = DataController()
    private let favouritePosts = CurrentValueSubject<[PostDTO], Never>([])
    private let favouritePostsCancellable: AnyCancellable?
    
    init(telegramClient: TelegramClient, photoURLFetcher: PhotoURLFetcher) {
        self.telegramClient = telegramClient
        self.photoURLFetcher = photoURLFetcher
        
        favouritePostsCancellable = dataController.favouritePosts
            .sink(receiveValue: favouritePosts.send(_:))
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
    
    func getIsInFavourite(post: PostDTO) -> AnyPublisher<Bool, Never> {
        favouritePosts
            .map { posts in
                posts.contains(where: { $0.id == post.id })
            }
            .eraseToAnyPublisher()
    }
    
    func addToFavourite(post: PostDTO) {
        dataController.save(post: post)
    }
    
    func removeFromFavourite(post: PostDTO) {
        dataController.delete(post: post)
    }
}
