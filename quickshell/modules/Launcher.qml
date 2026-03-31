import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import "../components" as Components

PanelWindow {
    id: root

    Components.Theme {
        id: theme
    }

    required property QtObject shell
    property real revealHeight: 0
    readonly property int panelWidth: Math.round(width * shell.centerPillWidthRatio)
    readonly property int panelMaxHeight: 520

    anchors {
        top: true
        left: true
        right: true
    }
    margins.top: shell.barHeight - 1

    visible: true
    color: "transparent"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shell.launcherOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    implicitHeight: revealHeight

    readonly property var visibleApps: {
        const apps = DesktopEntries.applications.values.filter(app => !shell.isHiddenApp(app));
        apps.sort((a, b) => {
            const rankDelta = shell.launcherMruRank(a) - shell.launcherMruRank(b);
            if (rankDelta !== 0)
                return rankDelta;

            return (a.name || a.id || "").localeCompare(b.name || b.id || "");
        });
        return apps;
    }

    function appIconSource(icon: string): url {
        if (!icon)
            return Quickshell.iconPath("application-x-executable");

        if (icon.includes("?"))
            icon = icon.split("?")[0];

        if (icon.endsWith("-symbolic"))
            return Quickshell.iconPath(icon.slice(0, -9), "application-x-executable");

        return Quickshell.iconPath(icon, "application-x-executable");
    }

    function launchCurrent(): void {
        if (appList.currentItem)
            shell.launchDesktopEntry(appList.currentItem.modelData);
    }

    function moveSelection(delta: int): void {
        if (visibleApps.length === 0) {
            appList.currentIndex = -1;
            return;
        }

        const baseIndex = appList.currentIndex < 0 ? 0 : appList.currentIndex;
        const nextIndex = Math.max(0, Math.min(visibleApps.length - 1, baseIndex + delta));
        appList.currentIndex = nextIndex;
        appList.positionViewAtIndex(nextIndex, ListView.Contain);
    }

    Connections {
        target: shell

        function onLauncherOpenChanged(): void {
            if (shell.launcherOpen) {
                appList.currentIndex = visibleApps.length > 0 ? 0 : -1;
                focusTimer.restart();
            }

            if (shell.launcherOpen) {
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
        to: launcherCard.implicitHeight + 12
        duration: 155
        easing.type: Easing.BezierSpline
        easing.bezierCurve: [0.38, 1.21, 0.22, 1, 1, 1]
        onStopped: {
            if (shell.launcherOpen)
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
            if (shell.launcherOpen)
                appList.forceActiveFocus();
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.revealHeight > 0
        onClicked: shell.closeOverlays()
    }

    HyprlandFocusGrab {
        active: shell.launcherOpen
        windows: [QsWindow.window]
        onCleared: shell.closeOverlays()
    }

    Item {
        anchors.fill: parent
        clip: true

        Rectangle {
            id: launcherCard

            width: root.panelWidth
            implicitHeight: Math.max(92, Math.min(root.panelMaxHeight, appList.contentHeight + 24))
            height: implicitHeight
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            radius: theme.radius
            topLeftRadius: 0
            topRightRadius: 0
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

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
            }

            ListView {
                id: appList

                anchors.fill: parent
                anchors.margins: 12
                clip: true
                spacing: 8
                boundsBehavior: Flickable.StopAtBounds
                model: root.visibleApps
                currentIndex: model.length > 0 ? 0 : -1
                keyNavigationWraps: false
                focus: shell.launcherOpen

                Keys.onEscapePressed: shell.closeOverlays()
                Keys.onReturnPressed: root.launchCurrent()
                Keys.onEnterPressed: root.launchCurrent()
                Keys.onDownPressed: root.moveSelection(1)
                Keys.onUpPressed: root.moveSelection(-1)

                delegate: Rectangle {
                    id: appDelegate

                    required property DesktopEntry modelData
                    required property int index

                    height: 60
                    width: ListView.view.width
                    radius: theme.radius
                    color: ListView.isCurrentItem ? Qt.alpha(theme.primaryContainer, 0.7) : Qt.alpha(theme.surfaceRaised, 0.88)
                    border.color: ListView.isCurrentItem ? theme.primaryStrong : theme.border
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        spacing: 12

                        Rectangle {
                            Layout.preferredWidth: 42
                            Layout.preferredHeight: 42
                            Layout.alignment: Qt.AlignVCenter
                            radius: theme.radius
                            color: ListView.isCurrentItem ? Qt.alpha(theme.primaryStrong, 0.12) : Qt.alpha(theme.border, 0.35)
                            border.color: Qt.alpha(theme.borderStrong, 0.85)
                            border.width: 1

                            IconImage {
                                anchors.centerIn: parent
                                width: 26
                                height: 26
                                asynchronous: true
                                source: root.appIconSource(appDelegate.modelData.icon)
                            }
                        }

                        Text {
                            text: appDelegate.modelData.name || appDelegate.modelData.id
                            color: theme.text
                            elide: Text.ElideRight
                            font.family: "GoMono Nerd Font Mono"
                            font.bold: true
                            font.pixelSize: 17
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: appList.currentIndex = appDelegate.index
                        onClicked: shell.launchDesktopEntry(appDelegate.modelData)
                    }
                }
            }
        }
    }
}
