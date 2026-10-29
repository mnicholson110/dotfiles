import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "../components" as Components


PanelWindow {
    id: root

    Components.Theme {
        id: theme
    }

    required property QtObject shell
    required property var panelScreen
    screen: root.panelScreen

    anchors {
        top: true
        left: true
        right: true
    }

    color: theme.background
    implicitHeight: shell.barHeight
    exclusiveZone: shell.barReserve

    function trayIconSource(icon: string): url {
        if (!icon)
            return "image-missing";

        if (icon.includes("?fallback="))
            icon = icon.split("?fallback=")[0];

        if (icon.includes("?path=")) {
            const parts = icon.split("?path=");
            const name = parts[0];
            const path = parts[1].split("?")[0];
            return Qt.resolvedUrl(`${path}/${name.slice(name.lastIndexOf("/") + 1)}`);
        }

        if (icon.startsWith("image://") || icon.startsWith("file:") || icon.startsWith("/"))
            return icon;

        if (icon.endsWith("-symbolic"))
            return Quickshell.iconPath(icon.slice(0, -9), "image-missing");

        return Quickshell.iconPath(icon, "image-missing");
    }

    Rectangle {
        anchors.fill: parent
        color: theme.background
        border.width: 0

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: theme.borderStrong
        }

        Item {
            id: titleStage

            anchors.centerIn: parent
            width: Math.max(320, Math.min(460, parent.width * 0.42))
            height: parent.height

            RowLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.centerIn: parent
                anchors.leftMargin: 44
                anchors.rightMargin: 44
                spacing: 10

            }
        }

        Item {
            id: leftZone

            anchors.left: parent.left
            anchors.right: titleStage.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.leftMargin: 14
            anchors.rightMargin: 12
            clip: true

            RowLayout {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                Row {
                    visible: SystemTray.items.values.length > 0
                    spacing: 8
                    Layout.alignment: Qt.AlignVCenter

                    Repeater {
                        model: SystemTray.items.values

                        MouseArea {
                            required property var modelData

                            width: 18
                            height: 18
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            cursorShape: Qt.PointingHandCursor
                            opacity: containsMouse ? 1 : 0.78

                            onClicked: event => {
                                if (event.button === Qt.LeftButton) {
                                    if (modelData.hasMenu)
                                        shell.toggleTrayMenu(modelData, root.panelScreen);
                                    else
                                        modelData.activate();
                                } else {
                                    if (modelData.hasMenu)
                                        shell.toggleTrayMenu(modelData, root.panelScreen);
                                    else
                                        modelData.secondaryActivate();
                                }
                            }

                            IconImage {
                                anchors.fill: parent
                                asynchronous: true
                                source: root.trayIconSource(parent.modelData.icon)
                            }
                        }
                    }
                }

                Rectangle {
                    visible: SystemTray.items.values.length > 0 && (shell.controllerBatteryText.length > 0 || shell.gloveBatteryText.length > 0 || shell.deathadderBatteryText.length > 0)
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: 18
                    color: theme.border
                    Layout.alignment: Qt.AlignVCenter
                }

                Text {
                    visible: shell.controllerBatteryText.length > 0
                    text: `PS5 ${shell.controllerBatteryText}`
                    color: theme.textMuted
                    font.family: "GoMono Nerd Font Mono"
                    font.bold: true
                    font.pixelSize: 12
                    Layout.alignment: Qt.AlignVCenter
                }

                Text {
                    visible: shell.gloveBatteryText.length > 0
                    text: `GLV ${shell.gloveBatteryText}`
                    color: theme.textMuted
                    font.family: "GoMono Nerd Font Mono"
                    font.bold: true
                    font.pixelSize: 12
                    Layout.alignment: Qt.AlignVCenter
                }

                Text {
                    visible: shell.deathadderBatteryText.length > 0
                    text: `DA ${shell.deathadderBatteryText}`
                    color: theme.textMuted
                    font.family: "GoMono Nerd Font Mono"
                    font.bold: true
                    font.pixelSize: 12
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }

        Item {
            id: rightZone

            anchors.left: titleStage.right
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.leftMargin: 12
            anchors.rightMargin: 14
            clip: true

            Item {
                id: clockHitbox

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: clockRow.implicitWidth
                height: 28

                RowLayout {
                    id: clockRow

                    anchors.centerIn: parent
                    spacing: 8

                    Rectangle {
                        width: 7
                        height: 7
                        radius: 1
                        color: shell.barMenu === "clock" ? theme.primaryStrong : theme.textFaint
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                        text: shell.clockText
                        color: theme.text
                        font.family: "GoMono Nerd Font Mono"
                        font.bold: true
                        font.pixelSize: 13
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: shell.toggleClockMenu(root.panelScreen)
                }
            }
        }
    }
}
