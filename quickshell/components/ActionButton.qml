import QtQuick
import QtQuick.Controls

Button {
    id: root

    Theme {
        id: theme
    }

    property color bgColor: theme.surfaceRaised
    property color hoverColor: theme.surfaceStrong
    property color accentColor: theme.primaryContainer
    property color borderColor: theme.border

    focusPolicy: Qt.StrongFocus

    background: Rectangle {
        radius: theme.radius
        color: root.down ? root.accentColor : (root.hovered ? root.hoverColor : root.bgColor)
        border.color: root.activeFocus ? theme.primaryStrong : root.borderColor
        border.width: 1

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 1
            height: Math.max(1, parent.height * 0.16)
            radius: parent.radius
            color: Qt.rgba(1, 1, 1, 0.05)
        }
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
