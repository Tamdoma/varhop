import QtQuick
import QtQuick.Controls
import "FieldKeys.js" as FieldKeys

// Search view: query field, result rows and the pinned "Resume draft" row.
// Plain QtQuick only; the root injects rows, draft state and colors, and owns
// hide/open actions through the emitted signals.
Item {
    id: root

    property var rows: []
    property string draftPromptId: ""
    property string query: ""
    property var colors: ({})
    property int selectedIndex: 0
    property real keyTime: 0          // epoch ms of the last keypress affecting the list
    property bool retainSelection: false // rows changed without a query edit
    property string restoreId: ""       // one-shot id to select on next rows change
    property string _lastSelectedId: ""

    signal queryEdited(string q)
    signal queryCleared
    signal hideRequested
    signal accepted(string id)
    signal resumeDraft
    signal pullRequested
    signal selectionChanged(string id)

    function c(name, fallback) {
        return colors && colors[name] !== undefined ? colors[name] : fallback
    }
    readonly property color _fg: c("foreground", "#cacccc")
    readonly property color _muted: c("muted", "#707880")
    readonly property color _accent: c("accent", "#cacccc")
    readonly property color _selBg: c("selectedBackground", "#22282c")
    readonly property color _selFg: c("selectedText", "#ffffff")

    onRowsChanged: resolveSelection()

    function resolveSelection() {
        // Query edits reset to the top row; refreshes that keep the query
        // (Ctrl+R, usage writes) retain the selection by id.
        var want = restoreId !== "" ? restoreId
            : (retainSelection ? _lastSelectedId : "")
        restoreId = ""
        selectedIndex = 0
        if (want !== "")
            for (var i = 0; i < rows.length; i++)
                if (rows[i].id === want) { selectedIndex = i; break }
    }

    onSelectedIndexChanged: {
        if (selectedIndex >= 0 && selectedIndex < rows.length) {
            _lastSelectedId = rows[selectedIndex].id
            selectionChanged(_lastSelectedId)
        }
    }

    function setQuery(q) {
        query = q
        queryField.text = Qt.binding(function() { return root.query })
    }

    function move(delta) {
        if (rows.length === 0) return
        selectedIndex = ((selectedIndex + delta) % rows.length + rows.length) % rows.length
    }

    function handleKey(event) {
        if (event.key === Qt.Key_Up) { move(-1); event.accepted = true }
        else if (event.key === Qt.Key_Down) { move(1); event.accepted = true }
        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (rows.length > 0 && selectedIndex >= 0 && selectedIndex < rows.length)
                accepted(rows[selectedIndex].id)
            event.accepted = true
        } else if (event.key === Qt.Key_Escape) {
            if (queryField.text !== "") { queryField.text = ""; queryCleared() }
            else hideRequested()
            event.accepted = true
        } else if (event.modifiers === (Qt.ControlModifier | Qt.ShiftModifier)
                   && event.key === Qt.Key_P) {
            resumeDraft()
            event.accepted = true
        } else if (event.modifiers === Qt.ControlModifier && event.key === Qt.Key_R) {
            pullRequested()
            event.accepted = true
        }
    }

    Keys.onPressed: function(event) { root.handleKey(event) }

    Column {
        anchors.fill: parent
        spacing: 8

        TextArea {
            id: queryField
            objectName: "queryField"
            width: parent.width
            height: 36
            text: root.query
            focus: true
            onVisibleChanged: if (visible) forceActiveFocus()
            Component.onCompleted: forceActiveFocus()
            wrapMode: TextEdit.NoWrap
            color: root._fg
            selectionColor: root._selBg
            selectedTextColor: root._selFg
            font.pixelSize: 16
            textFormat: TextEdit.PlainText
            placeholderText: "Search prompts"
            placeholderTextColor: root._muted
            background: Rectangle {
                color: "transparent"
                border.color: root.c("border", root._muted)
                border.width: 1
                radius: 4
            }
            Keys.priority: Keys.BeforeItem
            Keys.onPressed: function(event) {
                root.keyTime = Date.now()
                FieldKeys.handle(event, queryField, {copySelection: true, inertCtrlR: false})
                if (!event.accepted) root.handleKey(event)
            }
            onTextChanged: root.queryEdited(text)
        }

        // Pinned resume-draft row.
        Rectangle {
            objectName: "resumeDraftRow"
            visible: root.draftPromptId !== ""
            width: parent.width
            height: visible ? 36 : 0
            radius: 4
            color: root.c("border", "#2a3034")
            Text {
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                textFormat: Text.PlainText
                color: root._accent
                text: "Resume draft — Ctrl+Shift+P"
            }
            MouseArea {
                anchors.fill: parent
                onClicked: root.resumeDraft()
            }
        }

        // ListView instantiates only the rows on screen: a Repeater would
        // build one delegate per ranked prompt and blows the 50 ms key-to-
        // frame budget at multi-thousand-prompt libraries.
        ListView {
            id: resultsList
            width: parent.width
            height: parent.height - queryField.height - (root.draftPromptId !== "" ? 44 : 0) - 16
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: root.rows
            cacheBuffer: 88   // one extra row each direction
            reuseItems: true
            spacing: 4

            function ensureVisible(idx) {
                if (idx < 0) return
                var top = idx * 48
                var bot = top + 44
                if (top < contentY) contentY = top
                else if (bot > contentY + height) contentY = bot - height
            }

            Connections {
                target: root
                function onSelectedIndexChanged() { resultsList.ensureVisible(root.selectedIndex) }
            }

            delegate: Rectangle {
                required property var modelData
                required property int index
                objectName: "resultRow" + index
                width: resultsList.width - 12
                height: 44
                radius: 4
                color: index === root.selectedIndex ? root._selBg : "transparent"
                Column {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    anchors.topMargin: 4
                    spacing: 1
                    Row {
                        spacing: 8
                        Text {
                            textFormat: Text.PlainText
                            text: modelData.title
                            color: index === root.selectedIndex ? root._selFg : root._fg
                            font.pixelSize: 14
                            font.bold: index === root.selectedIndex
                        }
                        Text {
                            visible: modelData.draft === true
                            textFormat: Text.PlainText
                            text: "Draft"
                            color: root._accent
                            font.pixelSize: 11
                        }
                    }
                    Row {
                        spacing: 8
                        Text {
                            textFormat: Text.PlainText
                            text: modelData.detail
                            color: root._muted
                            font.pixelSize: 11
                            elide: Text.ElideRight
                            width: Math.min(implicitWidth, resultsList.width * 0.7)
                        }
                        Text {
                            visible: modelData.fileName !== "" && modelData.fileName !== null
                            textFormat: Text.PlainText
                            text: modelData.fileName
                            color: root._muted
                            font.pixelSize: 11
                        }
                    }
                    Text {
                        visible: modelData.snippet !== "" && modelData.snippet !== null
                        textFormat: Text.PlainText
                        text: modelData.snippet
                        color: root._muted
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        width: parent.width
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.accepted(modelData.id)
                }
            }

            Text {
                anchors.top: parent.top
                visible: root.rows.length === 0
                textFormat: Text.PlainText
                text: "No prompts"
                color: root._muted
            }
        }
    }
}
