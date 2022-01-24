import Gtk
import Gdk
import GLibObject
import Foundation

class MainWindow: WindowModel {

    // attempt to read file for main window.
    var builder: Builder? = Builder("window")

    // implement liststores to house data for tree view and combo box
    lazy var store = ListStore(builder?.get("store", Gtk.ListStoreRef.init).list_store_ptr)!
    lazy var categoryStore = ListStore(builder?.get("categoryStore", Gtk.ListStoreRef.init).list_store_ptr)!

    // add variable for tree view to get current selection for deltion method
    lazy var ledgerListView = TreeView(builder?.get("treeView", TreeViewRef.init).tree_view_ptr)!

    // implement iterators, to talk to list stores
    let iterator: TreeIter = TreeIter()

    let categoryIterator = TreeIter()

    lazy var mainArea = builder?.get("mainBox", BoxRef.init)

    // retrieve buttons, so that signals can be handled
    lazy var importButton = builder?.get("importButton", ButtonRef.init)
    lazy var exportButton = builder?.get("exportButton", ButtonRef.init)

    lazy var addButton = builder?.get("addTransactionButton", ButtonRef.init)
    lazy var removeButton = builder?.get("removeTransactionButton", ButtonRef.init)

    // connect search field to code.
    lazy var searchField = builder?.get("searchField", SearchEntryRef.init)


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

    override func make(window: Gtk.Window) {
        super.make(window: window)

        window.title = "BCheckbook"
        window.setDefaultSize(width: 800, height: 600)

        importButton?.onClicked { _ in

            // create filter to ensure files are the ones opened
            let filter = FileFilter()
            filter.add(pattern: "*.bcheck")
            filter.set(name: "BCheckbook Files")

            // create File Chooser, to allow user to specify specific file
            let chooser = FileChooserNative()

            // apply filter to chooser
            chooser.add(filter: filter)

            // set labels on file chooser
            chooser.set(acceptLabel: "Import")
            chooser.set(cancelLabel: "Cancel")

            /*
            run dialog and convert response to ResponseType, 
            in order to make sure data is only imported when desired. */
            if case ResponseType.accept = ResponseType(chooser.run()) {

                // retrieve URL string from chooser and convert it to a URL
                let fileURL = URL(string: chooser.getURI())!

                // attempt to parse file and import data into view.
                if let retrievedRecords = try? Record.load(from: fileURL) {
                    self.add(records: retrievedRecords)
                }
            }
        }

        exportButton?.onClicked { _ in

            // create filter to ensure files are saved as bcheck files
            let filter = FileFilter()
            filter.add(pattern: "*.bcheck")
            filter.set(name: "BCheckbook Files")

            // create File Chooser, to allow user to specify where to save.
            let chooser = FileChooserNative()

            // tell chooser it is meant to save
            chooser.set(action: FileChooserAction.save)

            // make sure default name is set correctly.
            chooser.setCurrent(name: "transactions")
            chooser.add(filter: filter)

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
                var fileURL = URL(string: chooser.getURI())!

                if fileURL.pathExtension != "bcheck" {
                    fileURL.appendPathExtension("bcheck")
                }

                try? self.records.items.save(to: fileURL)
            }
        }

        searchField?.onSearchChanged { searchEntry in
            let query = searchEntry.buffer.text 
        }

        addButton?.onClicked { _ in
            let record = Record()

            self.add(record: record)
        }

        removeButton?.onClicked { _ in
            let selection = self.ledgerListView.getSelection()
            let _ = selection?.getSelected(iter: self.iterator)

            if let path = self.store.getPath(iter: self.iterator) {
                let record = self.records.sortedRecords[path.index]

                self.remove(record: record)
            }
        }

        checkNumberCell?.onEdited { (_ unOwnedSelf: CellRendererTextRef, _ path: String, _ newValue: String) in
            let path = TreePath(string: path)

            let RECORD_ID = self.records.sortedRecords[path.index].id
            guard let record = self.records.items.first(where: { $0.id == RECORD_ID }) else { return }

            self.update(record: record)
        }

        // make sure data is modified appropriately for each cell
        dateCell?.onEdited { (_ unOwnedSelf: CellRendererTextRef, _ path: String, _ newValue: String) in
            let path = TreePath(string: path)

            guard let newDate = Event.DF.date(from: newValue) else { return } 

            let RECORD_ID = self.records.sortedRecords[path.index].id
            guard let record = self.records.items.first(where: { $0.id == RECORD_ID }) else { return }

            record.event.date = newDate

            self.update(record: record)
        }

        isReconciledCell?.onToggled { [weak self] _, string in
            let path = TreePath(string: string)

            let RECORD_ID = self?.records.sortedRecords[path.index].id
            guard let record = self?.records.items.first(where: { $0.id == RECORD_ID }) else { return }
            record.event.isReconciled.toggle()

            self?.update(record: record)
        }

        vendorCell?.onEdited { (_ unOwnedSelf: CellRendererTextRef, _ path: String, _ newValue: String) in
            let path = TreePath(string: path)

            let RECORD_ID = self.records.sortedRecords[path.index].id
            guard let record = self.records.items.first(where: { $0.id == RECORD_ID }) else { return }

            record.event.vendor = newValue

            self.update(record: record)
        }

        memoCell?.onEdited { (_ unOwnedSelf: CellRendererTextRef, _ path: String, _ newValue: String) in
            let path = TreePath(string: path)

            let RECORD_ID = self.records.sortedRecords[path.index].id
            guard let record = self.records.items.first(where: { $0.id == RECORD_ID }) else { return }

            record.event.memo = newValue

            self.update(record: record)
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

            self.update(record: record)
            self.updateCategoryList()
        }

        categoryCell?.onChanged{ (unownedSelf: CellRendererComboRef, path: String, selectedIterator: TreeIterRef) in
            let recordPath = TreePath(string: path)
            let RECORD_ID = self.records.sortedRecords[recordPath.index].id

            guard let record = self.records.items.first(where: { $0.id == RECORD_ID }) else { return }

            let categoryPath = self.categoryStore.getPath(iter: selectedIterator)!

            guard let databaseManager = DB.shared.manager, let categories = databaseManager.categories else { return }

            let sortedCategories = categories.sorted(by: <)

            let category = sortedCategories[categoryPath.index]

            record.event.category = category
            self.update(record: record)
        }

        depositCell?.onEdited { (_ unOwnedSelf: CellRendererTextRef, _ path: String, _ newValue: String) in
            let path = TreePath(string: path)

            guard let amount = Double(newValue) else { return }

            let RECORD_ID = self.records.sortedRecords[path.index].id
            guard let record = self.records.items.first(where: { $0.id == RECORD_ID }) else { return }

            record.event.amount = amount
            record.event.type = .deposit

            self.update(record: record)
        }

        withdrawalCell?.onEdited { (_ unOwnedSelf: CellRendererTextRef, _ path: String, _ newValue: String) in
            let path = TreePath(string: path)

            guard let amount = Double(newValue) else { return }

            let RECORD_ID = self.records.sortedRecords[path.index].id
            guard let record = self.records.items.first(where: { $0.id == RECORD_ID }) else { return }

            record.event.amount = amount
            record.event.type = .withdrawal
            
            self.update(record: record)
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
        guard let databaseManager = DB.shared.manager, let categories = databaseManager.categories else { return }

        for category in categories.sorted(by: <) {
            categoryStore.append(asNextRow: categoryIterator, Value(category))
        }
    }

    private func loadRecords() {
        guard let databaseManager = DB.shared.manager, let storedRecords = try? databaseManager.records(inRange: .all) else { return }

        records.items = storedRecords 
    }

    private func add(category: String) {
        guard let databaseManager = DB.shared.manager else { return }

        try? databaseManager.add(category: category)

        updateCategoryList()
    }

    private func add(record: Record) {
        guard let databaseManager = DB.shared.manager else { return }

        try? databaseManager.add(record: record)
        loadRecords()
        updateViews()
    }

    private func remove(record: Record) {
        guard let databaseManager = DB.shared.manager else { return }

        try? databaseManager.remove(record: record)
        loadRecords()
        updateViews()
    }

    private func update(record: Record) {
        guard let databaseManager = DB.shared.manager else { return }

        try? databaseManager.update(record: record)
        loadRecords()
        updateViews()
    }

    private func add(records: [Record]) {
        guard let databaseManager = DB.shared.manager else { return }
        try? databaseManager.add(records: records)
        loadRecords()
        updateViews()
    }

    private func balance(for record: Record) -> Double {
        guard let databaseManager = DB.shared.manager, let recordBalance = try? databaseManager.balance(for: record) else { return 0 }
        return recordBalance
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
                        Value(Event.CURRENCY_FORMAT.string(from: NSNumber(value: balance(for: record)))!))
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
                        Value(Event.CURRENCY_FORMAT.string(from: NSNumber(value: balance(for: record)))!))
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
                        Value(Event.CURRENCY_FORMAT.string(from: NSNumber(value: balance(for: record)))!))
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
                        Value(Event.CURRENCY_FORMAT.string(from: NSNumber(value: self.balance(for: record)))!))
                    }
            }
        }
    }
}