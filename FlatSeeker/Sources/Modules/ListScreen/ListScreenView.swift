import SwiftUI

struct ListScreenView: View {
    @ObservedObject var viewModel: ListScreenViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 20) {
                    PagerView(viewModel: viewModel.pageViewModel)
                        .frame(
                            width: UIScreen.main.bounds.width,
                            height: UIScreen.main.bounds.height / 2
                        )
                        .padding(.top, 20)
                    
                    VStack(alignment: .leading) {
                        if let district = viewModel.district {
                            Text("Район: \(district)")
                        }
                        
                        if let price = viewModel.price {
                            Text("Цена: $\(price)")
                        }
                        
                        Text(viewModel.text)
                            .padding(.top, 20)
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
            }
            
            Button(action: viewModel.onNext) {
                Text("Следующая квартира")
                    .foregroundColor(Color.white)
                    .padding(20)
                    .frame(height: 48)
                    .background(
                        Color.blue
                            .cornerRadius(16)
                    )
            }
        }
        .padding(.bottom, 20)
        .onAppear(perform: viewModel.onAppear)
    }
}
