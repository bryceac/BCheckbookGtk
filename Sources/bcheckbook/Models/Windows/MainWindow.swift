import Gtk
import Gdk
import GLibObject
import Foundation

class MainWindow: WindowModel {
    var builder: Builder? = Builder("window")

    lazy var store = ListStore(builder?.get("store", Gtk.ListStoreRef.init).list_store_ptr)!

    let iterator: TreeIter = TreeIter()

    lazy var scrollView = builder?.get("scrollView", ScrolledWindowRef.init)

    // retrieve cell renderers, so that data can be manipulated inside tree view.
    lazy var dateCell = builder?.get("dateCellRenderer", CellRendererTextRef.init)

    lazy var checkNumberCell = builder?.get("checkNumberCellRenderer", CellRendererTextRef.init)

    lazy var isReconciledCell = builder?.get("reconciledCellRenderer", CellRendererToggleRef.init)

    lazy var vendorCell = builder?.get("vendorCellRenderer", CellRendererTextRef.init)

    lazy var memoCell = builder?.get("memoCellRenderer", CellRendererTextRef.init)

    lazy var depositCell = builder?.get("depositCellRenderer", CellRendererTextRef.init)

    lazy var withdrawalCell = builder?.get("withdrawalCellRenderer", CellRendererTextRef.init)

    var application: ApplicationRef? = nil

    // URL for file to be read
    // var fileURL: URL? = nil
    var fileURL: URL? = nil {
        didSet {
            loadRecords()
            updateViews()
        }
    }
 
    // create property to house the transactions
    let records = Records.shared

    override func make(window: Gtk.Window) {
        super.make(window: window)

        window.title = "Hello, World!"
        window.setDefaultSize(width: 800, height: 600)

        var accelGroup: AccelGroup! = {
            let group = AccelGroupRef().link(to: AccelGroup.self)!
            return group
        }()

        window.add(accelGroup: accelGroup)

        var quitItem: MenuItem! = MenuItemRef(label: "Quit").link(to: MenuItem.self)?.apply { item in
            item.addAccelerator(accelSignal: "activate",
            accelGroup: accelGroup,
            accelKey: Int(Gdk.KEY_q),
            accelMods: ModifierType.controlMask,
            accelFlags: AccelFlags.visible)

            item.onActivate { [weak self] _ in
                self?.application?.quit()
            }
        }

        var fileMenu: Menu! = MenuRef().link(to: Menu.self)?.apply { menu in
            menu.append(child: quitItem)
        }

        var fileItem: MenuItem! = MenuItemRef(label: "File").link(to: MenuItem.self)?.apply { item in
            item.set(submenu: fileMenu)
        }

        var menuBar: MenuBar! = MenuBarRef().link(to: MenuBar.self)?.apply { bar in
            bar.append(child: fileItem)    
        }

        self.application?.set(menubar: menuBar)

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