import SwiftUI

class ListItemViewModel {
    let id: Int
    let text: String
    let district: String?
    let price: String?
    let carouselViewModel: CarouselViewModel
    
    init(post: Post, carouselViewModel: CarouselViewModel) {
        id = post.id
        text = post.text
        district = post.district
        price = post.price
        self.carouselViewModel = carouselViewModel
    }
}

struct ListItemView: View {
    let viewModel: ListItemViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            CarouselView(viewModel: viewModel.carouselViewModel)
                .aspectRatio(1, contentMode: .fit)
                .cornerRadius(16)
            
            Text(viewModel.district.flatMap { "Район: \($0)" } ?? "")
            
            Text(viewModel.price.flatMap { "Цена: $\($0)" } ?? "")
        }
    }
}
