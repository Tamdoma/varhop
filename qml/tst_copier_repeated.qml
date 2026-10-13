import QtQuick
import Quickshell

Item {
    id: root
    property int copies: 0

    Copier {
        id: copier
        command: ["sh", "-c", 'test "$(cat)" = "repeated"']
        timeoutMs: 1000
        onSucceeded: {
            root.copies++
            if (root.copies === 2) Qt.exit(0)
            else next.start()
        }
        onFailed: function(reason) {
            console.error(reason)
            Qt.exit(1)
        }
    }

    Timer { id: next; interval: 50; running: true; onTriggered: copier.copy("repeated") }
    Timer { interval: 5000; running: true; onTriggered: Qt.exit(2) }
}
