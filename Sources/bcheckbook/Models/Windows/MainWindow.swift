import Gtk
import GLibObject
import Foundation

class MainWindow: WindowModel {
    var builder: Builder? = Builder("window")

    lazy var store = ListStore(builder?.get("store", Gtk.ListStoreRef.init).list_store_ptr)!

    let iterator: TreeIter = TreeIter()

    lazy var scrollView = builder?.get("scrollView", ScrolledWindowRef.init)

    // retrieve cell renderers, so that data can be manipulated inside tree view.
    lazy var checkNumberCell = builder?.get("checkNumberCellRenderer", CellRendererTextRef.init)

    lazy var isReconciledCell = builder?.get("reconciledCellRenderer", CellRendererToggleRef.init)

    lazy var vendorCell = builder?.get("vendorCellRenderer", CellRendererTextRef.init)

    lazy var memoCell = builder?.get("memoCellRenderer", CellRendererTextRef.init)

    lazy var depositCell = builder?.get("depositCellRenderer", CellRendererTextRef.init)

    lazy var withdrawalCell = builder?.get("withdrawalCellRenderer", CellRendererTextRef.init)

    // URL for file to be read
    var fileURL: URL? = nil
 
    // create property to house the transactions
    let records = Records()

    override func make(window: Window) {
        super.make(window: window)

        window.title = "Hello, World!"
        window.setDefaultSize(width: 800, height: 600)

        checkNumberCell?.onEdited { (_ unOwnedSelf: CellRendererTextRef, _ path: String, _ newValue: String) in
            let path = TreePath(string: path)

            let RECORD_ID = self.records.sortedRecords[path.index].id
            guard let record = self.records.items.first(where: { $0.id == RECORD_ID }) else { return }

            record.event.checkNumber = Int(newValue) 

            self.updateViews()
        }

        // make sure data is modified appropriately for each cell
        isReconciledCell?.onToggled { [weak self] _, string in
            let path = TreePath(string: string)

            let RECORD_ID = self?.records.sortedRecords[path.index].id
            guard let record = self?.records.items.first(where: { $0.id == RECORD_ID }) else { return }
            record.event.isReconciled.toggle()

            self?.updateViews()
        }

        vendorCell?.onEdited { (_ unOwnedSelf: CellRendererTextRef, _ path: String, _ newValue: String) in
            let path = TreePath(string: path)

            let RECORD_ID = self.records.sortedRecords[path.index].id
            guard let record = self.records.items.first(where: { $0.id == RECORD_ID }) else { return }

            record.event.vendor = newValue

            self.updateViews()
        }

        memoCell?.onEdited { (_ unOwnedSelf: CellRendererTextRef, _ path: String, _ newValue: String) in
            let path = TreePath(string: path)

            let RECORD_ID = self.records.sortedRecords[path.index].id
            guard let record = self.records.items.first(where: { $0.id == RECORD_ID }) else { return }

            record.event.memo = newValue

            self.updateViews()
        }

        depositCell?.onEdited { (_ unOwnedSelf: CellRendererTextRef, _ path: String, _ newValue: String) in
            let path = TreePath(string: path)

            guard let amount = Double(newValue) else { return }

            let RECORD_ID = self.records.sortedRecords[path.index].id
            guard let record = self.records.items.first(where: { $0.id == RECORD_ID }) else { return }

            record.event.amount = amount
            record.event.type = .deposit

            self.updateViews()
        }

        withdrawalCell?.onEdited { (_ unOwnedSelf: CellRendererTextRef, _ path: String, _ newValue: String) in
            let path = TreePath(string: path)

            guard let amount = Double(newValue) else { return }

            let RECORD_ID = self.records.sortedRecords[path.index].id
            guard let record = self.records.items.first(where: { $0.id == RECORD_ID }) else { return }

            record.event.amount = amount
            record.event.type = .withdrawal
            
            self.updateViews()
        }
        window.add(widget: scrollView!)
    }

    override func windowWillOpen() {
        super.windowWillOpen()

        fileURL = URL(fileURLWithPath: "/home/bryce/transactions.bcheck").standardizedFileURL
        updateViews()
    }

    func updateViews() {
        if records.items.isEmpty {
            loadRecords()
        }

        // clear List Store, so that reloading data is made easy.
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
                        Value(Event.CURRENCY_FORMAT.string(from: NSNumber(value: record.balance))!))
                    } else {
                        store.append(asNextRow: iterator,
                        Value(Event.DF.string(from: record.event.date)),
                        "N/A",
                        Value(record.event.isReconciled),
                        Value(record.event.vendor),
                        Value(record.event.memo),
                        Value(Event.CURRENCY_FORMAT.string(from: NSNumber(value: record.event.amount))!),
                        "N/A",
                        Value(Event.CURRENCY_FORMAT.string(from: NSNumber(value: record.balance))!))
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
                        Value(Event.CURRENCY_FORMAT.string(from: NSNumber(value: record.balance))!))
                    } else {
                        store.append(asNextRow: iterator,
                        Value(Event.DF.string(from: record.event.date)),
                        "N/A",
                        Value(record.event.isReconciled),
                        Value(record.event.vendor),
                        Value(record.event.memo),
                        "N/A",
                        Value(Event.CURRENCY_FORMAT.string(from: NSNumber(value: record.event.amount))!),
                        Value(Event.CURRENCY_FORMAT.string(from: NSNumber(value: record.balance))!))
                    }
            }
        }
    }
}