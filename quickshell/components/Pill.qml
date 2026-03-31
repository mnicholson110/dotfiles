import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    Theme {
        id: theme
    }

    default property alias content: contentRow.data

    property color fillColor: theme.surfaceOverlay
    property color borderColor: theme.border
    property color glowColor: theme.primary
    property real glowOpacity: 0
    property int horizontalPadding: 12
    property int verticalPadding: 7
    property int spacing: 8

    radius: theme.radius
    color: fillColor
    border.color: borderColor
    border.width: 1

    implicitHeight: Math.max(contentRow.implicitHeight + verticalPadding * 2, 34)
    implicitWidth: contentRow.implicitWidth + horizontalPadding * 2

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 1
        height: Math.max(1, parent.height * 0.18)
        radius: root.radius
        color: Qt.rgba(1, 1, 1, 0.06)
    }

    Rectangle {
        visible: root.glowOpacity > 0
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 4
        height: 2
        radius: 1
        color: Qt.alpha(root.glowColor, root.glowOpacity)
    }

    RowLayout {
        id: contentRow

        anchors.fill: parent
        anchors.leftMargin: root.horizontalPadding
        anchors.rightMargin: root.horizontalPadding
        anchors.topMargin: root.verticalPadding
        anchors.bottomMargin: root.verticalPadding
        spacing: root.spacing
    }
}
