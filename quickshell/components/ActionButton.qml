import QtQuick
import QtQuick.Controls

Button {
    id: root

    property color bgColor: theme.surfaceRaised
    property color hoverColor: theme.surfaceStrong
    property color accentColor: theme.primaryContainer
    property color borderColor: theme.border

    required property string glyph

    focusPolicy: Qt.StrongFocus

    Theme {
        id: theme
    }

    background: Rectangle {
        radius: theme.radius
        color: root.down || root.activeFocus ? root.accentColor : (root.hovered ? root.hoverColor : root.bgColor)
        border.color: root.activeFocus ? theme.primaryStrong : root.borderColor
        border.width: 1
    }

    contentItem: Column {
        spacing: 5
        topPadding: Math.max(0, (height - symbol.implicitHeight - label.implicitHeight - spacing) / 2)

        Text {
            id: symbol
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.glyph
            font.family: "GoMono Nerd Font Mono"
            font.pixelSize: 21
            color: theme.primary
        }

        Text {
            id: label
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.text
            font.family: theme.fontFamily
            font.weight: Font.DemiBold
            font.pixelSize: 14
            color: theme.text
        }
    }
}
