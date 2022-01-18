import Gtk
import GLibObject
import CGtk
import GLib
import GIO
import Foundation

let status = Application.run() { app in
    let main = MainWindow(window: ApplicationWindow(application: app))
    main.application = app

    main.run()
}

guard let status = status else {
    fatalError("Could not create Application")
}

guard status == 0 else {
    fatalError("Application exited with status \(status)")
}