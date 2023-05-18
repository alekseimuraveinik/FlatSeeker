import SwiftUI

struct DetailsView: View {
    let viewModel: ListItemViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ListItemView(viewModel: viewModel)
                
                Text(viewModel.text)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .onAppear(perform: viewModel.loadBestImages)
    }
}
