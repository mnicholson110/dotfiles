import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
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

    anchors {
        top: true
        left: true
        right: true
    }

    color: "transparent"
    implicitHeight: shell.barHeight
    exclusiveZone: shell.barReserve

    readonly property string activeWindowTitle: Hyprland.activeToplevel ? Hyprland.activeToplevel.title : "Desktop"
    property date now: new Date()
    readonly property string clockText: Qt.formatDateTime(now, "yyyy-MM-dd hh:mm AP")

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

    function launcherIconSource(icon: string): url {
        if (!icon)
            return Quickshell.iconPath("application-x-executable");

        if (icon.endsWith("-symbolic"))
            return Quickshell.iconPath(icon.slice(0, -9), "application-x-executable");

        return Quickshell.iconPath(icon, "application-x-executable");
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
        id: barFrame

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: shell.barHeight
        radius: 0
        color: theme.surface
        border.color: theme.borderStrong
        border.width: 1

        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: parent.border.width + 1
            color: theme.surface
        }

        Rectangle {
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            width: parent.border.width + 1
            color: theme.surface
        }

        Rectangle {
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            width: parent.border.width + 1
            color: theme.surface
        }

        Rectangle {
            id: centerPlate

            width: parent.width * shell.centerPillWidthRatio
            height: parent.height - 10
            anchors.centerIn: parent
            radius: theme.radius
            color: theme.surfaceRaised
            border.color: theme.border
            border.width: 1

        }

        Text {
            anchors.centerIn: centerPlate
            width: centerPlate.width - 28
            text: root.activeWindowTitle
            color: theme.text
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.family: "GoMono Nerd Font Mono"
            font.bold: true
            font.pixelSize: 15
        }

        Item {
            anchors.left: parent.left
            anchors.leftMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(0, centerPlate.x - 30)
            height: leftRow.implicitHeight

            RowLayout {
                id: leftRow

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                Row {
                    spacing: 8

                    Repeater {
                        id: trayRepeater

                        model: SystemTray.items.values

                        MouseArea {
                            required property var modelData

                            width: 18
                            height: 18
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            cursorShape: Qt.PointingHandCursor
                            opacity: containsMouse ? 1 : 0.84

                            onClicked: event => {
                                if (event.button === Qt.LeftButton) {
                                    if (modelData.hasMenu)
                                        shell.toggleTrayMenu(modelData);
                                    else
                                        modelData.activate();
                                } else {
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
                    visible: controllerBattery.text.length > 0 || gloveBattery.text.length > 0
                    width: 1
                    height: 18
                    color: theme.border
                }

                Text {
                    visible: controllerBattery.text.length > 0
                    text: `PS5 ${controllerBattery.text}`
                    color: theme.textMuted
                    font.family: "GoMono Nerd Font Mono"
                    font.bold: true
                    font.pixelSize: 13
                }

                Text {
                    visible: gloveBattery.text.length > 0
                    text: `GLV ${gloveBattery.text}`
                    color: theme.textMuted
                    font.family: "GoMono Nerd Font Mono"
                    font.bold: true
                    font.pixelSize: 13
                }
            }
        }

        Item {
            id: clockHitbox

            anchors.right: parent.right
            anchors.rightMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: clockRow.implicitWidth
            implicitHeight: clockRow.implicitHeight

            RowLayout {
                id: clockRow

                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                spacing: 8

                Rectangle {
                    width: 7
                    height: 7
                    radius: 4
                    color: shell.barMenu === "clock" ? theme.primaryStrong : theme.textFaint
                }

                Text {
                    text: root.clockText
                    color: theme.primary
                    font.family: "GoMono Nerd Font Mono"
                    font.bold: true
                    font.pixelSize: 15
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: shell.toggleClockMenu()
            }
        }
    }
}
