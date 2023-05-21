import CoreData

@objc(Post)
final class Post: NSManagedObject, ConvertibleManagedObject {
    fileprivate convenience init(context: NSManagedObjectContext, post: PostDTO) {
        self.init(context: context)
        
        id = NSNumber(value: post.id)
        text = post.text
        price = post.price.map(NSNumber.init(value:))
        district = post.district
    }
    
    var dto: PostDTO {
        PostDTO(
            id: Int(truncating: id!),
            text: text!,
            price: price.map(Int.init(truncating:)),
            district: district,
            images: []
        )
    }
}

extension PostDTO: ManagedObjectConvertible {
    func createManagedObject(for context: NSManagedObjectContext) -> NSManagedObject {
        Post(context: context, post: self)
    }
}
