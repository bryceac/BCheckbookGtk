import Foundation
import Gtk
import GLibObject

class WindowModel {
    @GWeak var window: Gtk.WindowRef! = nil

    private var observer: AnyObject? = nil

    @discardableResult
    init(window: Window = Window(type: .toplevel)) {
        self.window = .unowned(window)

        self.observer = window.addWeakObserver { _ in _ = self }

        self.make(window: window)

        window.onDeleteEvent { [weak self] _, _ -> Bool in
            self?.windowWillClose()
            return false
        }

        self.windowWillOpen()
        window.showAll()
    }

    func make(window: Window) {}

    func windowWillOpen() {}

    func windowWillClose() {}
}