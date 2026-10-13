import QtQuick
import Quickshell.Io

// Copies text to the Wayland clipboard through `command` (default wl-copy),
// streaming it on stdin. Reports success only on exit 0; a non-zero exit, a
// timeout, or `running` going false with no `exited` (a failed start) is a
// failure. Importing Quickshell.Io only keeps it out of qmltestrunner views.
QtObject {
    id: copier

    property var command: ["wl-copy", "--type", "text/plain;charset=utf-8"]
    property int timeoutMs: 5000
    property bool busy: false

    signal succeeded
    signal failed(string reason)

    function copy(text) {
        if (busy) return false
        busy = true
        proc.sawExited = false
        proc.pendingText = text
        proc.running = true
        watchdog.restart()
        return true
    }

    function finish(ok, reason) {
        watchdog.stop()
        proc.running = false
        proc.pendingText = ""
        busy = false
        if (ok) succeeded()
        else failed(reason)
    }

    property Timer watchdog: Timer {
        interval: copier.timeoutMs
        repeat: false
        onTriggered: copier.finish(false, "copy timed out after " + copier.timeoutMs + " ms")
    }

    property Process proc: Process {
        property string pendingText: ""
        property bool sawExited: false
        command: copier.command
        stdinEnabled: true
        running: false
        onStarted: {
            write(pendingText)
            stdinEnabled = false
        }
        onExited: function(exitCode, exitStatus) {
            sawExited = true
            copier.finish(exitCode === 0, "copy exited " + exitCode)
        }
        onRunningChanged: {
            // Failed start: running turns false and `exited` never fires.
            if (!running && !sawExited && copier.busy)
                copier.finish(false, "copy failed to start")
        }
    }
}
