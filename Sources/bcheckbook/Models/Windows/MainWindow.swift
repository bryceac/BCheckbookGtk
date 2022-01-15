import Gtk
import Gdk
import GLibObject
import Foundation

class MainWindow: WindowModel {
    let records = Records()

    let iterator: TreeIter = TreeIter()
    let store = ListStore(.string, .string, .boolean, .string, .string, .string, .string, .string)
    let listView = ListView(model: store)

    lazy var scrollView = ScrolledWindow()

    let columns = [
        ("Date", "text", CellRendererText()),
        ("Check #", "text", CellRendererText()),
        ("Reconciled", "active", CellRendererToggle()),
        ("Vendor", "text", CellRendererText()),
        ("Memo", "text", CellRendererText()),
        ("Deposit", "text", CellRendererText()),
        ("Withdrawal", "text", CellRendererText()),
        ("Balance", "text", CellRendererText())
    ].enumerated().map {(i: Int, c:(title: String, kind: PropertyName, renderer: CellRenderer)) in
        TreeViewColumn(i, title: c.title, renderer: c.renderer, attribute: c.kind)
    }

    var application: ApplicationRef? = nil

    // URL for file to be read
    // var fileURL: URL? = nil
    var fileURL: URL? = nil {
        didSet {
            loadRecords()
            updateViews()
        }
    }

    override func make(window: Gtk.Window) {
        super.make(window: window)

        window.title = "BCheckbook"
        window.setDefaultSize(width: 800, height: 600)

        
        window.add(widget: scrollView)
    }

    override func windowWillOpen() {
        super.windowWillOpen()
    }

    func updateViews() {
        store.clear()
        loadStore()
    }

    private func loadRecords() {
        guard let FILE_PATH = self.fileURL, let STORED_RECORDS = try? Record.load(from: FILE_PATH) else { return }
        records.items = STORED_RECORDS
    }

    private func loadStore() {
        for record in records.sortedRecords {
            switch record.event.type {
                case .deposit:
                    if let checkNumber = record.event.checkNumber {
                        store.append(asNextRow: iterator,
                        Value(Event.DF.string(from: record.event.date)),
                        Value("\(checkNumber)"),
                        Value(record.event.isReconciled),
                        Value(record.event.vendor),
                        Value(record.event.memo),
                        Value(Event.CURRENCY_FORMAT.string(from: NSNumber(value: record.event.amount))!),
                        "N/A",
                        Value(Event.CURRENCY_FORMAT.string(from: NSNumber(value: 0.0))!))
                    } else {
                        store.append(asNextRow: iterator,
                        Value(Event.DF.string(from: record.event.date)),
                        "N/A",
                        Value(record.event.isReconciled),
                        Value(record.event.vendor),
                        Value(record.event.memo),
                        Value(Event.CURRENCY_FORMAT.string(from: NSNumber(value: record.event.amount))!),
                        "N/A",
                        Value(Event.CURRENCY_FORMAT.string(from: NSNumber(value: 0.0))!))
                    }
                case .withdrawal:
                    if let checkNumber = record.event.checkNumber {
                        store.append(asNextRow: iterator,
                        Value(Event.DF.string(from: record.event.date)),
                        Value("\(checkNumber)"),
                        Value(record.event.isReconciled),
                        Value(record.event.vendor),
                        Value(record.event.memo),
                        "N/A",
                        Value(Event.CURRENCY_FORMAT.string(from: NSNumber(value: record.event.amount))!),
                        Value(Event.CURRENCY_FORMAT.string(from: NSNumber(value: 0.0))!))
                    } else {
                        store.append(asNextRow: iterator,
                        Value(Event.DF.string(from: record.event.date)),
                        "N/A",
                        Value(record.event.isReconciled),
                        Value(record.event.vendor),
                        Value(record.event.memo),
                        "N/A",
                        Value(Event.CURRENCY_FORMAT.string(from: NSNumber(value: record.event.amount))!),
                        Value(Event.CURRENCY_FORMAT.string(from: NSNumber(value: 0.0))!))
                    }
            }
        }
    }
}