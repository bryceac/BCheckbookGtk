import Gtk

extension WidgetProtocol {
    public func apple(_ block: (Self) -> Void) -> Self {
        block(self)
        return self
    }
}