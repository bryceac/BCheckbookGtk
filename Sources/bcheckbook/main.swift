import Gtk
import GLibObject
import CGtk
import GLib
import GLibObject
import GIO
import Foundation

var appActionEntries = [
    GActionEntry(name: g_strdup("quit"), activate: { Gtk.ApplicationRef(gpointer: $2).quit() }, parameter_type: nil, state: nil, change_state: nil, padding: (0, 0, 0))
]

let TEST_FILE = URL(fileURLWithPath: "/home/bryce/transactions.bcheck").standardizedFileURL

if let STORED_RECORDS = try? Record.load(from: TEST_FILE) {
    for record in STORED_RECORDS {
        Records.shared.add(record)
    }
}

let status = Application.run(startupHandler: { app in
    if let builder = Builder("menus") {
        app.menubar = builder.get("menuBar", MenuModelRef.init)
    }
}) { app in
    guard let builder = Builder("window") else {
        print("Could not build the application user interface")
        app.quit()
        return
    }
    app.addAction(entries: &appActionEntries, nEntries: appActionEntries.count, userData: app.ptr)
    let window = ApplicationWindowRef(application: app)
    window.title = "Hello, World!"
    window.setDefaultSize(width: 320, height: 240)
    
    let scrollView = builder.get("scrollView", ScrolledWindowRef.init)
    let iterator = TreeIter()
    let store = ListStore(builder.get("store", Gtk.ListStoreRef.init).list_store_ptr)!
    /* let checkNumberColumn = builder.get("checkNumberColumn", TreeViewColumnRef.init)
    let reconciledColumn = builder.get("reconciledColumn", TreeViewColumnRef.init)
    let vendorColumn = builder.get("vendorColumn", TreeViewColumnRef.init)
    let memoColumn = builder.get("memoColumn", TreeViewColumnRef.init)
    let depositColumn = builder.get("depositColumn", TreeViewColumnRef.init)
    let withdrawalColumn = builder.get("withdrawalColumn", TreeViewColumnRef.init)
    let listView = builder.get("treeView", TreeViewRef.init) */

    /* reconciledColumn.connect(signal: ObjectSignalName(rawValue: "toggled")!, data: nil) {
        guard let selectedRowIndex = listView.selectedRow else { return }
        let RECORD_ID = Records.shared.sortedRecords[selectedRowIndex].id

        guard let record = Records.shared.items.first(where: { $0.id == RECORD_ID }) else { return }

        record.event.isReconciled.toggle()
    } */

    
    // This won't work since column does not have signal called toggles. You need to connect to the Renderer instance
    /*
    reconciledColumn.connect(signal: ObjectSignalName(rawValue: "toggled")!, handler: {
        guard let selectedRowIndex = listView.selectedRow else { return }
        let RECORD_ID = Records.shared.sortedRecords[selectedRowIndex].id

        guard let record = Records.shared.items.first(where: { $0.id == RECORD_ID }) else { return }

        record.event.isReconciled.toggle()
    })
    */

    let toggleCell = builder.get("reconciledCellRenderer", CellRendererToggleRef.init)
    toggleCell.onToggled { [store] _, string in
        let path = TreePath(string: string)

        // Modify the souce of truth of the application
        let RECORD_ID = Records.shared.sortedRecords[path.index].id
        guard let record = Records.shared.items.first(where: { $0.id == RECORD_ID }) else { return }
        record.event.isReconciled.toggle()

        // This is strong reference, only for PoC purposes.
        // Modify the source of truth of the tree view
        let iter = store.iterator(for: path.index)!
        store.setValue(iter: iter, column: 2, value: Value(record.event.isReconciled))
    }

    window.add(widget: scrollView)
    for record in Records.shared.sortedRecords {
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
    window.showAll()
}

guard let status = status else {
    fatalError("Could not create Application")
}

guard status == 0 else {
    fatalError("Application exited with status \(status)")
}