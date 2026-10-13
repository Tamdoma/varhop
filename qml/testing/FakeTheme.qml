import QtQuick

// Stand-in for Omarchy's Commons.Color singleton in component checks. The
// foundational foreground and the menu text role differ on purpose, so a view
// that reads the wrong role shows the wrong color.
QtObject {
    property color foreground: "#ff0000"
    property color background: "#000000"
    property color muted: "#808080"
    property color accent: "#4080ff"
    property color urgent: "#ff4040"
    property QtObject menu: QtObject {
        property color background: "#101820"
        property color text: "#00ff00"
        property color border: "#405060"
        property color scrim: "#80000000"
        property color selectedBackground: "#203040"
        property color selectedText: "#ffd080"
        property color selectedBorder: "#00000000"
    }
}
