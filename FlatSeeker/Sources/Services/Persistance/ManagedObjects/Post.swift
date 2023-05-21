import CoreData

@objc(Post)
class Post: NSManagedObject {
    convenience init(context: NSManagedObjectContext, post: PostDTO) {
        self.init(context: context)
        
        id = NSNumber(value: post.id)
        text = post.text
        price = post.price.map(NSNumber.init(value:))
        district = post.district
    }
    
    var postDTO: PostDTO {
        PostDTO(
            id: Int(truncating: id!),
            text: text!,
            price: price.map(Int.init(truncating:)),
            district: district,
            images: []
        )
    }
}
