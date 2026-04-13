import QtQuick
import QtQuick.Controls

Button {
    id: root

    property color bgColor: theme.surfaceRaised
    property color hoverColor: theme.surfaceStrong
    property color accentColor: theme.primaryContainer
    property color borderColor: theme.border

    focusPolicy: Qt.StrongFocus

    Theme {
        id: theme
    }

    background: Rectangle {
        radius: theme.radius
        color: root.down ? root.accentColor : (root.hovered ? root.hoverColor : root.bgColor)
        border.color: root.activeFocus ? theme.primaryStrong : root.borderColor
        border.width: 1
    }

    contentItem: Text {
        text: root.text
        color: theme.text
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.Wrap
        lineHeight: 0.92
        lineHeightMode: Text.ProportionalHeight
        font.family: "GoMono Nerd Font Mono"
        font.bold: true
        font.pixelSize: 17
    }

}
