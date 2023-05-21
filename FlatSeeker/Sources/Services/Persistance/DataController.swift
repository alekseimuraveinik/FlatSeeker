import Combine
import CoreData

protocol ManagedObjectConvertible {
    var id: Int { get }
    func makeManagedObject(context: NSManagedObjectContext) -> NSManagedObject
}

protocol ConvertibleManagedObject: NSManagedObject {
    associatedtype DTO
    
    var dto: DTO { get }
    static func fetchRequest() -> NSFetchRequest<Self>
}

class DataController {
    private let container = NSPersistentContainer(name: "Model")
    
    init() {
        container.loadPersistentStores { _, error in
            if let error {
                print("Core Data failed to load: \(error.localizedDescription)")
            }
        }
    }
    
    func makeObjectPublisher<Object: ConvertibleManagedObject>(for _: Object.Type) -> AnyPublisher<[Object.DTO], Never> {
        CoreDataPublisher(
            request: Object.fetchRequest(),
            context: container.viewContext
        )
        .map { $0.map(\.dto) }
        .catch { _ in Just([]) }
        .eraseToAnyPublisher()
    }
    
    func save<Object: ManagedObjectConvertible>(object: Object) {
        DispatchQueue.main.async { [context = container.viewContext] in
            _ = object.makeManagedObject(context: context)
            try! context.save()
        }
    }
    
    func delete<Object: ManagedObjectConvertible>(object: Object) {
        DispatchQueue.main.async { [context = container.viewContext] in
            let request = Post.fetchRequest()
            request.predicate = NSPredicate(format: "id == %lld", object.id)
            request.fetchLimit = 1
            
            if let object = try? context.fetch(request).first {
                context.delete(object)
                try! context.save()
            }
        }
    }
}
