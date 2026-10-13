import QtQuick

// Stand-in for Omarchy's Style singleton in component checks. Font and
// spacing tokens derive from one base size, as Style.fontPx and Style.space
// do. `family` differs from `menuFamily` on purpose, so a view that reads the
// shared family instead of the menu family shows the wrong font.
QtObject {
    id: tokens

    property int base: 12
    property int cornerRadius: 4
    property int gapsOut: 5

    function px(n) { return Math.max(1, Math.round(n * base / 12)) }
    function space(n) { return px(n) }

    property QtObject font: QtObject {
        property string family: "VarhopWrongFamily"
        property string menuFamily: "VarhopTestFamily"
        property int baseSize: tokens.base
        property int caption: tokens.px(10)
        property int bodySmall: tokens.px(11)
        property int body: tokens.px(12)
        property int subtitle: tokens.px(13)
        property int title: tokens.px(14)
        property int heading: tokens.px(16)
        property int display: tokens.px(24)
    }

    property QtObject spacing: QtObject {
        property int xxs: tokens.px(2)
        property int xs: tokens.px(3)
        property int sm: tokens.px(4)
        property int md: tokens.px(6)
        property int lg: tokens.px(8)
        property int xl: tokens.px(10)
        property int xxl: tokens.px(12)
        property int xxxl: tokens.px(14)
        property int huge: tokens.px(18)
        property int controlGap: tokens.px(8)
        property int controlPaddingX: tokens.px(10)
        property int controlPaddingY: tokens.px(6)
        property int inputPaddingY: tokens.px(7)
        property int controlHeight: tokens.px(28)
        property int popupRowHeight: tokens.px(28)
        property int rowGap: tokens.px(8)
        property int rowPaddingX: tokens.px(12)
        property int labelGap: tokens.px(4)
        property int panelGap: tokens.px(14)
        property int panelPadding: tokens.px(18)
        property int popupPadding: tokens.px(14)
    }
}
