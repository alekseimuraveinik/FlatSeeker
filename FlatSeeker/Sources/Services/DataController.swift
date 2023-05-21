import CoreData

class DataController {
    let container = NSPersistentContainer(name: "NSPersistentContainer")
    
    init() {
        container.loadPersistentStores { _, error in
            if let error {
                print("Core Data failed to load: \(error.localizedDescription)")
            }
        }
    }
    
    func save(post: PostDTO) {
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
