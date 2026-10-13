import QtQuick
import Quickshell

// Standalone probe for Copier.qml failure paths (proofs-overlay.md row 21):
// non-zero exit, a missing binary and a timeout must each report failure.
// Exits 0 when every case reports failure; prints "copier-probe: ..." and
// exits 1 otherwise.
Item {
    id: root

    property var results: []
    property int expected: 4
    property int finished: 0

    function note(name, ok) {
        results.push((ok ? "ok " : "FAIL ") + name)
        finished++
        if (finished === expected) {
            var bad = []
            for (var i = 0; i < results.length; i++)
                if (results[i].indexOf("FAIL") === 0) bad.push(results[i])
            if (bad.length > 0) {
                console.log("copier-probe: " + bad.join("; "))
                Qt.exit(1)
            } else {
                Qt.exit(0)
            }
        }
    }

    Component {
        id: copierComp
        Copier {}
    }

    Timer { interval: 200; running: true; onTriggered: seq.start() }
    Timer { interval: 20000; running: true; onTriggered: { console.log("copier-probe: timeout"); Qt.exit(1) } }

    QtObject {
        id: seq
        property int step: -1
        property var cur: null
        function start() { next() }
        function next() {
            step++
            if (cur) { cur.destroy(); cur = null }
            switch (step) {
            case 0: run("false", ["false"], 4000); break
            case 1: run("missing-binary", ["/nonexistent-varhop-bin-xyz"], 4000); break
            case 2: run("timeout", ["sleep", "10"], 500); break
            case 3: runSuccess("stdin-copy", ["wl-copy", "--type", "text/plain;charset=utf-8"], 4000); break
            default: root.expected = 4; break
            }
        }
        function run(name, cmd, ms) {
            var c = copierComp.createObject(root, {command: cmd, timeoutMs: ms})
            c.succeeded.connect(function() {
                root.note(name, false); seq.next()
            })
            c.failed.connect(function(reason) {
                root.note(name, true); seq.next()
            })
            cur = c
            c.copy("probe")
        }
        function runSuccess(name, cmd, ms) {
            var c = copierComp.createObject(root, {command: cmd, timeoutMs: ms})
            c.succeeded.connect(function() {
                root.note(name, true); seq.next()
            })
            c.failed.connect(function(reason) {
                root.note(name, false); seq.next()
            })
            cur = c
            c.copy("probe")
        }
    }
}
