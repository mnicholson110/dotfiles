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
    property real revealHeight: 0
    property var pendingAction: null
    readonly property int gridColumns: 2
    readonly property int gridSpacing: 14
    readonly property int panelWidth: Math.round(width * shell.centerPillWidthRatio)
    readonly property int buttonWidth: Math.floor((panelWidth - 48 - ((gridColumns - 1) * gridSpacing)) / gridColumns)
    readonly property int buttonHeight: 88

    anchors {
        top: true
        left: true
        right: true
    }
    margins.top: shell.barHeight - 1

    visible: shell.sessionOpen || root.revealHeight > 0
    color: "transparent"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shell.sessionOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    implicitHeight: revealHeight

    readonly property var actions: [
        {
            id: "lock",
            label: "Lock",
            command: "pidof hyprlock || hyprlock"
        },
        {
            id: "logout",
            label: "Logout",
            command: "hyprctl dispatch exit"
        },
        {
            id: "shutdown",
            label: "Shutdown",
            command: "systemctl poweroff"
        },
        {
            id: "reboot",
            label: "Reboot",
            command: "systemctl reboot"
        }
    ]

    function runAction(action): void {
        shell.closeOverlays();
        if (action && action.id === "lock") {
            pendingAction = action;
            actionTimer.restart();
            return;
        }

        shell.runShell(action.command);
    }

    function focusButton(index: int): void {
        const button = actionButtons[index];
        if (button)
            button.forceActiveFocus();
    }

    function moveFocus(index: int, delta: int): void {
        const nextIndex = index + delta;
        if (nextIndex >= 0 && nextIndex < actions.length)
            focusButton(nextIndex);
    }

    Connections {
        target: shell

        function onSessionOpenChanged(): void {
            if (shell.sessionOpen && firstButton)
                focusTimer.restart();

            if (shell.sessionOpen) {
                closeAnim.stop();
                openAnim.start();
            } else {
                openAnim.stop();
                closeAnim.start();
            }
        }
    }

    NumberAnimation {
        id: openAnim

        target: root
        property: "revealHeight"
        from: root.revealHeight
        to: card.implicitHeight + 12
        duration: 155
        easing.type: Easing.BezierSpline
        easing.bezierCurve: [0.38, 1.21, 0.22, 1, 1, 1]
        onStopped: {
            if (shell.sessionOpen && firstButton)
                focusTimer.restart();
        }
    }

    NumberAnimation {
        id: closeAnim

        target: root
        property: "revealHeight"
        from: root.revealHeight
        to: 0
        duration: 120
        easing.type: Easing.BezierSpline
        easing.bezierCurve: [0.05, 0, 0.1333, 0.06, 0.1667, 0.4, 0.2083, 0.82, 0.25, 1, 1, 1]
    }

    Timer {
        id: focusTimer

        interval: 60
        repeat: false
        onTriggered: {
            if (shell.sessionOpen && firstButton)
                firstButton.forceActiveFocus();
        }
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

    MouseArea {
        anchors.fill: parent
        enabled: root.revealHeight > 0
        onClicked: shell.closeOverlays()
    }

    HyprlandFocusGrab {
        active: shell.sessionOpen
        windows: [QsWindow.window]
        onCleared: shell.closeOverlays()
    }

    Item {
        anchors.fill: parent
        clip: true

        Rectangle {
            id: card

            width: root.panelWidth
            implicitHeight: actionGrid.implicitHeight + 48
            height: implicitHeight
            radius: theme.radius
            topLeftRadius: 0
            topRightRadius: 0
            color: theme.surface
            border.color: theme.borderStrong
            border.width: 1
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter

            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: parent.border.width + 1
                color: theme.surface
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
            }

            Keys.onEscapePressed: shell.closeOverlays()

            GridLayout {
                id: actionGrid

                anchors.fill: parent
                anchors.margins: 24
                columns: root.gridColumns
                columnSpacing: root.gridSpacing
                rowSpacing: root.gridSpacing

                Repeater {
                    model: root.actions

                    Components.ActionButton {
                        id: button

                        required property var modelData
                        required property int index

                        objectName: modelData.id
                        text: modelData.label
                        Layout.preferredWidth: root.buttonWidth
                        Layout.preferredHeight: root.buttonHeight
                        Layout.minimumWidth: root.buttonWidth
                        Layout.minimumHeight: root.buttonHeight

                        Component.onCompleted: {
                            root.actionButtons[index] = button;
                            if (index === 0)
                                firstButton = button;
                        }

                        onClicked: root.runAction(modelData)

                        Keys.onLeftPressed: event => {
                            root.moveFocus(index, -1);
                            event.accepted = true;
                        }

                        Keys.onRightPressed: event => {
                            root.moveFocus(index, 1);
                            event.accepted = true;
                        }

                        Keys.onUpPressed: event => {
                            root.moveFocus(index, -root.gridColumns);
                            event.accepted = true;
                        }

                        Keys.onDownPressed: event => {
                            root.moveFocus(index, root.gridColumns);
                            event.accepted = true;
                        }

                        Keys.onReturnPressed: event => {
                            root.runAction(modelData);
                            event.accepted = true;
                        }

                        Keys.onEnterPressed: event => {
                            root.runAction(modelData);
                            event.accepted = true;
                        }
                    }
                }
            }
        }
    }

    property Item firstButton: null
    property var actionButtons: []
}
