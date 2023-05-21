import Combine
import SwiftUI

class ListItemViewModel: ObservableObject {
    let index: Int
    let id: Int
    let text: String
    let district: String?
    let price: Int?
    let carouselViewModel: CarouselViewModel
    
    @Published private(set) var isInFavourites = false
    private let addToFavourite: () -> Void
    private let removeFromFavourite: () -> Void
    
    private var isInFavouritesCancellable: AnyCancellable?
    
    init(
        index: Int,
        post: PostDTO,
        carouselViewModel: CarouselViewModel,
        isInFavourite: AnyPublisher<Bool, Never>,
        addToFavourite: @escaping () -> Void,
        removeFromFavourite: @escaping () -> Void
    ) {
        self.index = index
        id = post.id
        text = post.text
        district = post.district
        price = post.price
        self.carouselViewModel = carouselViewModel
        self.addToFavourite = addToFavourite
        self.removeFromFavourite = removeFromFavourite
        
        isInFavouritesCancellable = isInFavourite
            .receive(on: RunLoop.main)
            .sink { [weak self] isInFavourite in
                self?.isInFavourites = isInFavourite
            }
    }
    
    func toggleFavourite() {
        if isInFavourites {
            removeFromFavourite()
        } else {
            addToFavourite()
        }
    }
}

struct ListItemView: View {
    @ObservedObject var viewModel: ListItemViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            CarouselView(viewModel: viewModel.carouselViewModel)
                .aspectRatio(1, contentMode: .fit)
                .cornerRadius(16)
            
            Text(viewModel.district.flatMap { "Район: \($0)" } ?? "")
            
            Text(viewModel.price.flatMap { "Цена: $\($0)" } ?? "")
        }
        .overlay(alignment: .topTrailing) {
            Button(!viewModel.isInFavourites ? "Добавить в избранное" : "Удалить из избранного") {
                viewModel.toggleFavourite()
            }
            .padding(5)
            .background(Color.white.cornerRadius(8))
            .padding(.top, 5)
            .padding(.trailing, 5)
        }
    }
}
