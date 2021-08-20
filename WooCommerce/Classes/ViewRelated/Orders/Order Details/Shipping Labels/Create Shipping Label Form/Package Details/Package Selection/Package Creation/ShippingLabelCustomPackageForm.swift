import SwiftUI
import Combine

/// Form to create a new custom package to use with shipping labels.
struct ShippingLabelCustomPackageForm: View {
    private let safeAreaInsets: EdgeInsets

    @Environment(\.presentationMode) var presentation
    @StateObject private var viewModel = ShippingLabelCustomPackageFormViewModel()
    @State private var showingPackageTypes = false

    init(safeAreaInsets: EdgeInsets) {
        self.safeAreaInsets = safeAreaInsets
    }

    var body: some View {
        VStack(spacing: Constants.verticalSpacing) {
                ListHeaderView(text: Localization.customPackageHeader, alignment: .left)
                    .padding(.horizontal, insets: safeAreaInsets)

                // Package Type & Name
                VStack(spacing: 0) {
                    Divider()
                    VStack(spacing: 0) {
                        // Package type
                        TitleAndValueRow(title: Localization.packageTypeLabel,
                                         value: viewModel.packageType.localizedName,
                                         selectable: true) {
                            showingPackageTypes.toggle()
                        }
                        .sheet(isPresented: $showingPackageTypes, content: {
                            SelectionList(title: Localization.packageTypeLabel,
                                          items: ShippingLabelCustomPackageFormViewModel.PackageType.allCases,
                                          contentKeyPath: \.localizedName,
                                          selected: $viewModel.packageType)
                        })

                        Divider()
                            .padding(.leading, Constants.horizontalPadding)

                        // Package name
                        TitleAndTextFieldRow(title: Localization.packageNameLabel,
                                             placeholder: Localization.packageNamePlaceholder,
                                             text: $viewModel.packageName,
                                             symbol: nil,
                                             keyboardType: .default)
                            .onReceive(viewModel.packageNameValidation, perform: { validated in
                                viewModel.isNameValidated = validated
                            })
                    }
                    .padding(.horizontal, insets: safeAreaInsets)
                    Divider()
                    validationErrorRow
                        .renderedIf(!viewModel.isNameValidated)
                }
                .background(Color(.systemBackground).ignoresSafeArea(.container, edges: .horizontal))

                // Package Dimensions
                VStack(spacing: 0) {
                    Divider()

                    // Package length
                    VStack(spacing: 0) {
                        TitleAndTextFieldRow(title: Localization.lengthLabel,
                                             placeholder: "0",
                                             text: $viewModel.packageLength,
                                             symbol: viewModel.lengthUnit,
                                             keyboardType: .decimalPad)
                            .onReceive(viewModel.packageLengthValidation, perform: { validated in
                                viewModel.isLengthValidated = validated
                            })
                        Divider()
                            .padding(.leading, Constants.horizontalPadding)
                    }
                    .padding(.horizontal, insets: safeAreaInsets)
                    validationErrorRow
                        .renderedIf(!viewModel.isLengthValidated)

                    // Package width
                    VStack(spacing: 0) {
                        TitleAndTextFieldRow(title: Localization.widthLabel,
                                             placeholder: "0",
                                             text: $viewModel.packageWidth,
                                             symbol: viewModel.lengthUnit,
                                             keyboardType: .decimalPad)
                            .onReceive(viewModel.packageWidthValidation, perform: { validated in
                                viewModel.isWidthValidated = validated
                            })

                        Divider()
                            .padding(.leading, Constants.horizontalPadding)
                    }
                    .padding(.horizontal, insets: safeAreaInsets)
                    validationErrorRow
                        .renderedIf(!viewModel.isWidthValidated)

                    // Package height
                    VStack(spacing: 0) {
                        TitleAndTextFieldRow(title: Localization.heightLabel,
                                             placeholder: "0",
                                             text: $viewModel.packageHeight,
                                             symbol: viewModel.lengthUnit,
                                             keyboardType: .decimalPad)
                            .onReceive(viewModel.packageHeightValidation, perform: { validated in
                                viewModel.isHeightValidated = validated
                            })
                    }
                    .padding(.horizontal, insets: safeAreaInsets)
                    Divider()
                    validationErrorRow
                        .renderedIf(!viewModel.isHeightValidated)
                }
                .background(Color(.systemBackground).ignoresSafeArea(.container, edges: .horizontal))

                // Package Weight
                VStack(spacing: 0) {
                    Divider()
                    TitleAndTextFieldRow(title: Localization.emptyPackageWeightLabel,
                                         placeholder: "0",
                                         text: $viewModel.emptyPackageWeight,
                                         symbol: viewModel.weightUnit,
                                         keyboardType: .decimalPad)
                        .padding(.horizontal, insets: safeAreaInsets)
                        .background(Color(.systemBackground).ignoresSafeArea(.container, edges: .horizontal))
                        .onReceive(viewModel.packageWeightValidation, perform: { validated in
                            viewModel.isWeightValidated = validated
                        })
                    Divider()
                    validationErrorRow
                        .renderedIf(!viewModel.isWeightValidated)
                    ListHeaderView(text: Localization.weightFooter, alignment: .left)
                        .padding(.horizontal, insets: safeAreaInsets)
                }
        }
        .background(Color(.listBackground))
        .ignoresSafeArea(.container, edges: .horizontal)
        .minimalNavigationBarBackButton()
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing, content: {
                Button(Localization.doneButton, action: {
                    // TODO-4743: Save custom package and add it to package list
                    presentation.wrappedValue.dismiss()
                }).disabled(!viewModel.isPackageValidated)
            })
        }
        .onReceive(viewModel.packageValidation, perform: { validated in
            viewModel.isPackageValidated = validated
        })
    }

    private var validationErrorRow: some View {
        ValidationErrorRow(errorMessage: Localization.validationError)
            .background(Color(.listBackground).ignoresSafeArea(.container, edges: .horizontal))
            .padding(.horizontal, insets: safeAreaInsets)
    }
}

private extension ShippingLabelCustomPackageForm {
    enum Localization {
        static let customPackageHeader = NSLocalizedString(
            "Set up the package you'll be using to ship your products. We'll save it for future orders.",
            comment: "Header text on Add New Custom Package screen in Shipping Label flow")
        static let packageTypeLabel = NSLocalizedString(
            "Package Type",
            comment: "Title for the row to select the package type (box or envelope) on the Add New Custom Package screen in Shipping Label flow")
        static let packageTypePlaceholder = NSLocalizedString(
            "Select Type",
            comment: "Placeholder for the row to select the package type (box or envelope) on the Add New Custom Package screen in Shipping Label flow")
        static let packageNameLabel = NSLocalizedString(
            "Package Name",
            comment: "Title for the row to enter the package name on the Add New Custom Package screen in Shipping Label flow")
        static let packageNamePlaceholder = NSLocalizedString(
            "Enter Name",
            comment: "Placeholder for the row to enter the package name on the Add New Custom Package screen in Shipping Label flow")
        static let lengthLabel = NSLocalizedString(
            "Length",
            comment: "Title for the row to enter the package length on the Add New Custom Package screen in Shipping Label flow")
        static let widthLabel = NSLocalizedString(
            "Width",
            comment: "Title for the row to enter the package width on the Add New Custom Package screen in Shipping Label flow")
        static let heightLabel = NSLocalizedString(
            "Height",
            comment: "Title for the row to enter the package height on the Add New Custom Package screen in Shipping Label flow")
        static let emptyPackageWeightLabel = NSLocalizedString(
            "Empty Package Weight",
            comment: "Title for the row to enter the empty package weight on the Add New Custom Package screen in Shipping Label flow")
        static let weightFooter = NSLocalizedString(
            "Weight of empty package",
            comment: "Footer text for the empty package weight on the Add New Custom Package screen in Shipping Label flow")
        static let validationError = NSLocalizedString(
            "This field is required",
            comment: "Error for missing package details on the Add New Custom Package screen in Shipping Label flow")
        static let doneButton = NSLocalizedString("Done", comment: "Done navigation button in the Custom Package screen in Shipping Label flow")
    }

    enum Constants {
        static let horizontalPadding: CGFloat = 16
        static let verticalSpacing: CGFloat = 16
    }
}

struct ShippingLabelAddCustomPackage_Previews: PreviewProvider {
    static var previews: some View {
        ShippingLabelCustomPackageForm(safeAreaInsets: .zero)
            .previewLayout(.sizeThatFits)
    }
}
