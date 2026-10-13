import QtQuick

// Plain button: a label plus an optional muted shortcut hint. It is a Tab
// stop; Enter, Return and Space press it like a click.
Rectangle {
    id: button

    property QtObject theme
    property QtObject tokens
    property string label: ""
    property string shortcut: ""

    signal clicked

    activeFocusOnTab: true
    implicitWidth: row.implicitWidth + 2 * tokens.spacing.controlPaddingX
    implicitHeight: row.implicitHeight + 2 * tokens.spacing.controlPaddingY
    radius: tokens.cornerRadius
    color: activeFocus ? theme.menu.selectedBackground : "transparent"
    border.width: 1
    border.color: activeFocus ? theme.menu.selectedBorder : theme.menu.border

    Keys.onPressed: function(event) {
        if (event.modifiers === Qt.NoModifier && (event.key === Qt.Key_Return
                || event.key === Qt.Key_Enter || event.key === Qt.Key_Space)) {
            button.clicked()
            event.accepted = true
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: button.tokens.spacing.controlGap

        Text {
            anchors.verticalCenter: parent.verticalCenter
            textFormat: Text.PlainText
            text: button.label
            color: button.activeFocus ? button.theme.menu.selectedText : button.theme.menu.text
            font.family: button.tokens.font.menuFamily
            font.pixelSize: button.tokens.font.title
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: button.shortcut !== ""
            textFormat: Text.PlainText
            text: button.shortcut
            color: button.theme.muted
            font.family: button.tokens.font.menuFamily
            font.pixelSize: button.tokens.font.body
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: button.clicked()
    }
}
