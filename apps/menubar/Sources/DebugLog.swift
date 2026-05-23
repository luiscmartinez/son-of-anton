import Foundation

/// Append `message` to `/tmp/menubar-debug.log` and also emit via `NSLog`.
///
/// `NSLog` from a Swift LSUIElement app launched via `open` does not always
/// surface in Console.app (the unified log subsystem can swallow or redact
/// messages that don't carry a recognized subsystem/category). The file sink
/// gives us a guaranteed-visible diagnostic stream we can `tail -f` to watch.
///
/// This helper is intentionally global (not @MainActor) so any subsystem can
/// call it without actor hops. The log file is opened/closed per call —
/// acceptable for low-frequency debug instrumentation.
func dbgLog(_ message: String) {
	NSLog(message)
	let line = "\(message)\n"
	guard let data = line.data(using: .utf8) else { return }
	let path = "/tmp/menubar-debug.log"
	let fm = FileManager.default
	if !fm.fileExists(atPath: path) {
		fm.createFile(atPath: path, contents: nil)
	}
	let url = URL(fileURLWithPath: path)
	guard let handle = try? FileHandle(forWritingTo: url) else { return }
	defer { try? handle.close() }
	_ = try? handle.seekToEnd()
	try? handle.write(contentsOf: data)
}
