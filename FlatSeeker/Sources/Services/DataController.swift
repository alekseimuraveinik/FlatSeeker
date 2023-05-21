import CoreData

class DataController {
    let container = NSPersistentContainer(name: "Model")
    private let accessQueue = DispatchQueue(label: "containerAccessQueue")
    
    init() {
        container.loadPersistentStores { _, error in
            if let error {
                print("Core Data failed to load: \(error.localizedDescription)")
            }
        }
    }
    
    func save(post: PostDTO) {
        accessQueue.async { [container] in
            let managedContext = container.viewContext
            let entity = NSEntityDescription.entity(
                forEntityName: "Post",
                in: managedContext
            )!
            
            let person = NSManagedObject(
                entity: entity,
                insertInto: managedContext
            )
              
            person.setValue(post.id, forKeyPath: "id")
            person.setValue(post.text, forKeyPath: "text")
            person.setValue(post.price, forKeyPath: "price")
            person.setValue(post.district, forKeyPath: "district")
              
            try! managedContext.save()
        }
    }
    
    func delete(post: PostDTO) {
        accessQueue.async { [container] in
            let managedContext = container.viewContext
            let request = NSFetchRequest<Post>(entityName: "Post")
            request.predicate = NSPredicate(format: "id == %lld", Int64(post.id))
            request.fetchLimit = 1
            
            let entities = try! managedContext.fetch(request)
            managedContext.delete(entities.first!)
            
            try! managedContext.save()
        }
    }
}
