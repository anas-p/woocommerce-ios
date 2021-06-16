import SwiftUI

/// Renders a product add-on
///
struct ProductAddOn: View {

    /// Representation of the view state.
    ///
    let viewModel: ProductAddOnViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            Text(viewModel.name)
                .headlineStyle()
                .padding([.leading, .trailing])

            HStack(alignment: .bottom) {
                Text(viewModel.description)
                    .subheadlineStyle()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .renderedIf(viewModel.showDescription)

                Text(viewModel.price)
                    .secondaryBodyStyle()
                    .renderedIf(viewModel.showPrice)
            }
            .padding([.leading, .trailing])

            Spacer()
                .frame(height: 2)

            ForEach(viewModel.options) { option in
                HStack(alignment: .bottom) {
                    Text(option.name)
                        .bodyStyle()
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(option.price)
                        .secondaryBodyStyle()
                        .renderedIf(option.showPrice)
                }
                .padding([.leading, .trailing])

                Divider()
                    .padding(.leading)
            }
        }
        .background(Color(.basicBackground))
    }
}

// MARK: Previews
struct ProductAddOn_Previews: PreviewProvider {

    static let toppingViewModel = ProductAddOnViewModel(name: "Pizza Topping",
                                                 description: "Select your favorite topping",
                                                 price: "",
                                                 options: [
                                                    .init(name: "Peperoni", price: "$2.99"),
                                                    .init(name: "Salami", price: "$1.99"),
                                                    .init(name: "Ham", price: "$1.99"),
                                                 ])
    static let deliveryViewModel = ProductAddOnViewModel(name: "Delivery",
                                                 description: "Weather you need delivery or not",
                                                 price: "$6.00",
                                                 options: [])

    static var previews: some View {
        VStack {
            ProductAddOn(viewModel: toppingViewModel)
                .environment(\.colorScheme, .light)

            Spacer()
                .frame(height: 20)

            ProductAddOn(viewModel: deliveryViewModel)
                .environment(\.colorScheme, .light)
        }
    }
}
