import SwiftUI

struct ListItemViewModel: Identifiable {
    let id: Int
    let text: String
    let district: String?
    let price: String?
    let carouselViewModel: CarouselViewModel
    
    init(group: MessageGroup, carouselViewModel: CarouselViewModel) {
        id = group.id
        text = group.textMessage
        district = group.district
        price = group.price
        self.carouselViewModel = carouselViewModel
    }
    
    func loadBestImages() {
        carouselViewModel.loadBestImages()
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
