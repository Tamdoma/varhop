import QtQuick
import QtQuick.Controls
import "FieldKeys.js" as FieldKeys

// Settings view: gh status, repo picker + typed field, sync state, load
// errors, the hotkey chord field and usage reset. Plain QtQuick; everything
// external arrives as a prop and every action leaves as a signal.
Item {
    id: root

    property var syncStatus: ({})       // varhop-sync status JSON
    property string lastPull: ""
    property string lastError: ""
    property var loadErrors: []         // [{kind,path,line,message}]
    property var selection: null        // {repo,login,accountId,repoId}
    property var binds: []              // [{modmask,key,description,submap}]
    property var repos: []              // [{fullName,id,private}]
    property var colors: ({})
    property var copyText: null         // fn(text) — root's Copier path
    property string chordState: "typing"   // typing | conflict | ready
    property string bindLine: ""
    property string conflictText: ""
    property string libraryMismatch: ""

    signal repoChosen(string fullName)
    signal repoTyped(string fullName)
    signal syncNow
    signal resetUsage
    signal backRequested
    signal hideRequested
    signal pullRequested
    signal resumeRequested
    signal confirmReimport

    function c(name, fallback) {
        return colors && colors[name] !== undefined ? colors[name] : fallback
    }
    readonly property color _fg: c("foreground", "#cacccc")
    readonly property color _muted: c("muted", "#707880")
    readonly property color _accent: c("accent", "#cacccc")
    readonly property color _err: c("urgent", "#a55555")

    // Chord vocabulary: MOD+MOD+KEY, modifiers SUPER/SHIFT/CTRL/ALT/META,
    // key one A-Z letter or a named key. No free text ever leaves the field.
    readonly property var _modBits: ({"SHIFT": 1, "CAPS": 2, "CTRL": 4, "ALT": 8, "META": 128, "SUPER": 64})
    readonly property var _keyNames: ["TAB","ESC","ESCAPE","RETURN","ENTER","SPACE","BACKSPACE","DELETE","HOME","END","PAGEUP","PAGEDOWN","UP","DOWN","LEFT","RIGHT"]

    function parseChord(text) {
        if (text === "") return {state: "typing"}
        var parts = text.split("+")
        if (parts.length < 2) return {state: "typing"}
        var key = parts.pop()
        if (!/^[A-Z0-9]$/.test(key) && _keyNames.indexOf(key) === -1)
            return {state: "typing"}
        var mask = 0
        for (var i = 0; i < parts.length; i++) {
            var bit = _modBits[parts[i]]
            if (bit === undefined) return {state: "typing"}
            mask |= bit
        }
        var seen = {}
        for (var j = 0; j < binds.length; j++) {
            var b = binds[j]
            if (b.modmask === mask && String(b.key).toUpperCase() === key)
                return {state: "conflict", description: b.description || "bound", submap: b.submap || ""}
        }
        var pretty = parts.join(" + ") + " + " + key
        return {state: "ready", line: 'o.bind("' + pretty + '", "Varhop prompts", { panel = "ivan.varhop" })'}
    }

    function updateChord(text) {
        var r = parseChord(text)
        chordState = r.state
        bindLine = r.state === "ready" ? r.line : ""
        conflictText = r.state === "conflict"
            ? "in use: " + r.description + (r.submap ? " (" + r.submap + ")" : "")
            : ""
    }

    function handleKey(event) {
        var ctrl = event.modifiers === Qt.ControlModifier
        var ctrlShift = event.modifiers === (Qt.ControlModifier | Qt.ShiftModifier)
        if (ctrl && event.key === Qt.Key_R) {
            pullRequested()
            event.accepted = true
        } else if (ctrl && event.key === Qt.Key_Comma) {
            backRequested()
            event.accepted = true
        } else if (ctrlShift && event.key === Qt.Key_P) {
            resumeRequested()
            event.accepted = true
        } else if (event.key === Qt.Key_Escape) {
            backRequested()
            event.accepted = true
        }
    }

    Keys.onPressed: function(event) { root.handleKey(event) }

    function fieldKeys(event, field) {
        FieldKeys.handle(event, field, {copySelection: true, inertCtrlR: true})
    }

    Flickable {
        anchors.fill: parent
        contentHeight: col.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: col
            width: root.width
            spacing: 14

            // gh status ----------------------------------------------------
            Column {
                width: parent.width
                spacing: 4
                Text {
                    textFormat: Text.PlainText
                    color: root._fg
                    font.pixelSize: 14
                    font.bold: true
                    text: "GitHub"
                }
                Text {
                    textFormat: Text.PlainText
                    color: root._muted
                    font.pixelSize: 12
                    visible: root.syncStatus && root.syncStatus.authenticated === true
                    text: root.syncStatus && root.syncStatus.authenticated === true
                        ? (root.syncStatus.login + " — " + (root.syncStatus.scopes || []).join(", "))
                        : ""
                }
                Text {
                    textFormat: Text.PlainText
                    color: root._err
                    font.pixelSize: 12
                    visible: root.syncStatus && root.syncStatus.authenticated !== true
                    text: root.syncStatus && root.syncStatus.authenticated !== true
                        ? "not authenticated — " + (root.syncStatus.fix || "gh auth login")
                        : ""
                }
            }

            // Repository ---------------------------------------------------
            Column {
                width: parent.width
                spacing: 4
                Text {
                    textFormat: Text.PlainText
                    color: root._fg
                    font.pixelSize: 14
                    font.bold: true
                    text: "Repository"
                }
                Text {
                    visible: root.libraryMismatch !== ""
                    textFormat: Text.PlainText
                    color: root._err
                    font.pixelSize: 12
                    wrapMode: Text.Wrap
                    width: parent.width
                    text: root.libraryMismatch
                }
                Rectangle {
                    visible: root.libraryMismatch !== "" && root.libraryMismatch.indexOf("reconfirm") !== -1
                    width: 110
                    height: 24
                    radius: 4
                    color: root.c("selectedBackground", "#22282c")
                    Text {
                        anchors.centerIn: parent
                        textFormat: Text.PlainText
                        color: root._fg
                        font.pixelSize: 11
                        text: "Confirm reimport"
                    }
                    MouseArea { anchors.fill: parent; onClicked: root.confirmReimport() }
                }
                Text {
                    visible: root.selection !== null
                    textFormat: Text.PlainText
                    color: root._muted
                    font.pixelSize: 12
                    text: root.selection ? root.selection.repo : ""
                }
                TextArea {
                    id: repoField
                    objectName: "repoField"
                    width: parent.width
                    height: 34
                    focus: true
                    onVisibleChanged: { console.log("varhop-vis " + visible); if (visible) forceActiveFocus() }
                    onActiveFocusChanged: console.log("varhop-foc " + activeFocus)
                    Component.onCompleted: forceActiveFocus()
                    wrapMode: TextEdit.NoWrap
                    color: root._fg
                    font.pixelSize: 13
                    textFormat: TextEdit.PlainText
                    placeholderText: "owner/repo"
                    placeholderTextColor: root._muted
                    background: Rectangle {
                        color: "transparent"
                        border.color: root._muted
                        border.width: 1
                        radius: 4
                    }
                    Keys.priority: Keys.BeforeItem
                    Keys.onPressed: function(event) {
                        console.log("varhop-fk " + event.key + " t=" + repoField.text)
                        if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                            && event.modifiers === Qt.NoModifier) {
                            root.repoTyped(repoField.text.trim())
                            event.accepted = true
                        } else {
                            root.fieldKeys(event, repoField)
                        }
                    }
                }
                Repeater {
                    model: root.repos
                    delegate: Rectangle {
                        objectName: "repoRow" + index
                        width: col.width
                        height: 26
                        color: "transparent"
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            textFormat: Text.PlainText
                            color: root._fg
                            font.pixelSize: 12
                            text: modelData.fullName + (modelData.private ? "  (private)" : "")
                        }
                        MouseArea { anchors.fill: parent; onClicked: root.repoChosen(modelData.fullName) }
                    }
                }
                Rectangle {
                    width: 96
                    height: 26
                    radius: 4
                    color: root.c("selectedBackground", "#22282c")
                    Text {
                        anchors.centerIn: parent
                        textFormat: Text.PlainText
                        color: root._fg
                        font.pixelSize: 12
                        text: "Sync now"
                    }
                    MouseArea { anchors.fill: parent; onClicked: root.syncNow() }
                }
                Text {
                    visible: root.lastPull !== ""
                    textFormat: Text.PlainText
                    color: root._muted
                    font.pixelSize: 11
                    text: "last pull " + root.lastPull
                }
                Text {
                    visible: root.lastError !== ""
                    textFormat: Text.PlainText
                    color: root._err
                    font.pixelSize: 11
                    text: root.lastError
                }
            }

            // Load errors ---------------------------------------------------
            Column {
                width: parent.width
                spacing: 2
                visible: root.loadErrors.length > 0
                Text {
                    textFormat: Text.PlainText
                    color: root._err
                    font.pixelSize: 12
                    font.bold: true
                    text: "Load errors"
                }
                Repeater {
                    model: root.loadErrors
                    delegate: Text {
                        width: col.width
                        wrapMode: Text.Wrap
                        textFormat: Text.PlainText
                        color: root._err
                        font.pixelSize: 11
                        text: modelData.path + (modelData.line !== null && modelData.line !== undefined ? ":" + modelData.line : "")
                            + " — " + modelData.message
                    }
                }
            }

            // Hotkey --------------------------------------------------------
            Column {
                width: parent.width
                spacing: 4
                Text {
                    textFormat: Text.PlainText
                    color: root._fg
                    font.pixelSize: 14
                    font.bold: true
                    text: "Hotkey"
                }
                TextArea {
                    id: chordField
                    objectName: "chordField"
                    width: parent.width
                    height: 34
                    wrapMode: TextEdit.NoWrap
                    color: root._fg
                    font.pixelSize: 13
                    textFormat: TextEdit.PlainText
                    placeholderText: "SUPER + ALT + P"
                    placeholderTextColor: root._muted
                    onTextChanged: root.updateChord(text)
                    background: Rectangle {
                        color: "transparent"
                        border.color: root._muted
                        border.width: 1
                        radius: 4
                    }
                    Keys.priority: Keys.BeforeItem
                    Keys.onPressed: function(event) { root.fieldKeys(event, chordField) }
                }
                Text {
                    visible: root.chordState === "conflict"
                    textFormat: Text.PlainText
                    color: root._err
                    font.pixelSize: 11
                    text: root.conflictText
                }
                Text {
                    visible: root.chordState === "ready"
                    textFormat: Text.PlainText
                    color: root._muted
                    font.pixelSize: 11
                    text: "ready — paste into ~/.config/hypr/bindings.lua:"
                }
                Row {
                    visible: root.chordState === "ready"
                    spacing: 8
                    Text {
                        textFormat: Text.PlainText
                        color: root._accent
                        font.pixelSize: 11
                        text: root.bindLine
                    }
                    Rectangle {
                        objectName: "copyBindButton"
                        width: 52
                        height: 20
                        radius: 3
                        color: root.c("selectedBackground", "#22282c")
                        Text {
                            anchors.centerIn: parent
                            textFormat: Text.PlainText
                            color: root._fg
                            font.pixelSize: 10
                            text: "copy"
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: if (root.copyText) root.copyText(root.bindLine)
                        }
                    }
                }
            }

            // Usage ---------------------------------------------------------
            Row {
                spacing: 8
                Rectangle {
                    objectName: "resetUsageButton"
                    width: 190
                    height: 26
                    radius: 4
                    color: root.c("selectedBackground", "#22282c")
                    Text {
                        anchors.centerIn: parent
                        textFormat: Text.PlainText
                        color: root._fg
                        font.pixelSize: 11
                        text: "Reset usage for this repository"
                    }
                    MouseArea { anchors.fill: parent; onClicked: root.resetUsage() }
                }
            }
        }
    }
}
