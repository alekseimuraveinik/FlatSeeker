import SwiftUI

struct ListItemViewModel {
    let text: String
    let district: String?
    let price: String?
    let carouselViewModel: CarouselViewModel
    
    init(group: Post, carouselViewModel: CarouselViewModel) {
        text = group.textMessage
        district = group.district
        price = group.price
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
