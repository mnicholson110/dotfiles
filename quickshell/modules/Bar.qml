import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import Quickshell.Widgets
import "../components" as Components

PanelWindow {
    id: root
    required property QtObject shell
    required property var panelScreen
    readonly property var player: Mpris.players.values.find(p => p.isPlaying && p.trackTitle) ?? null
    readonly property bool expanded: hover.hovered || (shell.barMenu !== "" && shell.barPopupScreen === panelScreen)
    screen: panelScreen
    anchors.right: true
    anchors.bottom: true
    margins.right: shell.dockInset
    margins.bottom: shell.dockInset
    implicitHeight: shell.dockSize
    implicitWidth: expanded ? Math.min(screen.width - 2 * shell.dockInset, details.implicitWidth + height + 30) : height
    color: "transparent"
    exclusiveZone: 0
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Components.Theme { id: theme }

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
        radius: height / 2
        border.color: theme.border
        clip: true
        HoverHandler { id: hover }

        RowLayout {
            id: details
            visible: root.expanded
            anchors.left: parent.left
            anchors.leftMargin: 18
            anchors.right: dial.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12

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


            Column {
                Layout.fillWidth: true
                spacing: 1
                Text {
                    width: parent.width
                    text: root.player ? [root.player.trackArtist, root.player.trackTitle].filter(Boolean).join(" · ") : shell.dateText
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                    color: theme.text
                    font.family: theme.fontFamily
                    font.pixelSize: 13
                }
                Text {
                    text: [shell.clockText, shell.controllerBatteryText && "PS5 " + shell.controllerBatteryText,
                           shell.gloveBatteryText && "Glove80 " + shell.gloveBatteryText,
                           shell.deathadderBatteryText && "Mouse " + shell.deathadderBatteryText].filter(Boolean).join("   ·   ")
                    color: theme.textFaint
                    font.family: theme.fontFamily
                    font.pixelSize: 11
                }
                Layout.preferredWidth: Math.min(360, Math.max(children[0].implicitWidth, children[1].implicitWidth))
            }
        }

        Components.ClockFace {
            id: dial
            anchors.right: parent.right
            anchors.rightMargin: 5
            anchors.verticalCenter: parent.verticalCenter
            width: parent.height - 10
            height: width
            time: shell.now
            TapHandler { onTapped: shell.toggleClockMenu(root.panelScreen) }
        }
    }
}
