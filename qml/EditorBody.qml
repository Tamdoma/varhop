import QtQuick
import QtQuick.Controls
import "../lib/tokens.mjs" as Tokens
import "../lib/rebuild.mjs" as Rebuild
import "FieldKeys.js" as FieldKeys

// Editor view: one PlainText text box shows the whole prompt with values
// inline. A deferred guard compares every change with the rendered text and
// keeps it only when it falls inside the active value occurrence; anything
// else is reverted, so prose never changes. Mirrors re-render from _values.
// Tab/Shift+Tab walk unique names with wrap. Delete empties a value, Delete
// on empty unsets it; per-name undo/redo replace the native text undo.
Item {
    id: root

    property var prompt: null           // {id,title,body,names}
    property var draft: null            // {promptId, values, activeName, cursor, anchor, histories, redos}
    property var copier: null           // {copy(text), failed(string), lastError}
    property QtObject theme
    property QtObject tokens
    property string activeName: ""
    property int valuesVersion: 0       // bumped so bindings re-read _values
    property string lastError: ""
    property var ranges: []             // [{name, start, end}] per occurrence in display order

    signal copyRequested
    signal hideRequested
    signal findAnother
    signal pullRequested

    property var _segments: []
    property var _names: []
    property var _values: ({})          // name -> string; absent = unset
    property var _hist: ({})            // name -> [{had, got}], undefined = unset
    property var _redos: ({})
    property int _activeOcc: -1         // index into ranges of the edited occurrence
    property string _shown: ""          // the text the guard accepts as current
    property bool _applying: false      // programmatic writes skip the guard
    property int _lastCursor: 0
    property int _lastAnchor: 0

    function valueOf(name) { return _values[name] }

    function _render() {
        var text = ""
        var out = []
        for (var i = 0; i < _segments.length; i++) {
            var s = _segments[i]
            if (s.kind === "text") { text += s.text; continue }
            var v = _values[s.name]
            var shown = v === undefined ? s.raw : v
            out.push({name: s.name, start: text.length, end: text.length + shown.length})
            text += shown
        }
        _shown = text
        ranges = out
        _applying = true
        if (editorText.text !== text) editorText.text = text
        _applying = false
        valuesVersion++
    }

    function _setCursor(anchor, cursor) {
        _applying = true
        editorText.cursorPosition = anchor
        if (anchor !== cursor) editorText.moveCursorSelection(cursor, TextEdit.SelectCharacters)
        _applying = false
        _lastAnchor = anchor
        _lastCursor = cursor
    }

    // Unset values are selected whole; filled ones get the cursor at the end.
    function _placeOnActive() {
        var r = ranges[_activeOcc]
        if (!r) return
        if (_values[r.name] === undefined) _setCursor(r.start, r.end)
        else _setCursor(r.end, r.end)
    }

    function _firstOcc(name) {
        for (var i = 0; i < ranges.length; i++)
            if (ranges[i].name === name) return i
        return -1
    }

    function _occAt(pos) {
        for (var i = 0; i < ranges.length; i++)
            if (ranges[i].start <= pos && pos <= ranges[i].end) return i
        return -1
    }

    function _anchorOf() {
        return editorText.cursorPosition === editorText.selectionStart
            ? editorText.selectionEnd : editorText.selectionStart
    }

    function _schedule() { if (!_applying) Qt.callLater(root._sync) }

    function _sync() {
        var f = editorText
        if (f.text !== _shown) { _acceptOrRevert(); return }
        var i = _occAt(f.cursorPosition)
        if (i >= 0) {
            _activeOcc = i
            activeName = ranges[i].name
            var r = ranges[i]
            if (_values[r.name] === undefined && f.selectedText === "") { _setCursor(r.start, r.end); return }
        }
        _lastCursor = f.cursorPosition
        _lastAnchor = _anchorOf()
    }

    function _acceptOrRevert() {
        var f = editorText
        var now = f.text
        var old = _shown
        var r = ranges[_activeOcc]
        var tail = old.length - (r ? r.end : 0)
        var ok = r && now.slice(0, r.start) === old.slice(0, r.start)
            && now.length - tail >= r.start
            && now.slice(now.length - tail) === old.slice(r.end)
        if (!ok) {
            _render()
            _setCursor(_lastAnchor, _lastCursor)
            return
        }
        var value = now.slice(r.start, now.length - tail)
        var offset = Math.max(0, Math.min(value.length, f.cursorPosition - r.start))
        _record(r.name, value)
        var nr = ranges[_activeOcc]
        _setCursor(nr.start + offset, nr.start + offset)
    }

    // One undoable value change: history first, then the render.
    function _record(name, value) {
        var had = _values[name]
        if (had === value) { _render(); return }
        _hist[name].push({had: had, got: value})
        _redos[name] = []
        _apply(name, value)
    }

    function _apply(name, value) {
        if (value === undefined) delete _values[name]
        else _values[name] = value
        _render()
    }

    function setValue(name, text) { _apply(name, text) }
    function unsetValue(name) { _apply(name, undefined) }

    function undo() {
        var h = _hist[activeName]
        if (!h || h.length === 0) return
        var a = h.pop()
        _redos[activeName].push(a)
        _apply(activeName, a.had)
        _placeOnActive()
    }

    function redo() {
        var rs = _redos[activeName]
        if (!rs || rs.length === 0) return
        var a = rs.pop()
        _hist[activeName].push(a)
        _apply(activeName, a.got)
        _placeOnActive()
    }

    function deleteKey() {
        var v = _values[activeName]
        if (v === undefined) return
        _record(activeName, v === "" ? undefined : "")
        _placeOnActive()
    }

    // Cut only inside the active value: a rejected cut must not touch the clipboard.
    function cut() {
        var r = ranges[_activeOcc]
        var f = editorText
        if (r && f.selectedText !== "" && f.selectionStart >= r.start && f.selectionEnd <= r.end
                && _values[r.name] !== undefined)
            f.cut()
    }

    function openPrompt() {
        var body = prompt ? String(prompt.body || "") : ""
        _segments = Tokens.splitSegments(body)
        _names = Tokens.uniqueNames(body)
        // A draft belongs to one prompt id; any other prompt starts clean.
        var d = (draft && prompt && draft.promptId === prompt.id) ? draft : null
        var v = ({})
        var hist = ({})
        var redos = ({})
        for (var i = 0; i < _names.length; i++) {
            var n = _names[i]
            if (d && d.values && d.values[n] !== undefined) v[n] = d.values[n]
            hist[n] = d && d.histories && d.histories[n] ? d.histories[n] : []
            redos[n] = d && d.redos && d.redos[n] ? d.redos[n] : []
        }
        _values = v
        _hist = hist
        _redos = redos
        lastError = ""
        _render()
        if (_names.length === 0) {
            Qt.callLater(function() { root.requestCopy() })
            return
        }
        activeName = d && _names.indexOf(d.activeName) >= 0 ? d.activeName : _names[0]
        _activeOcc = _firstOcc(activeName)
        editorText.forceActiveFocus()
        if (d && d.cursor !== undefined) {
            var len = editorText.text.length
            _setCursor(Math.min(d.anchor !== undefined ? d.anchor : d.cursor, len), Math.min(d.cursor, len))
            var at = _occAt(d.cursor)
            if (at >= 0 && ranges[at].name === activeName) _activeOcc = at
        } else {
            _placeOnActive()
        }
    }

    function rebuiltText() {
        return Rebuild.rebuild(_segments, _values)
    }

    function captureDraft() {
        return {
            promptId: prompt ? prompt.id : "",
            values: JSON.parse(JSON.stringify(_values)),
            activeName: activeName,
            cursor: editorText.cursorPosition,
            anchor: _anchorOf(),
            histories: JSON.parse(JSON.stringify(_hist)),
            redos: JSON.parse(JSON.stringify(_redos))
        }
    }

    function stepName(delta) {
        if (_names.length === 0) return
        var i = _names.indexOf(activeName)
        i = ((i + delta) % _names.length + _names.length) % _names.length
        activeName = _names[i]
        _activeOcc = _firstOcc(activeName)
        editorText.forceActiveFocus()
        _placeOnActive()
    }

    function requestCopy() {
        Qt.inputMethod.commit()
        var r = copier ? copier.copy(rebuiltText().text) : false
        if (r === false)
            lastError = (copier && copier.lastError) ? copier.lastError : "copy failed"
        copyRequested()
    }

    function handleKey(event) {
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

    Keys.onPressed: function(event) { root.handleKey(event) }

    onCopierChanged: {
        if (copier && copier.failed)
            copier.failed.connect(function(reason) { root.lastError = reason })
    }

    ScrollView {
        anchors.fill: parent
        anchors.bottomMargin: status.height + root.tokens.spacing.rowGap

        TextArea {
            id: editorText
            objectName: "editorText"
            textFormat: TextEdit.PlainText
            wrapMode: TextEdit.Wrap
            persistentSelection: true
            selectByMouse: true
            background: null
            color: root.theme.menu.text
            selectionColor: root.theme.menu.selectedBackground
            selectedTextColor: root.theme.menu.selectedText
            font.family: root.tokens.font.menuFamily
            font.pixelSize: root.tokens.font.heading

            onTextChanged: root._schedule()
            onCursorPositionChanged: root._schedule()

            // The native menu carries Undo/Redo; this one keeps the guarded paths.
            ContextMenu.menu: Menu {
                MenuItem { action: Action { text: "Cut"; onTriggered: root.cut() } }
                MenuItem { action: Action { text: "Copy"; onTriggered: editorText.copy() } }
                MenuItem { action: Action { text: "Paste"; onTriggered: editorText.paste() } }
            }

            Repeater {
                model: root.ranges
                delegate: Rectangle {
                    objectName: "valueHighlight"
                    required property var modelData
                    readonly property string name: modelData.name
                    readonly property string kind: {
                        root.valuesVersion
                        var v = root._values[name]
                        return name === root.activeName ? "active"
                            : v === undefined ? "unset" : v === "" ? "empty" : "filled"
                    }
                    readonly property rect a: {
                        editorText.contentWidth; editorText.contentHeight
                        return editorText.positionToRectangle(modelData.start)
                    }
                    readonly property rect b: {
                        editorText.contentWidth; editorText.contentHeight
                        return editorText.positionToRectangle(modelData.end)
                    }
                    z: -1
                    x: a.x + 1
                    y: a.y
                    width: Math.max(2, (b.y === a.y ? b.x : editorText.width) - a.x - 2)
                    height: a.height
                    radius: 2
                    color: kind === "active" || kind === "filled" ? root.theme.menu.selectedBackground : "transparent"
                    opacity: kind === "filled" ? 0.45 : 1
                    border.width: kind === "unset" || kind === "empty" ? 1 : 0
                    border.color: root.theme.muted
                }
            }

            Keys.priority: Keys.BeforeItem
            Keys.onPressed: function(event) {
                var mods = event.modifiers
                var ctrl = mods === Qt.ControlModifier
                var ctrlShift = mods === (Qt.ControlModifier | Qt.ShiftModifier)
                if (event.key === Qt.Key_Tab && (mods === Qt.NoModifier || mods === Qt.KeypadModifier)) {
                    root.stepName(1); event.accepted = true
                } else if (event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && mods === Qt.ShiftModifier)) {
                    root.stepName(-1); event.accepted = true
                } else if (event.key === Qt.Key_Delete && mods === Qt.NoModifier && selectedText === "") {
                    root.deleteKey(); event.accepted = true
                } else if ((event.key === Qt.Key_Backspace || event.key === Qt.Key_Delete)
                           && root._values[root.activeName] === undefined) {
                    event.accepted = true   // an unset value stays unset
                } else if (ctrl && event.key === Qt.Key_Z) {
                    root.undo(); event.accepted = true
                } else if ((ctrl && event.key === Qt.Key_Y) || (ctrlShift && event.key === Qt.Key_Z)) {
                    root.redo(); event.accepted = true
                } else if ((ctrl || ctrlShift) && event.key === Qt.Key_X) {
                    root.cut(); event.accepted = true
                } else {
                    FieldKeys.handle(event, editorText, {copySelection: false, inertCtrlR: false})
                    if (!event.accepted) root.handleKey(event)
                }
            }
        }
    }

    Item {
        id: status
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: Math.max(errorText.implicitHeight, unsetText.implicitHeight)

        Text {
            id: errorText
            anchors.left: parent.left
            visible: root.lastError !== ""
            textFormat: Text.PlainText
            text: root.lastError
            color: root.theme.urgent
            font.family: root.tokens.font.menuFamily
            font.pixelSize: root.tokens.font.body
        }

        Text {
            id: unsetText
            anchors.right: parent.right
            textFormat: Text.PlainText
            text: {
                root.valuesVersion
                var count = root.rebuiltText().unset.length
                return count + (count === 1 ? " unset variable" : " unset variables")
            }
            color: root.theme.muted
            font.family: root.tokens.font.menuFamily
            font.pixelSize: root.tokens.font.body
        }
    }
}
