import QtQuick
import QtQuick.Controls
import "FieldKeys.js" as FieldKeys

// Search view: query field, result rows and the pinned "Resume draft" row.
// Plain QtQuick only; the root injects rows, draft state, theme and tokens, and owns
// hide/open actions through the emitted signals.
Item {
    id: root

    property var rows: []
    property string draftPromptId: ""
    property string query: ""
    property QtObject theme
    property QtObject tokens
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
        spacing: root.tokens.spacing.rowGap

        TextArea {
            id: queryField
            objectName: "queryField"
            width: parent.width
            text: root.query
            focus: true
            onVisibleChanged: if (visible) forceActiveFocus()
            Component.onCompleted: forceActiveFocus()
            wrapMode: TextEdit.NoWrap
            color: root.theme.menu.text
            selectionColor: root.theme.menu.selectedBackground
            selectedTextColor: root.theme.menu.selectedText
            font.family: root.tokens.font.menuFamily
            font.pixelSize: root.tokens.font.heading
            topPadding: root.tokens.spacing.inputPaddingY
            bottomPadding: root.tokens.spacing.inputPaddingY
            leftPadding: root.tokens.spacing.controlPaddingX
            rightPadding: root.tokens.spacing.controlPaddingX
            textFormat: TextEdit.PlainText
            placeholderText: "Search prompts"
            placeholderTextColor: root.theme.muted
            background: Rectangle {
                color: "transparent"
                border.color: queryField.activeFocus ? root.theme.menu.selectedBorder : root.theme.menu.border
                border.width: 1
                radius: root.tokens.cornerRadius
            }
            Keys.priority: Keys.BeforeItem
            Keys.onPressed: function(event) {
                root.keyTime = Date.now()
                // The result list is part of this one control; Tab leaves it.
                if (event.key === Qt.Key_Tab && event.modifiers === Qt.NoModifier) {
                    queryField.nextItemInFocusChain(true).forceActiveFocus(Qt.TabFocusReason)
                    event.accepted = true
                    return
                }
                if (event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && event.modifiers === Qt.ShiftModifier)) {
                    queryField.nextItemInFocusChain(false).forceActiveFocus(Qt.BacktabFocusReason)
                    event.accepted = true
                    return
                }
                FieldKeys.handle(event, queryField, {copySelection: true, inertCtrlR: false})
                if (!event.accepted) root.handleKey(event)
            }
            // The public query mirrors the field so root-side rebuilds
            // (import, config reload, usage) start from the actual typed
            // text, not a stale default.
            onTextChanged: { root.query = text; root.queryEdited(text) }
        }

        // Pinned resume-draft row.
        Rectangle {
            id: resumeRow
            objectName: "resumeDraftRow"
            visible: root.draftPromptId !== ""
            width: parent.width
            height: visible ? resumeText.implicitHeight + 2 * root.tokens.spacing.controlPaddingY : 0
            radius: root.tokens.cornerRadius
            color: "transparent"
            border.width: 1
            border.color: root.theme.menu.border
            Text {
                id: resumeText
                anchors.left: parent.left
                anchors.leftMargin: root.tokens.spacing.rowPaddingX
                anchors.verticalCenter: parent.verticalCenter
                textFormat: Text.PlainText
                color: root.theme.accent
                font.family: root.tokens.font.menuFamily
                font.pixelSize: root.tokens.font.title
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
            height: parent.height - queryField.height - parent.spacing
                - (root.draftPromptId !== "" ? resumeRow.height + parent.spacing : 0)
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: root.rows
            cacheBuffer: 2 * rowHeight   // one extra row each direction
            reuseItems: true
            spacing: root.tokens.spacing.xxs
            // Title line plus detail line, derived from the font tokens.
            readonly property int rowHeight: Math.ceil((root.tokens.font.title + root.tokens.font.body) * 1.4)
                + 2 * root.tokens.spacing.xs
            readonly property int snippetHeight: Math.ceil(root.tokens.font.body * 1.4)

            Connections {
                target: root
                function onSelectedIndexChanged() {
                    if (root.selectedIndex >= 0) resultsList.positionViewAtIndex(root.selectedIndex, ListView.Contain)
                }
            }

            delegate: Rectangle {
                required property var modelData
                required property int index
                objectName: "resultRow" + index
                width: resultsList.width - root.tokens.spacing.xxl
                height: resultsList.rowHeight + (modelData.snippet ? resultsList.snippetHeight : 0)
                radius: root.tokens.cornerRadius
                color: index === root.selectedIndex ? root.theme.menu.selectedBackground : "transparent"
                Column {
                    anchors.fill: parent
                    anchors.leftMargin: root.tokens.spacing.rowPaddingX
                    anchors.rightMargin: root.tokens.spacing.rowPaddingX
                    anchors.topMargin: root.tokens.spacing.xs
                    spacing: 0
                    Row {
                        spacing: root.tokens.spacing.controlGap
                        Text {
                            textFormat: Text.PlainText
                            text: modelData.title
                            color: index === root.selectedIndex ? root.theme.menu.selectedText : root.theme.menu.text
                            font.family: root.tokens.font.menuFamily
                            font.pixelSize: root.tokens.font.title
                            font.bold: index === root.selectedIndex
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: modelData.draft === true
                            textFormat: Text.PlainText
                            text: "Draft"
                            color: root.theme.accent
                            font.family: root.tokens.font.menuFamily
                            font.pixelSize: root.tokens.font.body
                        }
                    }
                    Row {
                        spacing: root.tokens.spacing.controlGap
                        Text {
                            textFormat: Text.PlainText
                            text: modelData.detail
                            color: root.theme.muted
                            font.family: root.tokens.font.menuFamily
                            font.pixelSize: root.tokens.font.body
                            elide: Text.ElideRight
                            width: Math.min(implicitWidth, resultsList.width * 0.7)
                        }
                        Text {
                            visible: modelData.fileName !== "" && modelData.fileName !== null
                            textFormat: Text.PlainText
                            text: modelData.fileName
                            color: root.theme.muted
                            font.family: root.tokens.font.menuFamily
                            font.pixelSize: root.tokens.font.body
                        }
                    }
                    Text {
                        visible: modelData.snippet !== "" && modelData.snippet !== null
                        textFormat: Text.PlainText
                        text: modelData.snippet
                        color: root.theme.muted
                        font.family: root.tokens.font.menuFamily
                        font.pixelSize: root.tokens.font.body
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
                color: root.theme.muted
                font.family: root.tokens.font.menuFamily
                font.pixelSize: root.tokens.font.body
            }
        }
    }
}
