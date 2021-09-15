import Gtk

/*
extension to add synatic sugar for UI, as implemented by Mikolasstuchlik at the following address:
https://github.com/mikolasstuchlik/BurningRingOfFire/blob/master/Sources/BurningRingOfFire/global/Widget%2BExtensions.swift
*/
extension WidgetProtocol {
    public func apple(_ block: (Self) -> Void) -> Self {
        block(self)
        return self
    }
}