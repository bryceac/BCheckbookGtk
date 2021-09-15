import Gtk
import GLibObject
import CGtk
import GLib
import GIO
import Foundation

/* var appActionEntries = [
    GActionEntry(name: g_strdup("quit"), activate: { Gtk.ApplicationRef(gpointer: $2).quit() }, parameter_type: nil, state: nil, change_state: nil, padding: (0, 0, 0))
] */

let status = Application.run(startupHandler: { app in
    /* if let builder = Builder("menus") {
        app.menubar = builder.get("menuBar", MenuModelRef.init)
    } */
}) { app in
    
    // app.addAction(entries: &appActionEntries, nEntries: appActionEntries.count, userData: app.ptr)
    
    let main = MainWindow(window: ApplicationWindow(application: app))
    main.application = app

    main.fileURL = URL(fileURLWithPath: "/home/bryce/transactions.bcheck").standardizedFileURL
}

guard let status = status else {
    fatalError("Could not create Application")
}

guard status == 0 else {
    fatalError("Application exited with status \(status)")
}