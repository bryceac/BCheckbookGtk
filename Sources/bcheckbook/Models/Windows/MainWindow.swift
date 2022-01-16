import Gtk
import Gdk
import GLibObject
import Foundation

class MainWindow: WindowModel {
    let records = Records()

    let iterator: TreeIter = TreeIter()
    let store = ListStore(.string, .string, .boolean, .string, .string, .string, .string, .string, .string)

    let categoryStore = ListStore(.string)
    let categoryIterator = TreeIter()

    let dateCell = CellRendererText()
    let checkNumberCell = CellRendererText()
    let reconciledCell = CellRendererToggle()
    let vendorCell = CellRendererText()
    let memoCell = CellRendererText()
    let categoryCell = CellRendererCombo()
    let depositCell = CellRendererText()
    let withdrawalCell = CellRendererText()

    var categories = ["Hello", "World", "7"]
    

    var scrollView = ScrolledWindow()

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

        for category in categories {
            categoryStore.append(asNextRow: categoryIterator, values: [Value(category)])
        }

        let columns = [
        ("Date", "text", dateCell),
        ("Check #", "text", checkNumberCell),
        ("Reconciled", "active", reconciledCell),
        ("Vendor", "text", vendorCell),
        ("Memo", "text", memoCell),
        ("Category", "text", categoryCell),
        ("Deposit", "text", depositCell),
        ("Withdrawal", "text", withdrawalCell),
        ("Balance", "text", CellRendererText())
        ].enumerated().map {(i: Int, c:(title: String, kind: PropertyName, renderer: CellRenderer)) in
            TreeViewColumn(i, title: c.title, renderer: c.renderer, attribute: c.kind)
        }

        let listView = ListView(model: store)
        listView.append(columns)

        dateCell.set(property: 
        .editable, value: true)

        dateCell.onEdited { (_ unOwnedSelf: CellRendererTextRef, _ path: String, _ newValue: String) in
            let path = TreePath(string: path)

            guard let newDate = Event.DF.date(from: newValue) else { return } 

            let RECORD_ID = self.records.sortedRecords[path.index].id
            guard let record = self.records.items.first(where: { $0.id == RECORD_ID }) else { return }

            record.event.date = newDate

            self.updateViews()
        }

        checkNumberCell.set(property: .editable, value: true)

        checkNumberCell.onEdited { (_ unOwnedSelf: CellRendererTextRef, _ path: String, _ newValue: String) in
            let path = TreePath(string: path)

            let newCheckNumber = Int(newValue)

            let RECORD_ID = self.records.sortedRecords[path.index].id
            guard let record = self.records.items.first(where: { $0.id == RECORD_ID }) else { return }

            record.event.checkNumber = newCheckNumber

            self.updateViews()
        }

        reconciledCell.set(property: .activatable, value: true)

        reconciledCell.onToggled { [weak self] _, string in
            let path = TreePath(string: string)

            let RECORD_ID = self?.records.sortedRecords[path.index].id
            guard let record = self?.records.items.first(where: { $0.id == RECORD_ID }) else { return }
            record.event.isReconciled.toggle()

            self?.updateViews()
        }

        vendorCell.set(property: 
        .editable, value: true)

        vendorCell.onEdited { (_ unOwnedSelf: CellRendererTextRef, _ path: String, _ newValue: String) in
            let path = TreePath(string: path) 

            let RECORD_ID = self.records.sortedRecords[path.index].id
            guard let record = self.records.items.first(where: { $0.id == RECORD_ID }) else { return }

            record.event.vendor = newValue

            self.updateViews()
        }

        memoCell.set(property: .editable, value: true)

        memoCell.onEdited { (_ unOwnedSelf: CellRendererTextRef, _ path: String, _ newValue: String) in
            let path = TreePath(string: path)

            let RECORD_ID = self.records.sortedRecords[path.index].id
            guard let record = self.records.items.first(where: { $0.id == RECORD_ID }) else { return }

            record.event.memo = newValue

            self.updateViews()
        }

        categoryCell.set(property: 
        .editable, value: true)
        categoryCell.set(property: .model, value: Value(categoryStore))
        categoryCell.set(property: .textColumn, value: 0)
        categoryCell.set(property: .hasEntry, value: true)

        categoryCell.onEdited { (_ unOwnedSelf: CellRendererTextRef, _ path: String, _ newValue: String) in
            let path = TreePath(string: path) 

            let RECORD_ID = self.records.sortedRecords[path.index].id
            guard let record = self.records.items.first(where: { $0.id == RECORD_ID }) else { return }

            record.event.category = !newValue.isEmpty ?  newValue : nil

            self.updateViews()
        }

        depositCell.set(property: .editable, value: true)

        depositCell.onEdited { (_ unOwnedSelf: CellRendererTextRef, _ path: String, _ newValue: String) in
            let path = TreePath(string: path)

            let RECORD_ID = self.records.sortedRecords[path.index].id
            guard let record = self.records.items.first(where: { $0.id == RECORD_ID }) else { return }

            if let newAmount = Double(newValue) {
                record.event.amount = newAmount
            } else if let amountNumber = Event.CURRENCY_FORMAT.number(from: newValue) {
                record.event.amount = amountNumber.doubleValue
            }

            record.event.type = .deposit
            
            self.updateViews()
        }

        withdrawalCell.set(property: .editable, value: true)

        withdrawalCell.onEdited { (_ unOwnedSelf: CellRendererTextRef, _ path: String, _ newValue: String) in
            let path = TreePath(string: path)

            let RECORD_ID = self.records.sortedRecords[path.index].id
            guard let record = self.records.items.first(where: { $0.id == RECORD_ID }) else { return }

            if let newAmount = Double(newValue) {
                record.event.amount = newAmount
            } else if let amountNumber = Event.CURRENCY_FORMAT.number(from: newValue) {
                record.event.amount = amountNumber.doubleValue
            }

            record.event.type = .withdrawal
            
            self.updateViews()
        }

        scrollView.addWithViewport(child: listView)

        
        window.add(widget: scrollView)
    }

    override func windowWillOpen() {
        super.windowWillOpen()
        loadRecords()
        loadStore()
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
                        Value(record.event.category ?? "Uncategorized"),
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
                        Value(record.event.category ?? "Uncategorized"),
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
                        Value(record.event.category ?? "Uncategorized"),
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
                        Value(record.event.category ?? "Uncategorized"),
                        "N/A",
                        Value(Event.CURRENCY_FORMAT.string(from: NSNumber(value: record.event.amount))!),
                        Value(Event.CURRENCY_FORMAT.string(from: NSNumber(value: 0.0))!))
                    }
            }
        }
    }
}