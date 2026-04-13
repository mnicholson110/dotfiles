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
    property string searchText: ""
    readonly property int panelWidth: Math.round(width * shell.centerPillWidthRatio)
    readonly property int panelMaxHeight: 520

    anchors {
        top: true
        left: true
        right: true
    }
    margins.top: shell.barHeight - 1

    visible: shell.launcherOpen || root.revealHeight > 0
    color: "transparent"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shell.launcherOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    implicitHeight: revealHeight

    readonly property var visibleApps: {
        const apps = DesktopEntries.applications.values.filter(app => !shell.isHiddenApp(app));
        apps.sort((a, b) => {
            const weightDelta = shell.launcherHistoryWeight(b) - shell.launcherHistoryWeight(a);
            if (weightDelta !== 0)
                return weightDelta;

            const recentIndexA = shell.launcherHistoryRecentIndex(a);
            const recentIndexB = shell.launcherHistoryRecentIndex(b);
            if (recentIndexA !== recentIndexB) {
                if (recentIndexA === -1)
                    return 1;
                if (recentIndexB === -1)
                    return -1;
                return recentIndexA - recentIndexB;
            }

            return (a.name || a.id || "").localeCompare(b.name || b.id || "");
        });
        return apps;
    }
    readonly property var filteredApps: {
        const query = searchText.trim().toLowerCase();
        if (!query)
            return visibleApps;

        return visibleApps.filter(app => root.matchesSearch(app, query));
    }

    function matchesSearch(app: DesktopEntry, query: string): bool {
        const haystack = [
            app.name || "",
            app.id || "",
            app.genericName || "",
            app.comment || "",
            app.execString || "",
            app.startupClass || "",
            app.categories ? app.categories.join(" ") : "",
            app.keywords ? app.keywords.join(" ") : ""
        ].join(" ").toLowerCase();

        return haystack.includes(query);
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

    function resetSelection(): void {
        if (filteredApps.length === 0) {
            appList.currentIndex = -1;
            return;
        }

        appList.currentIndex = 0;
        appList.positionViewAtIndex(0, ListView.Beginning);
    }

    function moveSelection(delta: int): void {
        if (filteredApps.length === 0) {
            appList.currentIndex = -1;
            return;
        }

        const baseIndex = appList.currentIndex < 0 ? 0 : appList.currentIndex;
        const nextIndex = Math.max(0, Math.min(filteredApps.length - 1, baseIndex + delta));
        appList.currentIndex = nextIndex;
        appList.positionViewAtIndex(nextIndex, ListView.Contain);
    }

    function canAppendSearchText(event: KeyEvent): bool {
        const disallowedModifiers = event.modifiers & ~(Qt.ShiftModifier | Qt.KeypadModifier);
        if (disallowedModifiers !== 0)
            return false;

        if (!event.text || event.text.length === 0)
            return false;

        return !/[\r\n\t]/.test(event.text);
    }

    Connections {
        target: shell

        function onLauncherOpenChanged(): void {
            if (shell.launcherOpen) {
                root.searchText = "";
                root.resetSelection();
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

    onFilteredAppsChanged: {
        if (!shell.launcherOpen)
            return;

        if (filteredApps.length === 0) {
            appList.currentIndex = -1;
            root.revealHeight = launcherCard.implicitHeight + 12;
            return;
        }

        resetSelection();
        root.revealHeight = launcherCard.implicitHeight + 12;
    }

    onSearchTextChanged: {
        if (shell.launcherOpen)
            root.revealHeight = launcherCard.implicitHeight + 12;
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
            implicitHeight: Math.max(
                root.searchText.length > 0 ? 118 : 92,
                Math.min(
                    root.panelMaxHeight,
                    24
                    + (searchBar.visible ? searchBar.height + 8 : 0)
                    + (root.filteredApps.length > 0 ? appList.contentHeight : emptyState.implicitHeight)
                )
            )
            height: implicitHeight
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            radius: theme.radius
            topLeftRadius: 0
            topRightRadius: 0
            color: theme.surface
            border.color: theme.borderStrong
            border.width: 1
            onImplicitHeightChanged: {
                if (shell.launcherOpen && !openAnim.running && !closeAnim.running)
                    root.revealHeight = implicitHeight + 12;
            }

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

            Rectangle {
                id: searchBar

                visible: root.searchText.length > 0
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 12
                height: 42
                radius: theme.radius
                color: Qt.alpha(theme.surfaceRaised, 0.94)
                border.color: theme.primaryStrong
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 10

                    Text {
                        text: root.searchText
                        color: theme.text
                        elide: Text.ElideRight
                        font.family: "GoMono Nerd Font Mono"
                        font.pixelSize: 16
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Rectangle {
                        width: 2
                        height: 18
                        radius: 1
                        color: theme.primaryStrong
                        Layout.alignment: Qt.AlignVCenter

                        SequentialAnimation on opacity {
                            running: searchBar.visible && shell.launcherOpen
                            loops: Animation.Infinite
                            NumberAnimation { to: 1; duration: 0 }
                            PauseAnimation { duration: 520 }
                            NumberAnimation { to: 0; duration: 0 }
                            PauseAnimation { duration: 360 }
                        }
                    }
                }
            }

            ListView {
                id: appList

                anchors.top: searchBar.visible ? searchBar.bottom : parent.top
                anchors.topMargin: searchBar.visible ? 8 : 12
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                anchors.bottomMargin: 12
                clip: true
                spacing: 8
                boundsBehavior: Flickable.StopAtBounds
                model: root.filteredApps
                currentIndex: model.length > 0 ? 0 : -1
                keyNavigationWraps: false
                focus: shell.launcherOpen

                Keys.onPressed: event => {
                    switch (event.key) {
                    case Qt.Key_Escape:
                        shell.closeOverlays();
                        event.accepted = true;
                        return;
                    case Qt.Key_Return:
                    case Qt.Key_Enter:
                        root.launchCurrent();
                        event.accepted = true;
                        return;
                    case Qt.Key_Right:
                    case Qt.Key_Down:
                        root.moveSelection(1);
                        event.accepted = true;
                        return;
                    case Qt.Key_Left:
                    case Qt.Key_Up:
                        root.moveSelection(-1);
                        event.accepted = true;
                        return;
                    case Qt.Key_Backspace:
                        if (root.searchText.length > 0) {
                            root.searchText = root.searchText.slice(0, -1);
                            event.accepted = true;
                        }
                        return;
                    default:
                        break;
                    }

                    if (!root.canAppendSearchText(event))
                        return;

                    root.searchText += event.text;
                    event.accepted = true;
                }

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

            Item {
                id: emptyState

                visible: root.filteredApps.length === 0
                anchors.top: searchBar.visible ? searchBar.bottom : parent.top
                anchors.topMargin: searchBar.visible ? 8 : 12
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                implicitHeight: 74
                height: implicitHeight

                Text {
                    anchors.centerIn: parent
                    text: root.searchText.length > 0 ? "No matches for \"" + root.searchText + "\"" : "No apps available"
                    color: theme.textMuted
                    font.family: "GoMono Nerd Font Mono"
                    font.pixelSize: 15
                }
            }
        }
    }
}
