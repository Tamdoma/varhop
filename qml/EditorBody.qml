import QtQuick
import QtQuick.Controls
import "../lib/tokens.mjs" as Tokens
import "../lib/rebuild.mjs" as Rebuild
import "FieldKeys.js" as FieldKeys

// Editor view: prose is fixed; the first {{NAME}} occurrence per unique name
// is an editable "stop" (TextArea), later occurrences are read-only mirrors.
// Tab/Shift+Tab walk unique names with wrap. Delete on a value empties it,
// Delete on empty restores unset {{NAME}}; the reset joins the per-name undo
// stack alongside the field's own edit history.
Item {
    id: root

    property var prompt: null           // {id,title,body,names}
    property var draft: null            // {values, activeName, cursor, selection}
    property var copier: null           // {copy(text), failed(string), lastError}
    property var colors: ({})
    property string activeName: ""
    property int valuesVersion: 0       // bumped so mirror bindings re-read _values
    property string lastError: ""

    signal copyRequested
    signal hideRequested
    signal findAnother
    signal pullRequested

    function c(name, fallback) {
        return colors && colors[name] !== undefined ? colors[name] : fallback
    }
    readonly property color _fg: c("foreground", "#cacccc")
    readonly property color _muted: c("muted", "#707880")
    readonly property color _accent: c("accent", "#cacccc")
    readonly property color _selBg: c("selectedBackground", "#22282c")

    property var _segments: []
    property var _names: []
    property var _nameStops: ({})       // name -> stop index in unique order
    property var _values: ({})          // name -> string
    property var _resets: []            // [{name, had}] semantic empty/reset actions
    property var _redos: []             // undone semantic actions

    function pushAction(name, kind, had) {
        // "empty" then "reset" on the same name is one semantic undo step:
        // undo restores the value, redo returns to raw {{NAME}}.
        if (kind === "reset" && _resets.length > 0
            && _resets[_resets.length - 1].name === name
            && _resets[_resets.length - 1].kind === "empty") {
            var prev = _resets.pop()
            _resets.push({name: name, kind: "reset", had: prev.had})
            _redos = []
            return
        }
        _resets.push({name: name, kind: kind, had: had})
        _redos = []
    }
    function semanticUndo(name, field) {
        for (var i = _resets.length - 1; i >= 0; i--) {
            if (_resets[i].name !== name) continue
            var a = _resets.splice(i, 1)[0]
            _redos.push(a)
            if (a.kind === "reset") {
                // reset (raw) -> empty -> value: restore the value
                field.text = a.had
                setValue(name, a.had)
            } else {
                field.text = a.had
                setValue(name, a.had)
            }
            return true
        }
        return false
    }
    function semanticRedo(name, field) {
        for (var i = _redos.length - 1; i >= 0; i--) {
            if (_redos[i].name !== name) continue
            var a = _redos.splice(i, 1)[0]
            _resets.push(a)
            if (a.kind === "reset") {
                field.text = ""
                unsetValue(name)
            } else {
                field.text = ""
                setValue(name, "")
            }
            return true
        }
        return false
    }

    function openPrompt() {
        _segments = Tokens.splitSegments(prompt ? String(prompt.body || "") : "")
        _names = Tokens.uniqueNames(prompt ? String(prompt.body || "") : "")
        var stops = {}
        var idx = 0
        for (var i = 0; i < _names.length; i++) {
            stops[_names[i]] = idx
            idx++
        }
        _nameStops = stops
        _resets = []
        _redos = []
        lastError = ""
        var v = ({})
        if (draft && draft.values)
            for (var k in draft.values) v[k] = draft.values[k]
        _values = v
        activeName = draft && draft.activeName ? draft.activeName
            : (_names.length > 0 ? _names[0] : "")
        valuesVersion++
        if (_names.length === 0) {
            Qt.callLater(function() { root.copyRequested() })
            return
        }
        Qt.callLater(function() {
            var f = fieldFor(activeName)
            if (!f) return
            if (draft && draft.values && draft.values[activeName] !== undefined)
                f.text = draft.values[activeName]
            f.forceActiveFocus()
            if (draft && draft.cursor !== undefined)
                f.cursorPosition = Math.min(draft.cursor, f.text.length)
            if (draft && draft.selection)
                f.select(draft.selection[0], draft.selection[1])
        })
    }

    function fieldFor(name) {
        var idx = _nameStops[name]
        if (idx === undefined) return null
        var kids = root.children
        for (var i = 0; i < kids.length; i++) {
            var want = "value" + idx
            var found = findChild(kids[i], want)
            if (found) return found
        }
        return null
    }
    function findChild(item, name) {
        if (!item) return null
        if (item.objectName === name) return item
        var kids = item.children || []
        for (var i = 0; i < kids.length; i++) {
            var r = findChild(kids[i], name)
            if (r) return r
        }
        return null
    }

    function setValue(name, text) {
        _values[name] = text
        valuesVersion++
    }
    function unsetValue(name) {
        delete _values[name]
        valuesVersion++
    }

    function rebuiltText() {
        var segs = Tokens.splitSegments(prompt ? String(prompt.body || "") : "")
        return Rebuild.rebuild(segs, _values)
    }

    function captureDraft() {
        var f = fieldFor(activeName)
        return {
            promptId: prompt ? prompt.id : "",
            values: JSON.parse(JSON.stringify(_values)),
            activeName: activeName,
            cursor: f ? f.cursorPosition : 0,
            selection: f && f.selectedText !== "" ? [f.selectionStart, f.selectionEnd] : null
        }
    }

    function stepName(delta) {
        if (_names.length === 0) return
        var i = _names.indexOf(activeName)
        i = ((i + delta) % _names.length + _names.length) % _names.length
        activeName = _names[i]
        var f = fieldFor(activeName)
        if (f) f.forceActiveFocus()
    }

    function requestCopy() {
        Qt.inputMethod.commit()
        var r = copier ? copier.copy(rebuiltText().text) : false
        if (r === false)
            lastError = (copier && copier.lastError) ? copier.lastError : "copy failed"
        copyRequested()
    }

    function handleGlobalKeys(event) {
        var ctrl = (event.modifiers === Qt.ControlModifier)
        var ctrlShift = (event.modifiers === (Qt.ControlModifier | Qt.ShiftModifier))
        if ((ctrl || ctrlShift) && event.key === Qt.Key_C) {
            requestCopy()
            event.accepted = true
        } else if (event.key === Qt.Key_Escape) {
            hideRequested()
            event.accepted = true
        } else if (ctrl && event.key === Qt.Key_P) {
            findAnother()
            event.accepted = true
        } else if (ctrlShift && event.key === Qt.Key_P) {
            event.accepted = true   // already editing the draft
        } else if (ctrl && event.key === Qt.Key_R) {
            pullRequested()
            event.accepted = true
        }
    }

    Keys.onPressed: function(event) { root.handleGlobalKeys(event) }

    onCopierChanged: {
        if (copier && copier.failed)
            copier.failed.connect(function(reason) { root.lastError = reason })
    }

    Flickable {
        anchors.fill: parent
        anchors.bottomMargin: 24
        contentHeight: flowCol.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: flowCol
            width: root.width
            spacing: 4

            Repeater {
                model: root._segments
                delegate: Item {
                    id: segRow
                    width: flowCol.width
                    height: seg.kind === "text" ? Math.max(20, txt.implicitHeight)
                        : (isStop ? Math.max(28, field.implicitHeight) : Math.max(20, mir.implicitHeight))
                    property var seg: modelData
                    property int occurrenceIndex: {
                        var n = 0
                        for (var i = 0; i < index; i++)
                            if (root._segments[i].kind === "token" && root._segments[i].name === seg.name) n++
                        return n
                    }
                    property bool isStop: seg.kind === "token" && occurrenceIndex === 0

                    Text {
                        id: txt
                        visible: seg.kind === "text"
                        width: parent.width
                        wrapMode: Text.Wrap
                        textFormat: Text.PlainText
                        text: seg.kind === "text" ? seg.text : ""
                        color: root._fg
                        font.pixelSize: 14
                    }

                    TextArea {
                        id: field
                        visible: isStop
                        objectName: isStop ? "value" + root._nameStops[seg.name] : ""
                        width: Math.max(180, Math.min(parent.width, implicitWidth))
                        wrapMode: TextEdit.Wrap
                        text: {
                            root.valuesVersion
                            if (seg.kind !== "token") return ""
                            var v = root._values[seg.name]
                            return v !== undefined ? v : ""
                        }
                        color: root._fg
                        selectionColor: root._selBg
                        font.pixelSize: 14
                        textFormat: TextEdit.PlainText
                        placeholderText: seg.kind === "token" ? seg.raw : ""
                        placeholderTextColor: root._muted
                        background: Rectangle {
                            color: "transparent"
                            border.color: root.activeName === seg.name ? root._accent : root.c("border", root._muted)
                            border.width: 1
                            radius: 4
                        }
                        Keys.priority: Keys.BeforeItem
                        Keys.onPressed: function(event) {
                            var mods = event.modifiers
                            if (event.key === Qt.Key_Tab && (mods === Qt.NoModifier || mods === Qt.KeypadModifier)) {
                                root.stepName(1); event.accepted = true
                            } else if (event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && mods === Qt.ShiftModifier)) {
                                root.stepName(-1); event.accepted = true
                            } else if (event.key === Qt.Key_Delete && mods === Qt.NoModifier
                                       && selectedText === "") {
                                if (root._values[seg.name] === undefined) { event.accepted = false; return }
                                if (text === "") {
                                    root.pushAction(seg.name, "reset", "")
                                    root.unsetValue(seg.name)
                                } else {
                                    root.pushAction(seg.name, "empty", text)
                                    text = ""
                                    root.setValue(seg.name, "")
                                }
                                event.accepted = true
                            } else if (event.key === Qt.Key_Z && mods === Qt.ControlModifier) {
                                if (!root.semanticUndo(seg.name, field)) {
                                    undo()
                                    root.setValue(seg.name, text)
                                }
                                event.accepted = true
                            } else if (event.key === Qt.Key_Y && mods === Qt.ControlModifier) {
                                if (!root.semanticRedo(seg.name, field)) {
                                    redo()
                                    root.setValue(seg.name, text)
                                }
                                event.accepted = true
                            } else {
                                FieldKeys.handle(event, field, {copySelection: false, inertCtrlR: false})
                                if (!event.accepted) root.handleGlobalKeys(event)
                            }
                        }
                        onTextChanged: {
                            if (isStop && activeFocus && root._values[seg.name] !== text)
                                root.setValue(seg.name, text)
                        }
                        onActiveFocusChanged: if (activeFocus && seg.kind === "token") root.activeName = seg.name
                    }

                    Text {
                        id: mir
                        visible: seg.kind === "token" && !isStop
                        objectName: (seg.kind === "token" && !isStop) ? "mirror" + (occurrenceIndex - 1) : ""
                        textFormat: Text.PlainText
                        text: {
                            root.valuesVersion
                            if (seg.kind !== "token") return ""
                            var v = root._values[seg.name]
                            return (v !== undefined && v !== "") ? v : seg.raw
                        }
                        color: (root._values[seg.name] !== undefined && root._values[seg.name] !== "") ? root._fg : root._muted
                        font.pixelSize: 14
                        font.italic: !(root._values[seg.name] !== undefined && root._values[seg.name] !== "")
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                root.activeName = seg.name
                                var f = root.fieldFor(seg.name)
                                if (f) f.forceActiveFocus()
                            }
                        }
                    }
                }
            }
        }
    }

    Text {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        visible: root.lastError !== ""
        textFormat: Text.PlainText
        text: root.lastError
        color: "#d08080"
        font.pixelSize: 12
    }
}
