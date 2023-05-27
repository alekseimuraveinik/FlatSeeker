import SwiftUI

struct DetailsView: View {
    let viewModel: ListItemViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ListItemView(viewModel: viewModel)
                    .overlay(alignment: .bottomTrailing) {
                        Button {
                            if UIApplication.shared.canOpenURL(viewModel.deeplinkURL) {
                                UIApplication.shared.open(viewModel.deeplinkURL)
                            } else {
                                UIApplication.shared.open(viewModel.postURL)
                            }
                        } label: {
                            Text("Открыть в телеграмме")
                        }
                    }
                
                Text(viewModel.text)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
}
