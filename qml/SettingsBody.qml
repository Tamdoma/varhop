import QtQuick
import QtQuick.Controls
import "FieldKeys.js" as FieldKeys
import "../lib/fold.mjs" as Fold

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
    property string reposState: "ready" // loading | failed | ready, from the list process exit
    property QtObject theme
    property QtObject tokens
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
    signal lookupAccepted(string fullName, var repoId)

    // Picker: case- and accent-insensitive substring matches on fullName in
    // A-Z order. The highlight is keyed by repo id so a refresh keeps it.
    readonly property var filteredRepos: _filtered(repoField.text)
    property var _highlightId: null
    readonly property int pickerIndex: {
        for (var i = 0; i < filteredRepos.length; i++)
            if (_highlightId !== null && filteredRepos[i].id === _highlightId) return i
        return -1
    }
    readonly property int _rowHeight: Math.ceil(tokens.font.title * 1.4) + 2 * tokens.spacing.xs

    function _filtered(text) {
        var q = Fold.fold(text.trim())
        return repos.slice()
            .sort(function(a, b) {
                var x = a.fullName.toLowerCase(), y = b.fullName.toLowerCase()
                return x < y ? -1 : x > y ? 1 : 0
            })
            .filter(function(r) { return q === "" || Fold.fold(r.fullName).indexOf(q) !== -1 })
    }

    // After each text change: the exact match, else the first match.
    function _highlightFor(text) {
        var list = _filtered(text)
        var q = Fold.fold(text.trim())
        if (q === "" || list.length === 0) return null
        for (var i = 0; i < list.length; i++)
            if (Fold.fold(list[i].fullName) === q) return list[i].id
        return list[0].id
    }

    function movePicker(delta) {
        var n = filteredRepos.length
        if (n === 0) return
        var i = pickerIndex < 0 ? (delta > 0 ? 0 : n - 1) : ((pickerIndex + delta) % n + n) % n
        _highlightId = filteredRepos[i].id
    }

    function acceptPicker() {
        var typed = repoField.text.trim()
        if (pickerIndex >= 0) repoChosen(filteredRepos[pickerIndex].fullName)
        else if (typed !== "" && filteredRepos.length === 0) repoTyped(typed)
    }

    // A typed lookup applies only while the field still holds what was typed.
    function lookupDone(typed, fullName, repoId) {
        if (repoField.text.trim() === typed) lookupAccepted(fullName, repoId)
    }

    // Chord vocabulary: MOD+MOD+KEY, modifiers SUPER/SHIFT/CTRL/ALT/META,
    // key one A-Z letter or a named key. No free text ever leaves the field.
    readonly property var _modBits: ({"SHIFT": 1, "CTRL": 4, "ALT": 8, "META": 128, "SUPER": 64})
    readonly property var _keyNames: ["TAB","ESC","ESCAPE","RETURN","ENTER","SPACE","BACKSPACE","DELETE","HOME","END","PAGEUP","PAGEDOWN","UP","DOWN","LEFT","RIGHT"]

    function parseChord(text) {
        if (text === "") return {state: "typing"}
        var parts = text.split("+").map(function(part) { return part.trim() })
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
            spacing: root.tokens.spacing.panelGap

            // gh status ----------------------------------------------------
            Column {
                width: parent.width
                spacing: root.tokens.spacing.labelGap
                Text {
                    textFormat: Text.PlainText
                    color: root.theme.menu.text
                    font.family: root.tokens.font.menuFamily
                    font.pixelSize: root.tokens.font.heading
                    font.bold: true
                    text: "GitHub"
                }
                Text {
                    textFormat: Text.PlainText
                    color: root.theme.muted
                    font.family: root.tokens.font.menuFamily
                    font.pixelSize: root.tokens.font.body
                    visible: root.syncStatus && root.syncStatus.authenticated === true
                    text: root.syncStatus && root.syncStatus.authenticated === true
                        ? (root.syncStatus.login + " — " + (root.syncStatus.scopes || []).join(", "))
                        : ""
                }
                Text {
                    textFormat: Text.PlainText
                    color: root.theme.urgent
                    font.family: root.tokens.font.menuFamily
                    font.pixelSize: root.tokens.font.body
                    visible: root.syncStatus && root.syncStatus.authenticated !== true
                    text: root.syncStatus && root.syncStatus.authenticated !== true
                        ? "not authenticated — " + (root.syncStatus.fix || "gh auth login")
                        : ""
                }
            }

            // Repository ---------------------------------------------------
            Column {
                width: parent.width
                spacing: root.tokens.spacing.labelGap
                Text {
                    textFormat: Text.PlainText
                    color: root.theme.menu.text
                    font.family: root.tokens.font.menuFamily
                    font.pixelSize: root.tokens.font.heading
                    font.bold: true
                    text: "Repository"
                }
                Text {
                    visible: root.libraryMismatch !== ""
                    textFormat: Text.PlainText
                    color: root.theme.urgent
                    font.family: root.tokens.font.menuFamily
                    font.pixelSize: root.tokens.font.body
                    wrapMode: Text.Wrap
                    width: parent.width
                    text: root.libraryMismatch
                }
                TextButton {
                    objectName: "confirmReimportButton"
                    visible: root.libraryMismatch !== "" && root.libraryMismatch.indexOf("reconfirm") !== -1
                    theme: root.theme
                    tokens: root.tokens
                    label: "Confirm reimport"
                    onClicked: root.confirmReimport()
                }
                TextArea {
                    id: repoField
                    objectName: "repoField"
                    width: parent.width
                    focus: true
                    onVisibleChanged: if (visible) forceActiveFocus()
                    Component.onCompleted: forceActiveFocus()
                    wrapMode: TextEdit.NoWrap
                    color: root.theme.menu.text
                    selectionColor: root.theme.menu.selectedBackground
                    selectedTextColor: root.theme.menu.selectedText
                    font.family: root.tokens.font.menuFamily
                    font.pixelSize: root.tokens.font.title
                    topPadding: root.tokens.spacing.inputPaddingY
                    bottomPadding: root.tokens.spacing.inputPaddingY
                    leftPadding: root.tokens.spacing.controlPaddingX
                    rightPadding: root.tokens.spacing.controlPaddingX
                    textFormat: TextEdit.PlainText
                    placeholderText: "Filter repositories or type owner/repo"
                    placeholderTextColor: root.theme.muted
                    background: Rectangle {
                        color: "transparent"
                        border.color: repoField.activeFocus ? root.theme.menu.selectedBorder : root.theme.menu.border
                        border.width: 1
                        radius: root.tokens.cornerRadius
                    }
                    onTextChanged: root._highlightId = root._highlightFor(text)
                    Keys.priority: Keys.BeforeItem
                    Keys.onPressed: function(event) {
                        var plain = event.modifiers === Qt.NoModifier || event.modifiers === Qt.KeypadModifier
                        if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && plain) {
                            root.acceptPicker()
                            event.accepted = true
                        } else if (event.key === Qt.Key_Down && plain) {
                            root.movePicker(1)
                            event.accepted = true
                        } else if (event.key === Qt.Key_Up && plain) {
                            root.movePicker(-1)
                            event.accepted = true
                        } else if (event.key === Qt.Key_Escape && repoField.text !== "") {
                            repoField.text = ""
                            event.accepted = true
                        } else if (event.key === Qt.Key_Tab && plain) {
                            repoField.nextItemInFocusChain(true).forceActiveFocus(Qt.TabFocusReason)
                            event.accepted = true
                        } else if (event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && event.modifiers === Qt.ShiftModifier)) {
                            repoField.nextItemInFocusChain(false).forceActiveFocus(Qt.BacktabFocusReason)
                            event.accepted = true
                        } else {
                            root.fieldKeys(event, repoField)
                        }
                    }
                }
                Text {
                    objectName: "repoStateLine"
                    visible: text !== ""
                    textFormat: Text.PlainText
                    color: root.reposState === "failed" ? root.theme.urgent : root.theme.muted
                    font.family: root.tokens.font.menuFamily
                    font.pixelSize: root.tokens.font.body
                    text: root.reposState === "loading" ? "Loading repositories…"
                        : root.reposState === "failed" ? "Could not list repositories"
                        : repoField.text.trim() !== "" && root.filteredRepos.length === 0
                            ? "No match. Enter looks up owner/repo" : ""
                }
                ListView {
                    id: repoList
                    objectName: "repoList"
                    width: parent.width
                    height: Math.min(count, 8) * root._rowHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    activeFocusOnTab: false
                    model: root.filteredRepos
                    currentIndex: root.pickerIndex
                    highlightFollowsCurrentItem: false
                    onCurrentIndexChanged: if (currentIndex >= 0) positionViewAtIndex(currentIndex, ListView.Contain)
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        objectName: "repoRow" + index
                        width: repoList.width
                        height: root._rowHeight
                        radius: root.tokens.cornerRadius
                        color: index === root.pickerIndex ? root.theme.menu.selectedBackground : "transparent"
                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: root.tokens.spacing.rowPaddingX
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: root.tokens.spacing.controlGap
                            Text {
                                textFormat: Text.PlainText
                                color: index === root.pickerIndex ? root.theme.menu.selectedText : root.theme.menu.text
                                font.family: root.tokens.font.menuFamily
                                font.pixelSize: root.tokens.font.title
                                text: modelData.fullName
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: modelData.private === true
                                textFormat: Text.PlainText
                                color: root.theme.muted
                                font.family: root.tokens.font.menuFamily
                                font.pixelSize: root.tokens.font.body
                                text: "private"
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                textFormat: Text.PlainText
                                color: root.theme.accent
                                font.family: root.tokens.font.menuFamily
                                font.pixelSize: root.tokens.font.body
                                text: root.selection !== null && root.selection.repo === modelData.fullName ? "current" : ""
                            }
                        }
                        MouseArea { anchors.fill: parent; onClicked: root.repoChosen(modelData.fullName) }
                    }
                }
                TextButton {
                    objectName: "syncNowButton"
                    theme: root.theme
                    tokens: root.tokens
                    label: "Sync now"
                    onClicked: root.syncNow()
                }
                Text {
                    visible: root.lastPull !== ""
                    textFormat: Text.PlainText
                    color: root.theme.muted
                    font.family: root.tokens.font.menuFamily
                    font.pixelSize: root.tokens.font.body
                    text: "last pull " + root.lastPull
                }
                Text {
                    visible: root.lastError !== ""
                    textFormat: Text.PlainText
                    color: root.theme.urgent
                    font.family: root.tokens.font.menuFamily
                    font.pixelSize: root.tokens.font.body
                    wrapMode: Text.Wrap
                    width: parent.width
                    text: root.lastError
                }
            }

            // Load errors ---------------------------------------------------
            Column {
                width: parent.width
                spacing: root.tokens.spacing.xxs
                visible: root.loadErrors.length > 0
                Text {
                    textFormat: Text.PlainText
                    color: root.theme.urgent
                    font.family: root.tokens.font.menuFamily
                    font.pixelSize: root.tokens.font.heading
                    font.bold: true
                    text: "Load errors"
                }
                Repeater {
                    model: root.loadErrors
                    delegate: Text {
                        width: col.width
                        wrapMode: Text.Wrap
                        textFormat: Text.PlainText
                        color: root.theme.urgent
                        font.family: root.tokens.font.menuFamily
                        font.pixelSize: root.tokens.font.body
                        text: modelData.path + (modelData.line !== null && modelData.line !== undefined ? ":" + modelData.line : "")
                            + " — " + modelData.message
                    }
                }
            }

            // Hotkey --------------------------------------------------------
            Column {
                width: parent.width
                spacing: root.tokens.spacing.labelGap
                Text {
                    textFormat: Text.PlainText
                    color: root.theme.menu.text
                    font.family: root.tokens.font.menuFamily
                    font.pixelSize: root.tokens.font.heading
                    font.bold: true
                    text: "Hotkey"
                }
                TextField {
                    id: chordField
                    objectName: "chordField"
                    width: parent.width
                    color: root.theme.menu.text
                    selectionColor: root.theme.menu.selectedBackground
                    selectedTextColor: root.theme.menu.selectedText
                    font.family: root.tokens.font.menuFamily
                    font.pixelSize: root.tokens.font.title
                    topPadding: root.tokens.spacing.inputPaddingY
                    bottomPadding: root.tokens.spacing.inputPaddingY
                    leftPadding: root.tokens.spacing.controlPaddingX
                    rightPadding: root.tokens.spacing.controlPaddingX
                    validator: RegularExpressionValidator {
                        regularExpression: new RegExp("\\s*(?:(?:" + Object.keys(root._modBits).join("|")
                            + ")\\s*\\+\\s*)+(?:[A-Z0-9]|" + root._keyNames.join("|") + ")\\s*")
                    }
                    placeholderText: "SUPER + ALT + P"
                    placeholderTextColor: root.theme.muted
                    onTextChanged: root.updateChord(text)
                    background: Rectangle {
                        color: "transparent"
                        border.color: chordField.activeFocus ? root.theme.menu.selectedBorder : root.theme.menu.border
                        border.width: 1
                        radius: root.tokens.cornerRadius
                    }
                    Keys.priority: Keys.BeforeItem
                    Keys.onPressed: function(event) { root.fieldKeys(event, chordField) }
                }
                Text {
                    visible: root.chordState === "conflict"
                    textFormat: Text.PlainText
                    color: root.theme.urgent
                    font.family: root.tokens.font.menuFamily
                    font.pixelSize: root.tokens.font.body
                    text: root.conflictText
                }
                Text {
                    visible: root.chordState === "ready"
                    textFormat: Text.PlainText
                    color: root.theme.muted
                    font.family: root.tokens.font.menuFamily
                    font.pixelSize: root.tokens.font.body
                    text: "ready — paste into ~/.config/hypr/bindings.lua:"
                }
                Row {
                    visible: root.chordState === "ready"
                    spacing: root.tokens.spacing.controlGap
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        textFormat: Text.PlainText
                        color: root.theme.accent
                        font.family: root.tokens.font.menuFamily
                        font.pixelSize: root.tokens.font.body
                        text: root.bindLine
                    }
                    TextButton {
                        objectName: "copyBindButton"
                        theme: root.theme
                        tokens: root.tokens
                        label: "Copy"
                        onClicked: if (root.copyText) root.copyText(root.bindLine)
                    }
                }
            }

            // Usage ---------------------------------------------------------
            TextButton {
                objectName: "resetUsageButton"
                theme: root.theme
                tokens: root.tokens
                label: "Reset usage for this repository"
                onClicked: root.resetUsage()
            }
        }
    }
}
