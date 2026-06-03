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
    screen: shell.panelScreen
    property real revealHeight: 0
    property string searchText: ""
    readonly property int panelWidth: Math.max(520, Math.min(760, width - 72))
    readonly property int panelHeight: 536

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

            return (a.name || a.id || "").localeCompare(b.name || b.id || "");
        });
        return apps;
    }
    readonly property var filteredApps: {
        const query = searchText.trim().toLowerCase();
        return query ? visibleApps.filter(app => root.matchesSearch(app, query)) : visibleApps;
    }
    readonly property var recentApps: {
        const apps = visibleApps.filter(app => shell.launcherHistoryRecentIndex(app) >= 0);
        apps.sort((a, b) => shell.launcherHistoryRecentIndex(a) - shell.launcherHistoryRecentIndex(b));
        return apps.slice(0, 5);
    }
    readonly property bool commandMode: searchText.trim().length > 0 && filteredApps.length === 0

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

    function appGlyph(app: DesktopEntry): string {
        const label = app ? (app.name || app.id || "?") : "?";
        return label.slice(0, 1).toUpperCase();
    }

    function appIconSource(icon: string): url {
        if (!icon)
            return "";

        if (icon.includes("?"))
            icon = icon.split("?")[0];

        if (icon.endsWith("-symbolic"))
            return Quickshell.iconPath(icon.slice(0, -9), "");

        return Quickshell.iconPath(icon, "");
    }

    function launchCurrent(): void {
        if (appList.currentIndex >= 0 && appList.currentIndex < filteredApps.length) {
            shell.launchDesktopEntry(filteredApps[appList.currentIndex]);
            return;
        }

        const command = searchText.trim();
        if (command.length > 0) {
            shell.closeOverlays();
            shell.runShell(command);
        }
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

    onSearchTextChanged: {
        if (searchInput.text !== root.searchText)
            searchInput.text = root.searchText;
    }

    onFilteredAppsChanged: {
        if (shell.launcherOpen)
            resetSelection();
    }

    Connections {
        target: shell

        function onLauncherOpenChanged(): void {
            if (shell.launcherOpen) {
                root.searchText = "";
                searchInput.text = "";
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

    NumberAnimation {
        id: openAnim

        target: root
        property: "revealHeight"
        from: root.revealHeight
        to: launcherCard.height + 16
        duration: 155
        easing.type: Easing.OutCubic
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
        duration: 115
        easing.type: Easing.InCubic
    }

    Timer {
        id: focusTimer

        interval: 60
        repeat: false
        onTriggered: {
            if (shell.launcherOpen)
                searchInput.forceActiveFocus();
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

            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: root.panelWidth
            height: root.panelHeight
            radius: theme.radius
            topLeftRadius: 0
            topRightRadius: 0
            color: theme.surface
            border.color: theme.primaryStrong
            border.width: 1
            clip: true

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
            }

            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 4
                color: theme.primaryStrong
            }

            Repeater {
                model: 9

                Rectangle {
                    required property int index

                    x: -160 + index * 118
                    y: 36 + index * 49
                    width: 220
                    height: 1
                    rotation: -18
                    opacity: 0.07
                    color: theme.primaryStrong
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 64
                    radius: theme.radius
                    color: theme.background
                    border.color: searchInput.activeFocus ? theme.primaryStrong : theme.borderStrong
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        spacing: 12

                        Text {
                            text: "ALT+D"
                            color: theme.textFaint
                            font.family: "GoMono Nerd Font Mono"
                            font.bold: true
                            font.pixelSize: 11
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Rectangle {
                            Layout.preferredWidth: 1
                            Layout.preferredHeight: 30
                            color: theme.borderStrong
                            Layout.alignment: Qt.AlignVCenter
                        }

                        TextField {
                            id: searchInput

                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            placeholderText: "type app name, or enter a shell command"
                            placeholderTextColor: theme.textFaint
                            selectByMouse: true
                            color: theme.text
                            selectedTextColor: theme.background
                            selectionColor: theme.primaryStrong
                            font.family: "GoMono Nerd Font Mono"
                            font.bold: true
                            font.pixelSize: 18

                            background: Item {}

                            onTextChanged: {
                                if (root.searchText !== text)
                                    root.searchText = text;
                            }

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
                                case Qt.Key_Down:
                                    root.moveSelection(1);
                                    event.accepted = true;
                                    return;
                                case Qt.Key_Up:
                                    root.moveSelection(-1);
                                    event.accepted = true;
                                    return;
                                case Qt.Key_PageDown:
                                    root.moveSelection(6);
                                    event.accepted = true;
                                    return;
                                case Qt.Key_PageUp:
                                    root.moveSelection(-6);
                                    event.accepted = true;
                                    return;
                                default:
                                    break;
                                }
                            }
                        }

                        Rectangle {
                            width: 2
                            height: 24
                            radius: 1
                            color: theme.primaryStrong
                            Layout.alignment: Qt.AlignVCenter

                            SequentialAnimation on opacity {
                                running: shell.launcherOpen
                                loops: Animation.Infinite
                                NumberAnimation {
                                    to: 0.2
                                    duration: 460
                                }
                                NumberAnimation {
                                    to: 1
                                    duration: 460
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: visible ? 34 : 0
                    visible: root.recentApps.length > 0 && root.searchText.length === 0
                    spacing: 8

                    Text {
                        text: "RECENT"
                        color: theme.textFaint
                        font.family: "GoMono Nerd Font Mono"
                        font.bold: true
                        font.pixelSize: 11
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Repeater {
                        model: root.recentApps

                        Rectangle {
                            id: recentChip

                            required property DesktopEntry modelData

                            Layout.preferredWidth: Math.min(112, recentText.implicitWidth + 24)
                            Layout.preferredHeight: 30
                            radius: theme.radius
                            color: recentHover.containsMouse ? theme.primaryStrong : theme.background
                            border.color: recentHover.containsMouse ? theme.primaryStrong : theme.border
                            border.width: 1

                            Text {
                                id: recentText

                                anchors.centerIn: parent
                                width: parent.width - 14
                                text: recentChip.modelData.name || recentChip.modelData.id
                                color: recentHover.containsMouse ? theme.background : theme.textMuted
                                elide: Text.ElideRight
                                horizontalAlignment: Text.AlignHCenter
                                font.family: "GoMono Nerd Font Mono"
                                font.bold: true
                                font.pixelSize: 11
                            }

                            MouseArea {
                                id: recentHover

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: shell.launchDesktopEntry(recentChip.modelData)
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: theme.radius
                    color: theme.background
                    border.color: theme.border
                    border.width: 1
                    clip: true

                    ListView {
                        id: appList

                        anchors.fill: parent
                        anchors.margins: 8
                        clip: true
                        spacing: 6
                        boundsBehavior: Flickable.StopAtBounds
                        model: root.filteredApps
                        currentIndex: model.length > 0 ? 0 : -1
                        keyNavigationWraps: false
                        interactive: contentHeight > height
                        cacheBuffer: 600

                        delegate: Rectangle {
                            id: appDelegate

                            required property DesktopEntry modelData
                            required property int index
                            readonly property bool selected: appList.currentIndex === index

                            width: ListView.view.width
                            height: 54
                            radius: theme.radius
                            color: selected ? theme.surfaceStrong : (hoverArea.containsMouse ? theme.surfaceRaised : "transparent")
                            border.color: selected ? theme.primaryStrong : (hoverArea.containsMouse ? theme.borderStrong : "transparent")
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                Rectangle {
                                    Layout.preferredWidth: 32
                                    Layout.preferredHeight: 32
                                    Layout.alignment: Qt.AlignVCenter
                                    radius: theme.radius
                                    color: appDelegate.selected ? theme.primaryStrong : theme.surfaceRaised
                                    border.color: appDelegate.selected ? theme.primaryStrong : theme.border
                                    border.width: 1

                                    IconImage {
                                        id: appIcon

                                        anchors.centerIn: parent
                                        width: 21
                                        height: 21
                                        asynchronous: true
                                        source: root.appIconSource(appDelegate.modelData.icon)
                                        visible: source !== ""
                                        opacity: appDelegate.selected ? 1 : 0.92
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        visible: !appIcon.visible
                                        text: root.appGlyph(appDelegate.modelData)
                                        color: appDelegate.selected ? theme.background : theme.textMuted
                                        font.family: "GoMono Nerd Font Mono"
                                        font.bold: true
                                        font.pixelSize: 14
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: 1

                                    Text {
                                        text: appDelegate.modelData.name || appDelegate.modelData.id
                                        color: appDelegate.selected ? theme.primaryStrong : theme.text
                                        elide: Text.ElideRight
                                        font.family: "GoMono Nerd Font Mono"
                                        font.bold: true
                                        font.pixelSize: 15
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        visible: (appDelegate.modelData.genericName || appDelegate.modelData.comment || "").length > 0
                                        text: appDelegate.modelData.genericName || appDelegate.modelData.comment
                                        color: appDelegate.selected ? theme.textMuted : theme.textFaint
                                        elide: Text.ElideRight
                                        font.family: "GoMono Nerd Font Mono"
                                        font.pixelSize: 11
                                        Layout.fillWidth: true
                                    }
                                }

                                Text {
                                    text: appDelegate.index + 1 < 10 ? "0" + (appDelegate.index + 1) : String(appDelegate.index + 1)
                                    color: appDelegate.selected ? theme.primaryStrong : theme.textFaint
                                    font.family: "GoMono Nerd Font Mono"
                                    font.bold: true
                                    font.pixelSize: 11
                                    Layout.alignment: Qt.AlignVCenter
                                }
                            }

                            MouseArea {
                                id: hoverArea

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: appList.currentIndex = appDelegate.index
                                onClicked: shell.launchDesktopEntry(appDelegate.modelData)
                            }
                        }

                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AlwaysOn
                            width: 5

                            contentItem: Rectangle {
                                radius: 2
                                color: parent.size < 1 ? theme.primaryStrong : theme.borderStrong
                                opacity: parent.size < 1 ? 0.95 : 0
                            }

                            background: Rectangle {
                                color: "transparent"
                            }
                        }
                    }

                    Rectangle {
                        visible: root.commandMode
                        anchors.fill: parent
                        anchors.margins: 8
                        radius: theme.radius
                        color: "transparent"
                        border.color: theme.borderStrong
                        border.width: 1

                        Column {
                            anchors.centerIn: parent
                            width: parent.width - 42
                            spacing: 10

                            Text {
                                width: parent.width
                                text: "EXEC SHELL"
                                color: theme.text
                                horizontalAlignment: Text.AlignHCenter
                                font.family: "GoMono Nerd Font Mono"
                                font.bold: true
                                font.pixelSize: 15
                            }

                            Text {
                                width: parent.width
                                text: root.searchText.trim()
                                color: theme.textMuted
                                elide: Text.ElideRight
                                horizontalAlignment: Text.AlignHCenter
                                font.family: "GoMono Nerd Font Mono"
                                font.pixelSize: 13
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.launchCurrent()
                        }
                    }
                }
            }
        }
    }
}
