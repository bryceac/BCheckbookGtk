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

            let RECORD_ID = Records.shared.sortedRecords[path.index].id
            guard let record = Records.shared.items.first(where: { $0.id == RECORD_ID }), let iter = self.store.iterator(for: path.index)  else { return }

            record.event.checkNumber = checkNumber

            if let checkNumber = record.event.checkNumber {
                self.store.setValue(iter: iter, column: 1, value: Value(checkNumber))
            }
        }

        isReconciledCell?.onToggled { [weak self] _, string in
            let path = TreePath(string: string)

            // Modify the souce of truth of the application
            let RECORD_ID = Records.shared.sortedRecords[path.index].id
            guard let record = Records.shared.items.first(where: { $0.id == RECORD_ID }), let iter = self?.store.iterator(for: path.index) else { return }
            record.event.isReconciled.toggle()

            // Modify the source of truth of the tree view
            self?.store.setValue(iter: iter, column: 2, value: Value(record.event.isReconciled))
        }
        window.add(widget: scrollView!)
    }
}