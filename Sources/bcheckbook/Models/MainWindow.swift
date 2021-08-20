import Gtk
import GLibObject
import Foundation

class MainWindow: WindowModel {
    var builder: Builder? = Builder("window")

    lazy var store = ListStore(builder?.get("store", Gtk.ListStoreRef.init).list_store_ptr)!

    let iterator: TreeIter = TreeIter()

    lazy var scrollView = builder?.get("scrollView", ScrolledWindowRef.init)

    lazy var checkNumberCell = builder?.get("checkNumberCellRenderer", CellRendererTextRef.init)

    lazy var isReconciledCell = builder?.get("reconciledCellRenderer", CellRendererToggleRef.init)

    var fileURL: URL? = nil

    let records = Records()

    override func make(window: Window) {
        super.make(window: window)

        window.title = "Hello, World!"
        window.setDefaultSize(width: 800, height: 600)

        checkNumberCell?.onEdited { (_ unOwnedSelf: CellRendererTextRef, _ path: String, _ newValue: String) in
            let path = TreePath(string: path)

            guard let checkNumber = Int(newValue) else { return }

            let RECORD_ID = self.records.sortedRecords[path.index].id
            guard let record = self.records.items.first(where: { $0.id == RECORD_ID }), let iter = self.store.iterator(for: path.index)  else { return }

            record.event.checkNumber = checkNumber

            if let checkNumber = record.event.checkNumber {
                self.store.setValue(iter: iter, column: 1, value: Value(checkNumber))
            }
        }

        isReconciledCell?.onToggled { [weak self] _, string in
            let path = TreePath(string: string)

            // Modify the souce of truth of the application
            let RECORD_ID = self?.records.sortedRecords[path.index].id
            guard let record = self?.records.items.first(where: { $0.id == RECORD_ID }), let iter = self?.store.iterator(for: path.index) else { return }
            record.event.isReconciled.toggle()

            // Modify the source of truth of the tree view
            self?.store.setValue(iter: iter, column: 2, value: Value(record.event.isReconciled))
        }
        window.add(widget: scrollView!)
    }

    private func loadRecords() {
        guard let FILE_PATH = self.fileURL, let STORED_RECORDS = try? Record.load(from: FILE_PATH) else { return }
        /* for record in STORED_RECORDS {
             records.add(record)
        } */
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