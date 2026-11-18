import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../components" as Components

PanelWindow {
    id: root

    Components.Theme {
        id: theme
    }

    required property QtObject shell
    screen: shell.panelScreen
    property var pendingAction: null
    property int selected: 0
    implicitWidth: Math.min(580, screen.width - 40)
    implicitHeight: Math.min(290, screen.height - 40)
    visible: shell.sessionOpen
    color: "transparent"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    readonly property var actions: [
        {
            id: "lock",
            label: "Lock",
            command: "pidof hyprlock || hyprlock"
        },
        {
            id: "logout",
            label: "Log out",
            command: ["uwsm", "stop"],
            detached: true
        },
        {
            id: "shutdown",
            label: "Shut down",
            command: ["systemctl", "--no-block", "poweroff"],
            detached: true
        },
        {
            id: "reboot",
            label: "Restart",
            command: ["systemctl", "--no-block", "reboot"],
            detached: true
        }
    ]

    function runAction(action): void {
        shell.closeOverlays();
        if (action && action.id === "lock") {
            pendingAction = action;
            actionTimer.restart();
            return;
        }

        if (action.detached) {
            shell.runDetached(action.command);
            return;
        }

        shell.runShell(action.command);
    }

    onVisibleChanged: if (visible) {
        selected = 0;
        card.forceActiveFocus();
    }

    Timer {
        id: actionTimer

        interval: 160
        repeat: false
        onTriggered: {
            if (!root.pendingAction)
                return;

            const action = root.pendingAction;
            root.pendingAction = null;
            shell.runShell(action.command);
        }
    }

    HyprlandFocusGrab {
        active: root.visible
        windows: [root]
        onCleared: shell.closeOverlays()
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: 20
        border.color: theme.borderStrong
        color: theme.background
        focus: true
        Keys.onPressed: event => {
            switch (event.key) {
            case Qt.Key_Up: case Qt.Key_Left: case Qt.Key_K:
                root.selected = Math.max(0, root.selected - 1);
                break;
            case Qt.Key_Down: case Qt.Key_Right: case Qt.Key_J:
                root.selected = Math.min(root.actions.length - 1, root.selected + 1);
                break;
            case Qt.Key_Return: case Qt.Key_Enter: case Qt.Key_Space:
                if (!event.isAutoRepeat)
                    root.runAction(root.actions[root.selected]);
                break;
            case Qt.Key_Escape:
                shell.closeOverlays();
                break;
            default: return;
            }
            event.accepted = true;
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 28
            spacing: 28
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10
                Components.ClockFace {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: Math.min(152, root.width * 0.26)
                    Layout.preferredHeight: Layout.preferredWidth
                    time: shell.now
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: shell.dateText
                    font.family: theme.fontFamily
                    font.pixelSize: 14
                    color: theme.textMuted
                }
            }
            Rectangle { Layout.fillHeight: true; implicitWidth: 1; color: theme.border }
            Column {
                Layout.fillWidth: true
                spacing: 4
                Repeater {
                    model: root.actions
                    Text {
                        required property var modelData
                        required property int index
                        width: parent.width
                        height: 44
                        verticalAlignment: Text.AlignVCenter
                        text: modelData.label
                        color: index === root.selected ? theme.primaryStrong : theme.textFaint
                        font.family: theme.fontFamily
                        font.pixelSize: index === root.selected ? 29 : 20
                        Behavior on font.pixelSize { NumberAnimation { duration: 100 } }
                        TapHandler { onTapped: root.runAction(modelData) }
                    }
                }
            }
        }
    }
}
