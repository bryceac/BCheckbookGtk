import Gtk
import Gdk
import GLibObject
import Foundation

class MainWindow: WindowModel {
    var builder: Builder? = Builder("window")

    lazy var store = ListStore(builder?.get("store", Gtk.ListStoreRef.init).list_store_ptr)!
    lazy var categoryStore = ListStore(builder?.get("categoryStore", Gtk.ListStoreRef.init).list_store_ptr)!

    lazy var ledgerListView = TreeView(builder?.get("treeView", TreeViewRef.init).tree_view_ptr)!

    let iterator: TreeIter = TreeIter()

    let categoryIterator = TreeIter()

    lazy var mainArea = builder?.get("mainBox", BoxRef.init)

    // retrieve buttons, so that signals can be handled
    lazy var importButton = builder?.get("importButton", ButtonRef.init)
    lazy var exportButton = builder?.get("exportButton", ButtonRef.init)

    lazy var addButton = builder?.get("addTransactionButton", ButtonRef.init)
    lazy var removeButton = builder?.get("removeTransactionButton", ButtonRef.init)


    // retrieve cell renderers, so that data can be manipulated inside tree view.
    lazy var dateCell = builder?.get("dateCellRenderer", CellRendererTextRef.init)

    lazy var checkNumberCell = builder?.get("checkNumberCellRenderer", CellRendererTextRef.init)

    lazy var isReconciledCell = builder?.get("reconciledCellRenderer", CellRendererToggleRef.init)

    lazy var vendorCell = builder?.get("vendorCellRenderer", CellRendererTextRef.init)

    lazy var categoryCell = builder?.get("categoryCellRenderer", CellRendererComboRef.init)

    lazy var memoCell = builder?.get("memoCellRenderer", CellRendererTextRef.init)

    lazy var depositCell = builder?.get("depositCellRenderer", CellRendererTextRef.init)

    lazy var withdrawalCell = builder?.get("withdrawalCellRenderer", CellRendererTextRef.init)

    var application: ApplicationRef? = nil
 
    // create property to house the transactions
    let records = Records()

    var categories = ["Hello", "World", "7"]

    override func make(window: Gtk.Window) {
        super.make(window: window)

        window.title = "Hello, World!"
        window.setDefaultSize(width: 800, height: 600)

        importButton?.onClicked { _ in

            // create File Chooser, to allow user to specify specific file
            let chooser = FileChooserNative()

            // set labels on file chooser
            chooser.set(acceptLabel: "Open")
            chooser.set(cancelLabel: "Cancel")

            /*
            run dialog and convert response to ResponseType, 
            in order to make sure data is only imported when desired. */
            if case ResponseType.accept = ResponseType(chooser.run()) {

                // retrieve URL string from chooser and convert it to a URL
                let fileURL = URL(string: chooser.getURI())!

                // attempt to parse file and import data into view.
                if let retrievedRecords = try? Record.load(from: fileURL) {
                    self.records.items = retrievedRecords
                    self.updateViews()
                }
            }
        }

        exportButton?.onClicked { _ in

            // create File Chooser, to allow user to specify where to save.
            let chooser = FileChooserNative()

            // tell chooser it is meant to save
            chooser.set(action: FileChooserAction.save)

            // set labels on file chooser
            chooser.set(acceptLabel: "Export")
            chooser.set(cancelLabel: "Cancel")

            // make sure user does not accidentally overwrite file
            chooser.set(doOverwriteConfirmation: true)

            /*
            run dialog and convert response to ResponseType, 
            in order to make sure data is only imported when desired. */
            if case ResponseType.accept = ResponseType(chooser.run()) {

                // retrieve URL string from chooser and convert it to a URL
                let fileURL = URL(string: chooser.getURI())!

                try? self.records.items.save(to: fileURL)
            }
        }

        addButton?.onClicked { _ in
            let record = Record()

            self.records.add(record)
            self.updateViews()
        }

        removeButton?.onClicked { _ in
            let selection = self.ledgerListView.getSelection()
            let _ = selection?.getSelected(iter: self.iterator)

            if let path = self.store.getPath(iter: self.iterator) {
                let record = self.records.sortedRecords[path.index]

                self.records.remove(record)
                self.updateViews()
            }
        }

        checkNumberCell?.onEdited { (_ unOwnedSelf: CellRendererTextRef, _ path: String, _ newValue: String) in
            let path = TreePath(string: path)

            let RECORD_ID = self.records.sortedRecords[path.index].id
            guard let record = self.records.items.first(where: { $0.id == RECORD_ID }) else { return }

            record.event.checkNumber = Int(newValue) 

            self.updateViews()
        }

        // make sure data is modified appropriately for each cell
        dateCell?.onEdited { (_ unOwnedSelf: CellRendererTextRef, _ path: String, _ newValue: String) in
            let path = TreePath(string: path)

            guard let newDate = Event.DF.date(from: newValue) else { return } 

            let RECORD_ID = self.records.sortedRecords[path.index].id
            guard let record = self.records.items.first(where: { $0.id == RECORD_ID }) else { return }

            record.event.date = newDate

            self.updateViews()
        }

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

        categoryCell?.onEdited { (_ unOwnedSelf: CellRendererTextRef, _ path: String, _ newValue: String) in
            let path = TreePath(string: path)

            let RECORD_ID = self.records.sortedRecords[path.index].id
            guard let record = self.records.items.first(where: { $0.id == RECORD_ID }) else { return }

            if newValue.isEmpty || newValue == "Uncategorized" {
                record.event.category = nil
            } else {
                record.event.category = newValue
            }

            self.updateViews()

            guard !newValue.isEmpty && newValue != "Uncategorized" else { return }
            guard !self.categories.contains(where: { category in
                category.lowercased().contains(newValue.lowercased()) ||
                category.caseInsensitiveCompare(newValue) == .orderedSame
            }) else { return }

            self.categories.append(newValue)
            self.updateCategoryList()
        }

        categoryCell?.onChanged{ (unownedSelf: CellRendererComboRef, path: String, selectedIterator: TreeIterRef) in
            let recordPath = TreePath(string: path)
            let RECORD_ID = self.records.sortedRecords[recordPath.index].id

            guard let record = self.records.items.first(where: { $0.id == RECORD_ID }) else { return }

            let categoryPath = self.categoryStore.getPath(iter: selectedIterator)!

            let category = self.categories[categoryPath.index]

            record.event.category = category
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
        window.add(widget: mainArea!)
    }

    override func windowWillOpen() {
        super.windowWillOpen()
        loadCategoryStore()
    }

    func updateViews() {
        store.clear()
        loadStore()
    }

    func updateCategoryList() {
        categoryStore.clear()
        loadCategoryStore()
    }

    private func loadCategoryStore() {
        for category in categories {
            categoryStore.append(asNextRow: categoryIterator, Value(category))
        }
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