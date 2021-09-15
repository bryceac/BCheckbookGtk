import GLibObject

/* Implement link function from Mikolasstuchlik, as seen at this address:
https://github.com/mikolasstuchlik/BurningRingOfFire/blob/master/Sources/BurningRingOfFire/global/GObject%2BLink.swift
*/
extension GLibObject.ObjectProtocol {
    func link<T: GLibObject.Object>(to type: T.Type) -> T? {
        if let existingObject = self.swiftObj {
            if let correct = existingObject as? T {
                return correct
            } else {
                assertionFailure("Object already linked, but not related.")
                return nil
            }
        }

        if isFloating {
            refSink()
        }

        let new = T.init(raw: self.ptr)

        self.swiftObj = new

        return new
    }
}