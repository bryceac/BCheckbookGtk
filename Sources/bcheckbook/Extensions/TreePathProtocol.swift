import Gtk
import CGtk
import GLibObject
import GLib

public extension TreePathProtocol {
    var index: Int? {
        guard let indices = self.getIndices() else { return nil }
        
        return Int(indices.pointee)
    }
}