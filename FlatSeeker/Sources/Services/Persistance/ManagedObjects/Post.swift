import CoreData

@objc(Post)
class Post: NSManagedObject {
    @nonobjc class func fetchRequest() -> NSFetchRequest<Post> {
        NSFetchRequest<Post>(entityName: "Post")
    }

    @NSManaged var id: NSNumber
    @NSManaged var text: String
    @NSManaged var price: NSNumber?
    @NSManaged var district: String?
}

extension Post {
    convenience init(context: NSManagedObjectContext, post: PostDTO) {
        self.init(context: context)
        
        id = NSNumber(value: post.id)
        text = post.text
        price = post.price.flatMap(NSNumber.init(value:))
        district = post.district
    }
    
    var postDTO: PostDTO {
        PostDTO(
            id: Int(truncating: id),
            text: text,
            price: price.flatMap(Int.init(truncating:)),
            district: district,
            images: []
        )
    }
}
