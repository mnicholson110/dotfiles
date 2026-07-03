import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "../components" as Components


PanelWindow {
    id: root

    Components.Theme {
        id: theme
    }

    required property QtObject shell
    property var panelScreen: shell.panelScreen
    screen: root.panelScreen

    anchors {
        top: true
        left: true
        right: true
    }

    color: "transparent"
    implicitHeight: shell.barHeight
    exclusiveZone: shell.barReserve

    property date now: new Date()
    readonly property string clockText: Qt.formatDateTime(now, "ddd MM/dd/yyyy hh:mm AP")

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

    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: root.now = new Date()
    }

    Item {
        id: controllerBattery

        visible: false
        width: 0
        height: 0

        property string text: ""
        property string tooltip: ""

        function updateFrom(raw: string): void {
            const trimmed = raw.trim();
            if (!trimmed) {
                text = "";
                tooltip = "";
                return;
            }

            try {
                const payload = JSON.parse(trimmed);
                text = payload.text || "";
                tooltip = payload.tooltip || "";
            } catch (_) {
                text = trimmed;
                tooltip = trimmed;
            }
        }

        Process {
            id: controllerBatteryProc

            command: ["sh", "-lc", "/home/matt/.dotfiles/scripts/controller_bat"]
            stdout: StdioCollector {
                onStreamFinished: controllerBattery.updateFrom(this.text)
            }
        }

        Timer {
            interval: 10000
            repeat: true
            running: true
            triggeredOnStart: true
            onTriggered: controllerBatteryProc.running = true
        }
    }

    Item {
        id: gloveBattery

        visible: false
        width: 0
        height: 0

        property string text: ""
        property string tooltip: ""

        function updateFrom(raw: string): void {
            const trimmed = raw.trim();
            if (!trimmed) {
                text = "";
                tooltip = "";
                return;
            }

            try {
                const payload = JSON.parse(trimmed);
                text = payload.text || "";
                tooltip = payload.tooltip || "";
            } catch (_) {
                text = trimmed;
                tooltip = trimmed;
            }
        }

        Process {
            id: gloveBatteryProc

            command: ["sh", "-lc", "/home/matt/.dotfiles/scripts/glove80_bat"]
            stdout: StdioCollector {
                onStreamFinished: gloveBattery.updateFrom(this.text)
            }
        }

        Timer {
            interval: 10000
            repeat: true
            running: true
            triggeredOnStart: true
            onTriggered: gloveBatteryProc.running = true
        }
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
                    visible: SystemTray.items.values.length > 0 && (controllerBattery.text.length > 0 || gloveBattery.text.length > 0)
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: 18
                    color: theme.border
                    Layout.alignment: Qt.AlignVCenter
                }

                Text {
                    visible: controllerBattery.text.length > 0
                    text: `PS5 ${controllerBattery.text}`
                    color: theme.textMuted
                    font.family: "GoMono Nerd Font Mono"
                    font.bold: true
                    font.pixelSize: 12
                    Layout.alignment: Qt.AlignVCenter
                }

                Text {
                    visible: gloveBattery.text.length > 0
                    text: `GLV ${gloveBattery.text}`
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
                        text: root.clockText
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
