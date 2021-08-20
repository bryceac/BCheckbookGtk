import Gtk
import GLibObject

/* Extension from Mikolasstuchlik's Matika project, 
which can be found at https://github.com/mikolasstuchlik/Matika.

This provides handle UI creation, by making it easier to add things via closures. */
public extension WidgetProtocol {
    func apply(_ block: (Self) -> Void) -> Self {
        block(self)
        return self
    }
}