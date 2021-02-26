import UIKit

final class CardReaderSettingsConnectedReaderView: NSObject {

    /// A simple model for this "ViewModel" - just a reference to the CardReaderSettingsViewModel connected reader
    var connectedReader: CardReader?

    var onPressedDisconnect: (() -> ())?

    private var rows = [Row]()

    override init() {
        super.init()
        rows = [
            .connectedReader,
            .disconnectButton
        ]
    }

    public func rowTypes() -> [UITableViewCell.Type] {
        return [
            ConnectedReaderTableViewCell.self,
            ButtonTableViewCell.self
        ]
    }

    public func update(reader: CardReader) {
        connectedReader = reader
    }

    private func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as ConnectedReaderTableViewCell where row == .connectedReader:
            configureConnectedReader(cell: cell)
        case let cell as ButtonTableViewCell where row == .disconnectButton:
            configureButton(cell: cell)
        default:
            fatalError()
        }
    }

    private func configureConnectedReader(cell: ConnectedReaderTableViewCell) {
        let batteryLevel = connectedReader?.batteryLevel ?? 1.0
        let batteryLevelPercent = Int(100 * batteryLevel)
        let batteryLevelString = NumberFormatter.localizedString(from: batteryLevelPercent as NSNumber, number: .decimal)

        let batteryLabelFormat = NSLocalizedString(
            "%1$@%% Battery",
            comment: "Settings > Manage Card Reader > Connected Reader >> Battery level as a percentage"
        )

        cell.batteryLevelLabel?.text = String.localizedStringWithFormat(batteryLabelFormat, batteryLevelString)
        cell.serialNumberLabel?.text = connectedReader?.serialNumber ?? "Unknown"
        cell.hideSeparator()
        cell.selectionStyle = .none
    }

    private func configureButton(cell: ButtonTableViewCell) {
        let buttonTitle = NSLocalizedString(
            "Disconnect",
            comment: "Settings > Manage Card Reader > Connected Reader > A button to disconnect the reader"
        )
        cell.configure(title: buttonTitle) { [weak self] in
            self?.onPressedDisconnect?()
        }
        cell.hideSeparator()
        cell.selectionStyle = .none
    }
}

private enum Row: CaseIterable {
    case connectedReader
    case disconnectButton

    var type: UITableViewCell.Type {
        switch self {
        case .connectedReader:
            return ConnectedReaderTableViewCell.self
        case .disconnectButton:
            return ButtonTableViewCell.self
        }
    }

    var reuseIdentifier: String {
        return type.reuseIdentifier
    }
}

// MARK: - Convenience Methods
//
private extension CardReaderSettingsConnectedReaderView {
    func rowAtIndexPath(_ indexPath: IndexPath) -> Row {
        return rows[indexPath.row]
    }
}

// MARK: - UITableViewDataSource Conformance
//
extension CardReaderSettingsConnectedReaderView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return NSLocalizedString(
            "CONNECTED READER",
            comment: "Settings > Manage Card Reader > Connected Reader Table Section Heading"
        )
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = rowAtIndexPath(indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: row.reuseIdentifier, for: indexPath)
        configure(cell, for: row, at: indexPath)
        return cell
    }
}

// MARK: - UITableViewDelegate Conformance
//
extension CardReaderSettingsConnectedReaderView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = rowAtIndexPath(indexPath)
        if row == .connectedReader {
            return 60
        }
        return UITableView.automaticDimension
    }}
