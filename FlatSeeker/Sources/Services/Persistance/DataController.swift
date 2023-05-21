import Combine
import CoreData

class DataController {
    let favouritePosts: AnyPublisher<[PostDTO], Never>
    private let container = NSPersistentContainer(name: "Model")
    
    init() {
        container.loadPersistentStores { _, error in
            if let error {
                print("Core Data failed to load: \(error.localizedDescription)")
            }
        }
        
        favouritePosts = CoreDataPublisher(
            request: Post.fetchRequest(),
            context: container.viewContext
        )
        .map { $0.map(\.postDTO) }
        .catch { _ in Just([]) }
        .eraseToAnyPublisher()
    }
    
    func save(post: PostDTO) {
        DispatchQueue.main.async { [managedContext = container.viewContext] in
            _ = Post(context: managedContext, post: post)
            try! managedContext.save()
        }
    }
    
    func delete(post: PostDTO) {
        DispatchQueue.main.async { [managedContext = container.viewContext] in
            let request = Post.fetchRequest()
            request.predicate = NSPredicate(format: "id == %lld", post.id)
            request.fetchLimit = 1
            
            if let object = try? managedContext.fetch(request).first {
                managedContext.delete(object)
                try! managedContext.save()
            }
        }
    }
}
